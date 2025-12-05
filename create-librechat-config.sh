#!/bin/sh
# Script to create librechat.yaml from environment variables
# This script runs at container startup

cat > /app/librechat.yaml << 'YAML_EOF'
# LibreChat Configuration for Sportsbook RAG
# Auto-generated at startup
version: 1.2.1
cache: true
endpoints:
  custom:
    - name: 'Sportsbook RAG'
      apiKey: 'sk-optional'
      baseURL: 'https://sportsbook-rag.up.railway.app/v1'
      models:
        default:
          - 'sportsbook-rag'
        fetch: false
      titleConvo: true
      titleModel: 'sportsbook-rag'
      modelDisplayLabel: 'Sportsbook RAG'
      summarize: false
      summaryModel: 'sportsbook-rag'
      forcePrompt: false
YAML_EOF

echo "✅ Created librechat.yaml at /app/librechat.yaml"
ls -la /app/librechat.yaml || echo "❌ File not found after creation"

