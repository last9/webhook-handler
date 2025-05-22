# MS Teams Webhook Handler

A Node.js application that handles webhook notifications and forwards them to Microsoft Teams channels.

## Features

- Dynamic team registration with authentication
- Secure admin and team-specific authentication
- MS Teams message formatting
- Comprehensive logging
- Health check endpoint
- Docker support

## Prerequisites

- Node.js 18 or higher
- Docker (for containerized deployment)
- Microsoft Teams webhook URL

## Environment Variables

Create a `.env` file in the project root with the following variables:

```env
# Admin credentials
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your_secure_password

# Server configuration
PORT=3000

# Logging configuration
LOG_LEVEL=info
```

## Running with Docker

1. Build the Docker image:
```bash
docker build -t webhook-handler .
```

2. Create a logs directory on your host:
```bash
mkdir -p ~/webhook-logs
```

3. Run the container:
```bash
docker run -d \
  -p 3000:3000 \
  -v ~/webhook-logs:/app/logs \
  -e ADMIN_USERNAME=your_admin_username \
  -e ADMIN_PASSWORD=your_admin_password \
  --name webhook-handler \
  webhook-handler
```

## API Endpoints

### Register a Team (Admin only)
```bash
curl -X POST http://localhost:3000/register \
  -H "Content-Type: application/json" \
  -H "X-Username: team1user" \
  -H "X-Password: team1pass" \
  -u admin:password123 \
  -d '{
    "teamId": "team1",
    "webhookUrl": "https://your-teams-webhook-url"
  }'
```

### Send Alert to Team
```bash
curl -X POST http://localhost:3000/team1 \
  -H "Content-Type: application/json" \
  -u team1user:team1pass \
  -d '{
    "event_action": "trigger",
    "payload": {
      "summary": "Test Alert",
      "severity": "critical",
      "source": "Test System"
    }
  }'
```

### List Registered Teams (Admin only)
```bash
curl -u admin:password123 http://localhost:3000/teams
```

### Health Check
```bash
curl http://localhost:3000/health
```

## Logs

Logs are written to three files in the mounted volume (`~/webhook-logs`):

- `access.log`: General access logs
- `error.log`: Error logs
- `payload.log`: Webhook payload logs

View logs in real-time:
```bash
tail -f ~/webhook-logs/*.log
```

## Security Notes

1. Always use strong passwords for admin and team credentials
2. Use HTTPS in production
3. Regularly rotate credentials
4. Monitor logs for suspicious activity

## Development

1. Install dependencies:
```bash
npm install
```

2. Start the server:
```bash
npm start
```

## License

MIT