# Email Webhook Handler

A Sinatra-based webhook handler that converts PagerDuty-style alerts into email notifications.

## Features

- Converts webhook payloads into formatted email notifications
- Supports multiple recipients
- Configurable SMTP settings
- Health check endpoint
- Detailed logging and error handling

## Prerequisites

- Ruby 2.6 or higher
- SMTP server access (e.g., Gmail SMTP)
- Email account with SMTP access

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   gem install sinatra json dotenv mail
   ```

3. Create a `.env` file in the project root with the following variables:
   ```
   # Server configuration
   PORT=3000

   # Email configuration
   SMTP_ADDRESS=smtp.gmail.com
   SMTP_PORT=587
   SMTP_DOMAIN=your-domain.com
   SMTP_USERNAME=your-email@gmail.com
   SMTP_PASSWORD=your-app-password
   SMTP_AUTHENTICATION=plain
   SMTP_ENABLE_STARTTLS_AUTO=true

   # Recipient emails (comma-separated)
   RECIPIENT_EMAILS=recipient1@example.com,recipient2@example.com

   # Email sender
   EMAIL_FROM=alerts@your-domain.com
   EMAIL_FROM_NAME=Alert System
   ```

   For Gmail SMTP:
   1. Enable 2-factor authentication
   2. Generate an App Password
   3. Use the App Password in SMTP_PASSWORD

## Running the Server

```bash
ruby server.rb
```

The server will start on port 3000 (or the port specified in your .env file).

## Testing

### Health Check
```bash
curl http://localhost:3000/health
```
Expected response:
```json
{"status":"ok"}
```

### Sending Test Alerts
Run the test script:
```bash
./test_webhook.sh
```

This will send three different types of alerts:
1. Basic alert with minimal information
2. Critical alert with incident URL
3. Alert with multiple custom fields

## Email Format

The emails will include:
- Alert summary
- Severity level
- Source system
- Description
- Custom details (if any)
- Incident URL (if provided)

## Error Handling

The server will return appropriate error messages for:
- Invalid JSON payload
- SMTP connection errors
- Missing environment variables
- Email delivery failures

