# Python Email Webhook Handler

A Python-based webhook handler that receives alerts and sends them via email. This service is designed to work with Last9's alerting system and can be used as a template for building custom webhook handlers.

## Features

- Receives webhook payloads in Last9's alert format
- Sends formatted email alerts using SMTP
- Supports multiple alert types and severity levels
- Configurable email templates
- Health check endpoint for monitoring
- Environment-based configuration

## Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- Virtual environment (recommended)
- Gmail account with App Password (for SMTP)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd python_example_email
```

2. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Configuration

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Update the `.env` file with your configuration:
```env
# Server Configuration
PORT=3001
HOST=0.0.0.0

# SMTP Configuration
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@example.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=your-email@example.com
SMTP_TO=recipient@example.com

# Email Template Configuration
EMAIL_SUBJECT_PREFIX=[Last9 Alert]
```

### Security Warning
⚠️ **IMPORTANT**: Never commit your `.env` file to version control. Add it to your `.gitignore` file:
```bash
echo ".env" >> .gitignore
```

### Gmail App Password Setup

To use Gmail's SMTP server, you'll need to generate an App Password:

1. Enable 2-Step Verification in your Google Account
2. Go to your Google Account settings
3. Navigate to Security > App passwords
4. Generate a new app password for "Mail"
5. Use this password in your `.env` file

## Running the Server

1. Activate the virtual environment:
```bash
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Start the server:
```bash
python server.py
```

The server will start on the configured port (default: 3001).

## Testing

A test script is provided to test different alert scenarios:

```bash
./test_webhook.sh
```

This script tests:
1. Basic alert
2. Critical alert with incident URL
3. Alert with multiple custom fields

## API Endpoints

### Health Check
- **GET** `/health`
- Returns server status
- Response: `{"status": "ok"}`

### Webhook
- **POST** `/webhook`
- Accepts alert payloads
- Returns success/error status
- Response: `{"status": "success"}` or `{"status": "error", "message": "error details"}`

## Alert Payload Format

The webhook expects payloads in the following format:

```json
{
  "alert": {
    "name": "Alert Name",
    "severity": "critical|warning|info",
    "status": "firing|resolved",
    "description": "Alert description",
    "incident_url": "https://last9.io/incidents/123",
    "custom_fields": {
      "field1": "value1",
      "field2": "value2"
    }
  }
}
```

## Email Format

Alerts are sent as HTML emails with the following sections:
- Subject: `[Last9 Alert] <severity>: <alert_name>`
- Body:
  - Alert Name
  - Severity (color-coded)
  - Description
  - Incident URL (if available)
  - Custom Fields (if available)
  - Timestamp

## Troubleshooting

Common issues and solutions:

1. **Port already in use**
   - Check if another process is using the configured port
   - Change the port in `.env` file

2. **SMTP Authentication Failed**
   - Verify Gmail App Password is correct
   - Check if 2-Step Verification is enabled
   - Ensure SMTP settings are correct

3. **Email not received**
   - Check spam folder
   - Verify recipient email address
   - Check server logs for errors


## Deployment on AWS EC2

### Prerequisites
- AWS account with EC2 access
- AWS CLI installed and configured
- SSH access to EC2 instances
- Security group with port 3001 open (default port for this handler)

### Setup Steps

1. **Launch EC2 Instance**
   ```bash
   # Create a new EC2 instance (Ubuntu 20.04 recommended)
   aws ec2 run-instances \
     --image-id ami-0c55b159cbfafe1f0 \
     --count 1 \
     --instance-type t2.micro \
     --key-name your-key-pair \
     --security-group-ids sg-xxxxxxxx
   ```

2. **Install Dependencies**
   ```bash
   # Update system
   sudo apt-get update
   sudo apt-get upgrade -y

   # Install Python dependencies
   sudo apt-get install -y python3 python3-pip python3-venv
   ```

3. **Configure Environment**
   ```bash
   # Create application directory
   mkdir -p /opt/webhook-handlers
   cd /opt/webhook-handlers

   # Clone repository
   git clone <repository-url> .

   # Set up environment variables
   sudo nano .env
   ```

4. **Set Up Systemd Service**
   Create a service file:

   ```bash
   sudo nano /etc/systemd/system/webhook-email.service
   ```

   ```ini
   [Unit]
   Description=Last9 Email Webhook Handler
   After=network.target

   [Service]
   User=ubuntu
   WorkingDirectory=/opt/webhook-handlers/python_example_email
   Environment="PATH=/opt/webhook-handlers/python_example_email/venv/bin"
   ExecStart=/opt/webhook-handlers/python_example_email/venv/bin/python server.py
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

5. **Start Service**
   ```bash
   # Enable and start service
   sudo systemctl daemon-reload
   sudo systemctl enable webhook-email
   sudo systemctl start webhook-email

   # Check status
   sudo systemctl status webhook-email
   ```



