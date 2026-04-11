#!/bin/bash
# AWS ECR Setup Script
# Usage: bash scripts/setup-ecr.sh

set -e

AWS_ACCOUNT_ID="089959488660"
AWS_REGION="us-east-1"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "🔧 Setting up AWS ECR repositories..."

# Create backend repository
echo "Creating backend repository..."
aws ecr create-repository \
    --repository-name calcify-ai/backend \
    --region ${AWS_REGION} \
    --image-scan-on-push \
    --image-tag-mutability IMMUTABLE || echo "Repository already exists"

# Create frontend repository
echo "Creating frontend repository..."
aws ecr create-repository \
    --repository-name calcify-ai/frontend \
    --region ${AWS_REGION} \
    --image-scan-on-push \
    --image-tag-mutability IMMUTABLE || echo "Repository already exists"

echo "✅ ECR repositories created successfully!"
echo "   Backend:  ${ECR_REGISTRY}/calcify-ai/backend"
echo "   Frontend: ${ECR_REGISTRY}/calcify-ai/frontend"
