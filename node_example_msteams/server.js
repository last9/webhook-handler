require('dotenv').config();
const express = require('express');
const axios = require('axios');
const bodyParser = require('body-parser');
const basicAuth = require('express-basic-auth');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Configure logging
const logDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir);
}

// Create write streams for different log types
const accessLogStream = fs.createWriteStream(path.join(logDir, 'access.log'), { flags: 'a' });
const errorLogStream = fs.createWriteStream(path.join(logDir, 'error.log'), { flags: 'a' });
const payloadLogStream = fs.createWriteStream(path.join(logDir, 'payload.log'), { flags: 'a' });

// Function to write to log file
function writeToLog(stream, message, data = null) {
    const timestamp = new Date().toISOString();
    const logEntry = {
        timestamp,
        message,
        data
    };
    stream.write(JSON.stringify(logEntry) + '\n');
}

// Configure middleware to parse JSON
app.use(bodyParser.json());

// Store webhook URLs and credentials in memory (in production, use a database)
const teamWebhooks = new Map();
const teamCredentials = new Map();

// Admin credentials
const ADMIN_USERNAME = 'admin';
const ADMIN_PASSWORD = 'password123';

// Function to log payload to stdout and file
function logPayloadToStdout(payload) {
    console.log('\n=== Incoming Webhook Payload ===');
    console.log(JSON.stringify(payload, null, 2));
    console.log('===============================\n');
    writeToLog(payloadLogStream, 'Incoming Webhook Payload', payload);
}

// Function to log success
function logSuccess(message, details = {}) {
    console.log('\n=== Success ===');
    console.log(`Message: ${message}`);
    if (Object.keys(details).length > 0) {
        console.log('Details:', JSON.stringify(details, null, 2));
    }
    console.log('==============\n');
    writeToLog(accessLogStream, message, details);
}

// Function to log error
function logError(message, error = null) {
    console.error('\n=== Error ===');
    console.error(`Message: ${message}`);
    if (error) {
        console.error('Error details:', error.message);
        if (error.stack) {
            console.error('Stack trace:', error.stack);
        }
    }
    console.error('============\n');
    writeToLog(errorLogStream, message, {
        error: error ? {
            message: error.message,
            stack: error.stack
        } : null
    });
}

// Function to format Webhook payload for MS Teams
function formatForMsTeams(payload) {
  // Check if this is a resolve payload
  if (payload.event_action === 'resolve') {
    // Extract resolve payload details
    const eventAction = payload.event_action;
    const dedupKey = payload.dedup_key || 'N/A';
    const routingKey = payload.routing_key || 'N/A';

    // Create MS Teams message card for resolve
    return {
      "@type": "MessageCard",
      "@context": "http://schema.org/extensions",
      "themeColor": "#00FF00", // Green for resolve
      "summary": "Alert RESOLVED",
      "title": "Alert RESOLVED",
      "sections": [
        {
          "activityTitle": "Alert Resolved",
          "facts": [
            {
              "name": "Event Action",
              "value": eventAction.toUpperCase()
            },
            {
              "name": "Dedup Key",
              "value": dedupKey
            },
            {
              "name": "Routing Key",
              "value": routingKey
            }
          ],
          "markdown": true
        }
      ]
    };
  }

  // Handle original payload format
  const alert = payload.payload;
  const eventAction = payload.event_action;
  const links = payload.links || [];
  const images = payload.images || [];

  // Define severity color
  let severityColor;
  switch (alert.severity) {
    case 'critical':
      severityColor = '#FF0000'; // Red
      break;
    case 'warning':
      severityColor = '#FFA500'; // Orange
      break;
    case 'info':
      severityColor = '#0000FF'; // Blue
      break;
    default:
      severityColor = '#808080'; // Grey
  }

  // Create facts array for details
  const facts = [
    {
      name: 'Severity',
      value: alert.severity
    },
    {
      name: 'Source',
      value: alert.source
    },
    {
      name: 'Component',
      value: alert.component || 'N/A'
    },
    {
      name: 'Group',
      value: alert.group || 'N/A'
    },
    {
      name: 'Class',
      value: alert.class || 'N/A'
    }
  ];

  // Add custom details as facts
  if (alert.custom_details) {
    Object.entries(alert.custom_details).forEach(([key, value]) => {
      facts.push({
        name: key,
        value: String(value)
      });
    });
  }

  // Format links section
  let potentialActions = [];
  if (links.length > 0 || payload.client_url) {
    const actions = [];
    
    if (payload.client_url) {
      actions.push({
        "@type": "OpenUri",
        "name": payload.client || "View in Monitoring Service",
        "targets": [
          {
            "os": "default",
            "uri": payload.client_url
          }
        ]
      });
    }
    
    links.forEach(link => {
      actions.push({
        "@type": "OpenUri",
        "name": link.text || "View Details",
        "targets": [
          {
            "os": "default",
            "uri": link.href
          }
        ]
      });
    });
    
    potentialActions = actions;
  }

  // Create MS Teams message card
  const teamsPayload = {
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    "themeColor": severityColor,
    "summary": alert.summary,
    "title": `Webhook ${eventAction.toUpperCase()}: ${alert.summary}`,
    "sections": [
      {
        "activityTitle": "Webhook Alert",
        "activitySubtitle": `Triggered at ${alert.timestamp}`,
        "facts": facts,
        "markdown": true
      }
    ],
    "potentialAction": potentialActions
  };

  // Add image section if available
  if (images.length > 0) {
    teamsPayload.sections.push({
      "images": images.map(img => ({
        "image": img.src,
        "title": img.alt || "Alert Image"
      }))
    });
  }

  return teamsPayload;
}

// Admin authentication middleware
const adminAuth = basicAuth({
  users: { [ADMIN_USERNAME]: ADMIN_PASSWORD },
  challenge: true,
  realm: 'Admin Area'
});

// Team authentication middleware
const teamAuth = (req, res, next) => {
  const teamId = req.params.teamId;
  const credentials = teamCredentials.get(teamId);
  
  if (!credentials) {
    logError(`Team not found: ${teamId}`);
    return res.status(404).json({ error: 'Team not found' });
  }

  const auth = basicAuth({
    users: { [credentials.username]: credentials.password },
    challenge: true,
    realm: `Team ${teamId} Area`
  });

  auth(req, res, next);
};

// Register a new team webhook (admin only)
app.post('/register', adminAuth, (req, res) => {
    writeToLog(accessLogStream, 'Team Registration Request', {
        headers: req.headers,
        body: req.body
    });
    
    const { teamId, webhookUrl } = req.body;
    const username = req.headers['x-username'];
    const password = req.headers['x-password'];
    
    if (!teamId || !webhookUrl || !username || !password) {
        const error = { 
            error: 'Missing required fields',
            details: {
                teamId: !teamId ? 'required' : 'provided',
                webhookUrl: !webhookUrl ? 'required' : 'provided',
                username: !username ? 'required in X-Username header' : 'provided',
                password: !password ? 'required in X-Password header' : 'provided'
            }
        };
        logError('Registration failed - missing fields', error);
        return res.status(400).json(error);
    }

    // Store webhook URL and credentials
    teamWebhooks.set(teamId, webhookUrl);
    teamCredentials.set(teamId, { username, password });
    
    // Create a dynamic route for this team
    app.post(`/:teamId`, teamAuth, async (req, res) => {
        try {
            const teamId = req.params.teamId;
            writeToLog(accessLogStream, `Processing Alert for Team ${teamId}`);
            
            const webhookUrl = teamWebhooks.get(teamId);
            if (!webhookUrl) {
                logError(`Team webhook not found: ${teamId}`);
                return res.status(404).json({ error: 'Team webhook not found' });
            }

            // Log the received payload
            logPayloadToStdout(req.body);
            
            // Format payload for MS Teams
            const teamsPayload = formatForMsTeams(req.body);
            writeToLog(payloadLogStream, 'Formatted Teams Payload', teamsPayload);
            
            // Send to MS Teams
            const response = await axios.post(webhookUrl, teamsPayload);
            logSuccess(`Alert sent to team ${teamId}`, {
                status: response.status,
                statusText: response.statusText
            });
            res.json({ success: true, message: 'Notification sent successfully' });
        } catch (error) {
            logError(`Failed to send notification to team ${req.params.teamId}`, error);
            res.status(500).json({ error: 'Failed to send notification' });
        }
    });

    logSuccess(`Team ${teamId} registered successfully`, {
        webhookUrl,
        username
    });
    res.json({ success: true, message: `Team ${teamId} registered successfully` });
});

// List all registered teams (admin only)
app.get('/teams', adminAuth, (req, res) => {
    writeToLog(accessLogStream, 'Listing Registered Teams');
    const teams = Array.from(teamWebhooks.keys());
    console.log('Teams:', teams);
    res.json({ teams });
});

// Health check endpoint
app.get('/health', (req, res) => {
    writeToLog(accessLogStream, 'Health Check');
    console.log('\n=== Health Check ===');
    console.log('Status: OK');
    res.status(200).json({ status: 'up' });
});

// Start the server
app.listen(PORT, () => {
    writeToLog(accessLogStream, `Webhook Server Started on port ${PORT}`);
    console.log(`\n=== Webhook Server Started ===`);
    console.log(`Listening on port ${PORT}`);
    console.log('=============================\n');
});
