#!/bin/bash
# Jenkins Installation Script for Ubuntu 22.04
# Usage: sudo bash install-jenkins.sh

set -e

echo "🔧 Installing Jenkins and Dependencies..."

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Java (Jenkins requirement)
echo "📦 Installing Java 17..."
sudo apt-get install -y openjdk-17-jdk-headless

# Add Jenkins repository
echo "📦 Adding Jenkins repository..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | \
    sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | \
    sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt-get update
echo "📦 Installing Jenkins..."
sudo apt-get install -y jenkins

# Install Docker
echo "📦 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker jenkins

# Install AWS CLI
echo "📦 Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm awscliv2.zip
rm -rf aws

# Install kubectl
echo "📦 Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Trivy (Security scanning)
echo "📦 Installing Trivy..."
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list > /dev/null
sudo apt-get update
sudo apt-get install -y trivy

# Start Jenkins
echo "🚀 Starting Jenkins..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Wait for Jenkins to start
echo "⏳ Waiting for Jenkins to start (30 seconds)..."
sleep 30

# Get initial password
INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

echo ""
echo "✅ Jenkins installation complete!"
echo ""
echo "📝 Initial Setup Instructions:"
echo "======================================"
echo "1. Open your browser: http://YOUR_EC2_IP:8080"
echo ""
echo "2. Use this password: $INITIAL_PASSWORD"
echo ""
echo "3. Proceed with initial setup:"
echo "   - Click 'Install suggested plugins'"
echo "   - Create admin user"
echo "   - Save and Finish"
echo ""
echo "4. Configure Jenkins:"
echo "   - Manage Jenkins → Manage Credentials"
echo "   - Add AWS credentials"
echo "   - Add GitHub credentials (if using)"
echo ""
echo "5. Install Additional Plugins:"
echo "   - Manage Jenkins → Plugin Manager"
echo "   - Search & install:"
echo "      • Docker Pipeline"
echo "      • Amazon ECR"
echo "      • Kubernetes"
echo "      • GitHub Integration"
echo ""
echo "Configuration file locations:"
echo "- Jenkins home: /var/lib/jenkins"
echo "- Jenkins config: /etc/default/jenkins"
echo "- Jenkins logs: /var/log/jenkins/jenkins.log"
echo ""
echo "Useful commands:"
echo "- sudo systemctl restart jenkins"
echo "- sudo systemctl status jenkins"
echo "- sudo tail -100f /var/log/jenkins/jenkins.log"
echo ""
