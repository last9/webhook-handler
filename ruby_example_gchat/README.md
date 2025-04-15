# Google Chat Webhook Handler

A webhook handler service that processes alerts and forwards them to Google Chat.

## Features

- Receives webhook alerts
- Formats alerts for Google Chat
- Health check endpoint
- Configurable through environment variables

## Prerequisites

- Ruby (version X.X.X)
- Bundler
- Google Chat space with webhook URL

## Installation

1. Clone the repository
2. Navigate to the `ruby_example_gchat` directory
3. Install dependencies:
   ```bash
   bundle install
   ```
4. Copy `.env.example` to `.env` and configure your environment variables:
   ```bash
   PORT=3000
   GOOGLE_CHAT_WEBHOOK_URL=your-google-chat-webhook-url
   ```

### Security Warning
⚠️ **IMPORTANT**: 
1. Never commit your `.env` file to version control. Add it to your `.gitignore` file:
   ```bash
   echo ".env" >> .gitignore
   ```
2. Keep your Google Chat webhook URL secure and rotate it if compromised
3. Use environment variables or a secrets management service in production
4. Restrict access to the `.env` file using appropriate file permissions

5. Start the server:
   ```bash
   ruby server.rb
   ```

## API Endpoints

- `POST /webhook` - Receive webhook alerts
- `GET /health` - Health check endpoint

## Testing

### Simple Test Alert
```bash
curl -X POST http://localhost:3000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "payload": {
      "summary": "Test Alert",
      "severity": "critical",
      "source": "Test System"
    }
  }'
```

### Complex Test Alert with Multiple Sections
```bash
curl -X POST http://localhost:3000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "payload": {
      "summary": "High CPU Usage Alert",
      "severity": "warning",
      "source": "Production Server",
      "details": {
        "cpu_usage": "95%",
        "memory_usage": "80%",
        "disk_usage": "60%"
      },
      "links": [
        {
          "text": "View Dashboard",
          "url": "https://dashboard.example.com"
        },
        {
          "text": "Runbook",
          "url": "https://runbook.example.com/high-cpu"
        }
      ]
    }
  }'
```

The webhook will format these alerts into Google Chat cards with appropriate styling based on severity and include all provided information in a structured format.

## Dependencies

- sinatra: Web framework
- httparty: HTTP client
- json: JSON parsing and generation

## Development

To run the server in development mode:
```bash
ruby server.rb
```

To test the health endpoint:
```bash
curl http://localhost:3000/health
```

## Deployment on AWS EC2

### Prerequisites
- AWS account with EC2 access
- AWS CLI installed and configured
- SSH access to EC2 instances
- Security group with port 3000 open (default port for this handler)

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

   # Install Ruby dependencies
   sudo apt-get install -y ruby ruby-dev build-essential
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
   sudo nano /etc/systemd/system/webhook-gchat.service
   ```

   ```ini
   [Unit]
   Description=Last9 Google Chat Webhook Handler
   After=network.target

   [Service]
   User=ubuntu
   WorkingDirectory=/opt/webhook-handlers/ruby_example_gchat
   Environment="PATH=/opt/webhook-handlers/ruby_example_gchat/.bundle/bin"
   ExecStart=/usr/bin/bundle exec ruby server.rb
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

5. **Start Service**
   ```bash
   # Enable and start service
   sudo systemctl daemon-reload
   sudo systemctl enable webhook-gchat
   sudo systemctl start webhook-gchat

   # Check status
   sudo systemctl status webhook-gchat
   ```



