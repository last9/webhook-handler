# frozen_string_literal: true

require 'sinatra'
require 'json'
require 'net/http'
require 'uri'
require 'base64'
require 'dotenv'

# Load environment variables
Dotenv.load

# Configure Sinatra
set :port, ENV['PORT'] || 3000
set :bind, '0.0.0.0'

# Jira configuration from environment variables
JIRA_CONFIG = {
  domain: ENV['JIRA_DOMAIN'],
  email: ENV['JIRA_EMAIL'],
  api_token: ENV['JIRA_API_TOKEN'],
  project_key: ENV['JIRA_PROJECT_KEY'],
  assignee_id: ENV['JIRA_ASSIGNEE_ID']
}.freeze

# Health check endpoint
get '/health' do
  content_type :json
  { status: 'ok' }.to_json
end

# Webhook endpoint
post '/webhook' do
  begin
    # Parse the incoming payload
    payload = JSON.parse(request.body.read)
    puts "Received payload: #{payload.inspect}"

    # Handle the webhook
    response = WebhookJiraHandler.handle_webhook(payload, JIRA_CONFIG)
    
    # Return success response
    content_type :json
    { status: 'success', message: 'Alert processed successfully' }.to_json
  rescue StandardError => e
    puts "Error processing webhook: #{e.message}"
    puts e.backtrace
    status 500
    content_type :json
    { status: 'error', message: e.message }.to_json
  end
end

class WebhookJiraHandler
  def self.handle_webhook(payload, jira_config)
    # Convert PagerDuty-style webhook payload to Jira format
    jira_payload = convert_to_jira_payload(payload, jira_config)
    send_to_jira(jira_config, jira_payload)
  end

  private

  def self.convert_to_jira_payload(payload, jira_config)
    # Extract relevant information from PagerDuty-style payload
    summary = payload.dig('payload', 'summary')
    source = payload.dig('payload', 'source')
    severity = payload.dig('payload', 'severity')
    details = payload.dig('payload', 'custom_details')

    # Format description with structured information
    description = "Source: #{source}\nSeverity: #{severity}\n\nAdditional Details:\n#{details.map { |k, v| "#{k}: #{v}" }.join("\n")}"

    # Construct Jira issue payload
    {
      fields: {
        project: {
          key: jira_config[:project_key]
        },
        summary: summary,
        description: description,
        issuetype: {
          name: "Task"
        },
        assignee: jira_config[:assignee_id] ? { accountId: jira_config[:assignee_id] } : nil
      }.compact
    }
  end

  def self.send_to_jira(config, payload)
    domain = config[:domain].sub(%r{https?://}, '').sub(%r{/$}, '')
    uri = URI("https://#{domain}/rest/api/2/issue")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Basic #{Base64.strict_encode64("#{config[:email]}:#{config[:api_token]}")}"
    request.body = payload.to_json

    puts "\n=== Jira Request Debug ==="
    puts "URL: #{uri}"
    puts "Auth Header: #{request['Authorization']}"
    puts "Payload: #{payload.to_json}"
    puts "=========================\n"

    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
      puts "\n=== Jira Error Response ==="
      puts "Status: #{response.code}"
      puts "Body: #{response.body}"
      puts "=========================\n"
      raise "Jira API error: #{response.code} - #{response.body}"
    end

    puts "\n=== Jira Success Response ==="
    puts "Status: #{response.code}"
    puts "Body: #{response.body}"
    puts "=========================\n"
    response
  end

  def self.fetch_issue_types(config)
    domain = config[:domain].sub(%r{https?://}, '').sub(%r{/$}, '')
    uri = URI("https://#{domain}/rest/api/3/issue/createmeta?projectKeys=#{config[:project_key]}&expand=projects.issuetypes")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Basic #{Base64.strict_encode64("#{config[:email]}:#{config[:api_token]}")}"

    puts "\n=== Issue Types Request Debug ==="
    puts "URL: #{uri}"
    puts "Auth Header: #{request['Authorization']}"
    puts "=========================\n"

    response = http.request(request)
    
    puts "\n=== Issue Types Response ==="
    puts "Status: #{response.code}"
    puts "Body: #{response.body}"
    puts "=========================\n"
  end
end 