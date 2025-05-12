# Node.js Webhook Handler for MS Teams

This project is a simple webhook handler that receives alerts and forwards them to Microsoft Teams.

## Features

- Receives webhook alerts
- Formats alerts for Microsoft Teams
- Health check endpoint
- Configurable through environment variables

## Prerequisites

- Node.js 18 or higher
- npm (Node Package Manager)
- Docker (optional
- Microsoft Teams channel with Incoming Webhook connector

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd node_example_msteams
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file based on `.env.example`:
   ```bash
   cp .env.example .env
   ```

4. Update the `.env` file with your MS Teams webhook URL:
   ```
   TEAMS_WEBHOOK_URL=your_teams_webhook_url
   ```

## Running the Server

### Using Node.js

1. Start the server:
   ```bash
   node server.js
   ```

2. The server will be running on `http://localhost:3000`.

### Using Docker

1. Build the Docker image:
   ```bash
   docker build -t node_example_msteams .
   ```

2. Run the Docker container with environment variables:
   ```bash
   docker run -p 3000:3000 --env-file .env node_example_msteams
   ```

3. The server will be running on `http://localhost:3000`.

## Testing the Webhook

You can test the webhook using the provided `test_webhook.sh` script:

```bash
./test_webhook.sh
```

Or manually send a test payload using curl:

```bash
curl -X POST http://localhost:3000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "event_action": "triggered",
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
  }'
```

## .env.example Template

```
TEAMS_WEBHOOK_URL=your_teams_webhook_url
```

Replace `your_teams_webhook_url` with your actual MS Teams webhook URL.

## API Endpoints

- `POST /webhook` - Receive webhook alerts
- `GET /health` - Health check endpoint