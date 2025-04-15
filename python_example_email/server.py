from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import json
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Email configuration
SMTP_SERVER = os.getenv('SMTP_SERVER')
SMTP_PORT = int(os.getenv('SMTP_PORT', 587))
SMTP_USERNAME = os.getenv('SMTP_USERNAME')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD')
SMTP_FROM = os.getenv('SMTP_FROM')
SMTP_FROM_NAME = os.getenv('SMTP_FROM_NAME')
RECIPIENT_EMAILS = os.getenv('RECIPIENT_EMAILS', '').split(',')

def format_email_content(payload):
    """Format the alert payload into email content."""
    alert = payload.get('payload', {})
    
    # Create HTML content
    html_content = f"""
    <html>
        <body>
            <h2>Alert Details</h2>
            <p><strong>Summary:</strong> {alert.get('summary', 'N/A')}</p>
            <p><strong>Severity:</strong> {alert.get('severity', 'N/A')}</p>
            <p><strong>Source:</strong> {alert.get('source', 'N/A')}</p>
            
            <h3>Description</h3>
            <p>{alert.get('description', 'No description provided')}</p>
            
            <h3>Additional Details</h3>
            {format_custom_details(alert.get('custom_details', {}))}
            
            <p><strong>Incident URL:</strong> {alert.get('incident_url', 'Not provided')}</p>
        </body>
    </html>
    """
    
    return html_content

def format_custom_details(details):
    """Format custom details into HTML."""
    if not details:
        return "<p>No additional details provided</p>"
    
    details_html = "<ul>"
    for key, value in details.items():
        details_html += f"<li><strong>{key}:</strong> {value}</li>"
    details_html += "</ul>"
    return details_html

def send_email(recipients, subject, html_content):
    """Send email to recipients."""
    try:
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = f"{SMTP_FROM_NAME} <{SMTP_FROM}>"
        msg['To'] = ', '.join(recipients)
        
        # Attach HTML content
        msg.attach(MIMEText(html_content, 'html'))
        
        # Connect to SMTP server and send email
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.send_message(msg)
            
        print(f"Email sent successfully to {recipients}")
        return True
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        return False

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({"status": "ok"})

@app.route('/webhook', methods=['POST'])
def webhook():
    """Webhook endpoint to receive alerts and send emails."""
    try:
        # Parse the incoming payload
        payload = request.json
        print(f"Received payload: {json.dumps(payload, indent=2)}")
        
        # Format email content
        email_content = format_email_content(payload)
        
        # Send email to all recipients
        success = send_email(
            recipients=RECIPIENT_EMAILS,
            subject="Alert Notification",
            html_content=email_content
        )
        
        if success:
            return jsonify({
                "status": "success",
                "message": "Alert processed and email sent successfully"
            })
        else:
            return jsonify({
                "status": "error",
                "message": "Failed to send email"
            }), 500
            
    except Exception as e:
        print(f"Error processing webhook: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 3000))
    app.run(host='0.0.0.0', port=port) 