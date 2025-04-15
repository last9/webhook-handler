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

