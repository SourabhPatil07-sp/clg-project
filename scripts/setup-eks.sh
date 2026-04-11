#!/bin/bash
# EKS Cluster Setup Script
# Usage: bash scripts/setup-eks.sh

set -e

CLUSTER_NAME="calcify-Ai-cluster"
AWS_REGION="us-east-1"
NODE_GROUP_NAME="calcify-ai-nodes"

echo "🔧 Setting up AWS EKS cluster..."

# Check if cluster exists
if aws eks describe-cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} 2>/dev/null; then
    echo "✅ Cluster already exists: ${CLUSTER_NAME}"
else
    echo "📦 Creating EKS cluster..."
    aws eks create-cluster \
        --name ${CLUSTER_NAME} \
        --version 1.28 \
        --roleArn arn:aws:iam::089959488660:role/eks-service-role \
        --resourcesVpcConfig subnetIds=subnet-xxxxx,subnet-xxxxx \
        --region ${AWS_REGION}
    
    echo "⏳ Waiting for cluster to be active..."
    aws eks wait cluster-active --name ${CLUSTER_NAME} --region ${AWS_REGION}
fi

# Configure kubectl
echo "⚙️  Configuring kubectl..."
aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}

# Create namespace
echo "📝 Creating calcify-ai namespace..."
kubectl create namespace calcify-ai --dry-run=client -o yaml | kubectl apply -f -

echo "✅ EKS cluster configured successfully!"
echo "   Cluster: ${CLUSTER_NAME}"
echo "   Region: ${AWS_REGION}"
echo ""
echo "Next steps:"
echo "1. Add node groups to the cluster"
echo "2. Set up IAM roles for service accounts"
echo "3. Configure secrets management"
