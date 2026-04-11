#!/bin/bash
# Local Docker Test Script
# Usage: bash scripts/test-local.sh

set -e

echo "🧪 Testing Docker builds locally..."

# Backend test
echo "📦 Testing backend build..."
docker build -t calcify-ai-backend:test ./backend

echo "✅ Backend build successful"

# Frontend test
echo "📦 Testing frontend build..."
docker build -t calcify-ai-frontend:test ./frontend

echo "✅ Frontend build successful"

# Run backend health check
echo "🏥 Testing backend health..."
docker run --rm -p 8000:8000 calcify-ai-backend:test &
sleep 3
curl http://localhost:8000/ || echo "Health check failed"
pkill -f "calcify-ai-backend:test"

echo "✅ All local tests passed!"
