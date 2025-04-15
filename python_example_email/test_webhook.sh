#!/bin/bash

# Test health check endpoint
echo "Testing health check endpoint..."
curl -s http://localhost:3001/health
echo -e "\n\n"

# Test 1: Basic Alert
echo "Test 1: Basic Alert"
curl -X POST http://localhost:3001/webhook \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
echo -e "\n\n"

# Test 2: Critical Alert with Incident URL
echo "Test 2: Critical Alert with Incident URL"
curl -X POST http://localhost:3001/webhook \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
echo -e "\n\n"

# Test 3: Alert with Multiple Custom Fields
echo "Test 3: Alert with Multiple Custom Fields"
curl -X POST http://localhost:3001/webhook \
  -H "Content-Type: application/json" \
  -d '{
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
echo -e "\n\n" 