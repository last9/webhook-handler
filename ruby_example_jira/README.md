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

   To get your Jira API token:
   1. Log in to https://id.atlassian.com/manage/api-tokens
   2. Click "Create API token"
   3. Give it a name and copy the token

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

## Logging

The server logs:
- Received payloads
- Jira API requests and responses
- Error messages and stack traces

## Security Considerations

1. Keep your `.env` file secure and never commit it to version control
2. Use HTTPS for production deployments
3. Consider implementing request authentication
4. Regularly rotate your Jira API token

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License 