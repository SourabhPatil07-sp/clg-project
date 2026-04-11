terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.67.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# IAM ROLE FOR EC2
resource "aws_iam_role" "ec2_role" {
  name = "ec2-basic-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_attach_admin" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-basic-profile"
  role = aws_iam_role.ec2_role.name
}

# STEP1: CREATE SG
resource "aws_security_group" "my-sg" {
  name        = "JENKINS-SERVER-SG"
  description = "Jenkins Server Ports"

  # Port 22 is required for SSH Access
  ingress {
    description = "SSH Port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS Port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "etc-cluster Port"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NPM Port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kube API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube Port"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus Port"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 9100 is required for Prometheus metrics server
  ingress {
    description = "Prometheus Metrics Port"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 10250-10260 is required for K8s
  ingress {
    description = "K8s Ports"
    from_port   = 10250
    to_port     = 10260
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 30000-32767 is required for NodePort
  ingress {
    description = "K8s NodePort"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# STEP2: CREATE EC2 USING PEM & SG
resource "aws_instance" "my-ec2" {
  ami                    = "ami-0ec10929233384c7f"  # Ubuntu 24.04 LTS (us-east-1)
  instance_type          = "c7i-flex.large"          # 2 vCPU, 4 GiB RAM
  key_name               = "new-key"
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "Jenkins-Server"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      private_key = file("./new-key.pem")
      user        = "ubuntu"
      host        = self.public_ip
    }

    inline = [

      # REGION FIX
      "echo 'export AWS_REGION=us-east-1' >> ~/.bashrc",
      "export AWS_REGION=us-east-1",

      # UPDATE SYSTEM
      "sudo apt update -y",

      # INSTALL AWS CLI
      "sudo apt install unzip -y",
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
      "unzip awscliv2.zip",
      "sudo ./aws/install",

      # INSTALL DOCKER
      "sudo apt-get install -y ca-certificates curl gnupg",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",
      "sudo chmod 777 /var/run/docker.sock",

      # SONARQUBE
      "docker run -d --name sonar -p 9000:9000 sonarqube:lts-community",

      # TRIVY
      "sudo apt-get install -y wget apt-transport-https gnupg",
      "wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg",
      "echo 'deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main' | sudo tee /etc/apt/sources.list.d/trivy.list",
      "sudo apt-get update -y",
      "sudo apt-get install trivy -y",

      # KUBECTL
      "curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.4/2024-09-11/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/",

      # HELM
      "wget https://get.helm.sh/helm-v3.16.1-linux-amd64.tar.gz",
      "tar -zxvf helm-v3.16.1-linux-amd64.tar.gz",
      "sudo mv linux-amd64/helm /usr/local/bin/helm",

      # ARGOCD
      "VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)",
      "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64",
      "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd",

      # JAVA
      "sudo apt install openjdk-17-jdk openjdk-17-jre -y",

    
      # JENKINS
        "sudo rm -f /usr/share/keyrings/jenkins-keyring.asc /usr/share/keyrings/jenkins-keyring.gpg /etc/apt/sources.list.d/jenkins.list",
        "sudo gpg --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68",
        "sudo gpg --export 7198F4B714ABFC68 | sudo tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null",
        "echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
        "sudo apt-get update -y",
        "sudo apt-get install -y jenkins",
        "sudo systemctl enable jenkins",
        "sudo systemctl start jenkins",
        "sleep 20",
      

      # OUTPUT INFO
      "ip=$(curl -s ifconfig.me)",
      "pass=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)",
      "echo 'Jenkins: http://'$ip':8080'",
      "echo 'Password: '$pass",
      "echo 'SonarQube: http://'$ip':9000 | admin/admin'"
    ]
  }
}

# OUTPUTS
output "SSH" {
  value = "ubuntu@${aws_instance.my-ec2.public_ip}"
}

output "PUBLIC-IP" {
  value = aws_instance.my-ec2.public_ip
}

output "PRIVATE-IP" {
  value = aws_instance.my-ec2.private_ip
}
