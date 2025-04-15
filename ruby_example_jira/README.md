# Jira Webhook Handler

A Sinatra-based webhook handler that converts PagerDuty-style alerts into Jira issues.

## Features

- Converts webhook payloads into Jira issues
- Supports custom fields and details
- Configurable Jira project and assignee
- Health check endpoint
- Detailed logging and error handling

## Prerequisites

- Ruby 2.6 or higher
- Jira account with API access
- Jira API token

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   gem install sinatra json net-http dotenv
   ```

3. Create a `.env` file in the project root with the following variables:
   ```
   JIRA_DOMAIN=your-domain.atlassian.net
   JIRA_EMAIL=your-email@example.com
   JIRA_API_TOKEN=your-api-token
   JIRA_PROJECT_KEY=YOUR_PROJECT_KEY
   JIRA_ASSIGNEE_ID=optional-assignee-id
   PORT=3000
   ```

### Security Warning
⚠️ **IMPORTANT**: 
1. Never commit your `.env` file to version control. Add it to your `.gitignore` file:
   ```bash
   echo ".env" >> .gitignore
   ```
2. Store your Jira API token securely and rotate it regularly
3. Use environment variables or a secrets management service in production
4. Restrict access to the `.env` file using appropriate file permissions

   To get your Jira API token:
   1. Log in to https://id.atlassian.com/manage/api-tokens
   2. Click "Create API token"
   3. Give it a name and copy the token
   4. Store the token securely - you won't be able to see it again

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

### Creating a Jira Issue
```bash
curl -X POST http://localhost:3000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "payload": {
      "summary": "Test Alert",
      "severity": "critical",
      "source": "test-service",
      "description": "This is a test alert",
      "incident_url": "https://example.com/incidents/123",
      "custom_details": {
        "environment": "production",
        "service": "test-service",
        "region": "us-east-1"
      }
    }
  }'
```

Expected response:
```json
{"status":"success","message":"Alert processed successfully"}
```

### Example Payloads

1. Basic Alert:
```json
{
  "payload": {
    "summary": "High CPU Usage",
    "severity": "warning",
    "source": "monitoring-system",
    "description": "CPU usage above 80% for 5 minutes",
    "custom_details": {
      "host": "server-1",
      "cpu_usage": "85%"
    }
  }
}
```

2. Critical Alert with Incident URL:
```json
{
  "payload": {
    "summary": "Database Connection Failed",
    "severity": "critical",
    "source": "database-monitor",
    "description": "Unable to connect to primary database",
    "incident_url": "https://status.example.com/incidents/456",
    "custom_details": {
      "database": "primary-db",
      "error": "Connection timeout",
      "retry_count": "3"
    }
  }
}
```

3. Alert with Multiple Custom Fields:
```json
{
  "payload": {
    "summary": "Service Degradation",
    "severity": "major",
    "source": "application-monitor",
    "description": "Response time increased by 200%",
    "custom_details": {
      "service": "api-gateway",
      "response_time": "2.5s",
      "error_rate": "5%",
      "affected_users": "1000",
      "region": "eu-west-1"
    }
  }
}
```

## Error Handling

The server will return appropriate error messages for:
- Invalid JSON payload
- Missing required fields
- Jira API errors
- Authentication failures



## Deployment on AWS EC2

### Prerequisites
- AWS account with EC2 access
- AWS CLI installed and configured
- SSH access to EC2 instances
- Security group with port 3002 open (default port for this handler)

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
   sudo nano /etc/systemd/system/webhook-jira.service
   ```

   ```ini
   [Unit]
   Description=Last9 Jira Webhook Handler
   After=network.target

   [Service]
   User=ubuntu
   WorkingDirectory=/opt/webhook-handlers/ruby_example_jira
   Environment="PATH=/opt/webhook-handlers/ruby_example_jira/.bundle/bin"
   ExecStart=/usr/bin/bundle exec ruby server.rb
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

5. **Start Service**
   ```bash
   # Enable and start service
   sudo systemctl daemon-reload
   sudo systemctl enable webhook-jira
   sudo systemctl start webhook-jira

   # Check status
   sudo systemctl status webhook-jira
   ```

