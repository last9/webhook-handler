# Microsoft Teams Webhook Handler

A webhook handler service that processes alerts and forwards them to Microsoft Teams.

## Features

- Receives webhook alerts
- Formats alerts for Microsoft Teams
- Health check endpoint
- Configurable through environment variables

## Prerequisites

- Node.js (version X.X.X)
- npm (version X.X.X)
- Microsoft Teams channel with Incoming Webhook connector

## Installation

1. Clone the repository
2. Navigate to the `node_example_msteams` directory
3. Install dependencies:
   ```bash
   npm install
   ```
4. Copy `.env.example` to `.env` and configure your environment variables:
```bash
PORT=3000
TEAMS_WEBHOOK_URL=your-teams-webhook-url
```
5. Start the server:
   ```bash
   npm start
   ```

## API Endpoints

- `POST /webhook` - Receive webhook alerts
- `GET /health` - Health check endpoint

## Testing
You can test the webhook by sending a sample payload:
```bash
curl -X POST \
  http://localhost:3000/webhook \
  -H 'Content-Type: application/json' \
  -d '{
  "payload": {
    "summary": "Test Alert",
    "timestamp": "2023-04-15T08:42:58.315+0000",
    "severity": "critical",
    "source": "test-server.example.com",
    "component": "test",
    "group": "test-group",
    "class": "test-class",
    "custom_details": {
      "free space": "1%"
    }
  },
  "event_action": "trigger"
}'
```
The server should log the payload to stdout and show the formatted MS Teams payload.