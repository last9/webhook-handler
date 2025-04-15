require 'sinatra'
require 'json'
require 'httparty'
require 'dotenv'

# Load environment variables
Dotenv.load
puts "\n=== Environment Variables Debug ==="
puts "Current directory: #{Dir.pwd}"
puts "GOOGLE_CHAT_WEBHOOK_URL present? #{ENV.key?('GOOGLE_CHAT_WEBHOOK_URL')}"
puts "GOOGLE_CHAT_WEBHOOK_URL value: #{ENV['GOOGLE_CHAT_WEBHOOK_URL']}"
puts "==================================\n"

# Configure Sinatra
set :port, ENV['PORT'] || 3000
set :bind, '0.0.0.0'

# Function to log payload to stdout
def log_payload_to_stdout(payload)
  puts 'Webhook Alert Received:'
  puts JSON.pretty_generate(payload)
end

# Function to format Webhook payload for Google Chat
def format_for_google_chat(payload)
  begin
    # Extract relevant information from the Webhook payload
    alert = payload['payload'] || {}
    event_action = payload['event_action'] || 'unknown'
    links = payload['links'] || []
    images = payload['images'] || []

    # Define severity color
    severity_color = case alert['severity']
      when 'critical' then '#FF0000' # Red
      when 'warning' then '#FFA500'  # Orange
      when 'info' then '#0000FF'     # Blue
      else '#808080'                 # Grey
    end

    # Create facts array for details
    facts = []
    
    # Add standard fields
    [
      ['Severity', 'severity'],
      ['Source', 'source'],
      ['Component', 'component'],
      ['Group', 'group'],
      ['Class', 'class']
    ].each do |label, key|
      facts << {
        keyValue: {
          topLabel: label,
          content: alert[key] || 'N/A'
        }
      }
    end

    # Add custom details as facts
    if alert['custom_details'].is_a?(Hash)
      alert['custom_details'].each do |key, value|
        facts << {
          keyValue: {
            topLabel: key.to_s,
            content: value.to_s
          }
        }
      end
    end

    # Create Google Chat message
    chat_payload = {
      cards: [
        {
          header: {
            title: "Webhook #{event_action.to_s.upcase}",
            subtitle: alert['summary'] || 'No summary provided',
            imageUrl: "https://www.gstatic.com/images/icons/material/system/1x/error_black_48dp.png",
            imageStyle: "AVATAR"
          },
          sections: [
            {
              widgets: facts
            }
          ]
        }
      ]
    }

    # Add image section if available
    if images.any? && images.first['src']
      chat_payload[:cards][0][:sections] << {
        widgets: [
          {
            image: {
              imageUrl: images.first['src']
            }
          }
        ]
      }
    end

    # Add buttons for links if available
    buttons = []
    
    # Add client URL button if available
    if payload['client_url']
      buttons << {
        textButton: {
          text: payload['client'] || "View in Monitoring Service",
          onClick: {
            openLink: {
              url: payload['client_url']
            }
          }
        }
      }
    end
    
    # Add other link buttons
    links.each do |link|
      next unless link['href'] && link['text']
      buttons << {
        textButton: {
          text: link['text'],
          onClick: {
            openLink: {
              url: link['href']
            }
          }
        }
      }
    end
    
    # Add buttons section if any buttons were created
    if buttons.any?
      chat_payload[:cards][0][:sections] << {
        widgets: [
          {
            buttons: buttons
          }
        ]
      }
    end

    chat_payload
  rescue => e
    puts "Error formatting payload: #{e.message}"
    puts e.backtrace
    raise e
  end
end

# Endpoint to receive Webhook
post '/webhook' do
  begin
    # Parse the request body
    payload = JSON.parse(request.body.read)
    
    # Log the received payload to stdout
    log_payload_to_stdout(payload)
    
    # Create card format message
    chat_payload = {
      cards: [
        {
          header: {
            title: "Alert: #{payload['payload']['summary']}",
            subtitle: "Severity: #{payload['payload']['severity']}"
          },
          sections: [
            {
              widgets: [
                {
                  textParagraph: {
                    text: "Source: #{payload['payload']['source']}"
                  }
                }
              ]
            }
          ]
        }
      ]
    }
    
    # Log the formatted Google Chat payload (for debugging)
    puts 'Formatted Google Chat Payload:'
    puts JSON.pretty_generate(chat_payload)
    
    # Send the payload to Google Chat
    google_chat_webhook_url = ENV['GOOGLE_CHAT_WEBHOOK_URL']
    puts "\n=== Webhook URL Debug Information ==="
    puts "Is webhook URL set? #{!google_chat_webhook_url.nil?}"
    puts "Webhook URL length: #{google_chat_webhook_url&.length || 0}"
    puts "Webhook URL value: #{google_chat_webhook_url}"
    puts "====================================\n"
    
    if google_chat_webhook_url
      puts "Sending to Google Chat..."
      response = HTTParty.post(
        google_chat_webhook_url,
        body: chat_payload.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      puts "Google Chat response: #{response.code} - #{response.body}"
    else
      puts "ERROR: Google Chat webhook URL not configured"
    end
    
    # Return success response
    status 200
    { status: 'success', message: 'Alert processed successfully' }.to_json
  rescue => e
    puts "Error processing webhook: #{e.message}"
    puts e.backtrace
    status 500
    { status: 'error', message: e.message }.to_json
  end
end

# Health check endpoint
get '/health' do
  status 200
  { status: 'up' }.to_json
end 