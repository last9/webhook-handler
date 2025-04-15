const express = require('express');
const axios = require('axios');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 3000;

// Configure middleware to parse JSON
app.use(bodyParser.json());

// Function to log payload to stdout
function logPayloadToStdout(payload) {
  console.log('Webhook Alert Received:');
  console.log(JSON.stringify(payload, null, 2));
}

// Function to format Webhook payload for MS Teams
function formatForMsTeams(payload) {
  // Extract relevant information from the Webhook payload
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

// Endpoint to receive Webhook
app.post('/webhook', async (req, res) => {
  try {
    // Log the received payload to stdout
    logPayloadToStdout(req.body);
    
    // Format payload for MS Teams
    const teamsPayload = formatForMsTeams(req.body);
    
    // Log the formatted MS Teams payload (for debugging)
    console.log('Formatted Teams Payload:');
    console.log(JSON.stringify(teamsPayload, null, 2));
    
    // Here you would send the payload to MS Teams
    // Uncomment and configure the below section to actually send to Teams
    /*
    const TEAMS_WEBHOOK_URL = process.env.TEAMS_WEBHOOK_URL;
    if (!TEAMS_WEBHOOK_URL) {
      console.error('MS Teams webhook URL not configured');
    } else {
      try {
        await axios.post(TEAMS_WEBHOOK_URL, teamsPayload);
        console.log('Successfully sent alert to MS Teams');
      } catch (error) {
        console.error('Failed to send to MS Teams:', error.message);
      }
    }
    */
    
    // Return success response
    res.status(200).json({ status: 'success', message: 'Alert processed successfully' });
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'up' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Webhook server listening on port ${PORT}`);
});
