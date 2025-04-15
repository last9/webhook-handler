# frozen_string_literal: true

require 'sinatra'
require 'json'
require 'dotenv'
require 'mail'

# Load environment variables
Dotenv.load

# Configure Sinatra
set :port, ENV['PORT'] || 3000
set :bind, '0.0.0.0'

# Configure Mail
Mail.defaults do
  delivery_method :smtp, {
    address: ENV['SMTP_ADDRESS'],
    port: ENV['SMTP_PORT'],
    domain: ENV['SMTP_DOMAIN'],
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    authentication: ENV['SMTP_AUTHENTICATION'],
    enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] == 'true'
  }
end

# Health check endpoint
get '/health' do
  content_type :json
  { status: 'ok' }.to_json
end

# Webhook endpoint
post '/webhook' do
  begin
    # Parse the incoming payload
    payload = JSON.parse(request.body.read)
    puts "Received payload: #{payload.inspect}"

    # Format email content
    email_content = format_email_content(payload)

    # Send email to all recipients
    recipients = ENV['RECIPIENT_EMAILS'].split(',')
    send_alert_email(recipients, email_content)

    # Return success response
    content_type :json
    { status: 'success', message: 'Alert processed and email sent successfully' }.to_json
  rescue StandardError => e
    puts "Error processing webhook: #{e.message}"
    puts e.backtrace
    status 500
    content_type :json
    { status: 'error', message: e.message }.to_json
  end
end

def format_email_content(payload)
  alert = payload['payload']
  <<~EMAIL
    Alert Details:
    =============
    
    Summary: #{alert['summary']}
    Severity: #{alert['severity']}
    Source: #{alert['source']}
    
    Description:
    #{alert['description']}
    
    Additional Details:
    #{format_custom_details(alert['custom_details'])}
    
    Incident URL: #{alert['incident_url'] || 'Not provided'}
  EMAIL
end

def format_custom_details(details)
  return 'No additional details provided' unless details

  details.map { |key, value| "#{key}: #{value}" }.join("\n")
end

def send_alert_email(recipients, content)
  recipients.each do |recipient|
    Mail.deliver do
      from "#{ENV['EMAIL_FROM_NAME']} <#{ENV['EMAIL_FROM']}>"
      to recipient.strip
      subject 'Alert Notification'
      body content
    end
    puts "Email sent to #{recipient}"
  end
end 