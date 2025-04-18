# Webhook Handlers

A collection of webhook handlers for processing alerts and notifications from Last9's alerting system. Each handler is designed to convert alerts into different formats and send them to various destinations.

## Available Handlers

### 1. Python Email Handler
Location: `python_example_email/`
- Converts alerts into formatted HTML emails
- Uses SMTP for email delivery
- Supports multiple alert types and severity levels
- [View Documentation](python_example_email/README.md)

### 2. Ruby Google Chat Handler
Location: `ruby_example_gchat/`
- Sends alerts to Google Chat
- Formats messages with cards and sections
- Supports interactive elements and links
- [View Documentation](ruby_example_gchat/README.md)

### 3. Ruby Jira Handler
Location: `ruby_example_jira/`
- Creates Jira issues from alerts
- Maps alert fields to Jira fields
- Supports custom field mapping
- [View Documentation](ruby_example_jira/README.md)

## Common Features

All webhook handlers include:
- Health check endpoints
- Environment-based configuration
- Error handling and logging
- Test scripts for validation
- Docker support for containerization

## Getting Started

1. Choose the handler that matches your needs
2. Navigate to the handler's directory
3. Follow the specific setup instructions in its README
4. Configure the environment variables
5. Start the server
6. Test the integration

## Development

### Prerequisites
- Docker (for containerized deployment)
- Python 3.8+ (for Python handlers)
- Ruby 2.7+ (for Ruby handlers)
- Git

### Directory Structure
```
.
├── python_example_email/     # Email webhook handler
├── ruby_example_gchat/       # Google Chat webhook handler
├── ruby_example_jira/        # Jira webhook handler
└── README.md                 # This file
```

### Testing
Each handler includes test scripts to verify functionality:
- `test_webhook.sh` - Tests basic alert processing
- `test_critical.sh` - Tests critical alert handling
- `test_custom.sh` - Tests custom field processing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please open an issue in the repository.
