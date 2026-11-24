
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Security group
resource "aws_security_group" "medicart" {
  name        = "medicart-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = "vpc-054f04198f63827f9"

  # Allow public HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH from the configured CIDR
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "medicart-sg"
  }
}

# EC2 instance
resource "aws_instance" "medicart" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = "subnet-08a883dce8407b893"
  vpc_security_group_ids      = [aws_security_group.medicart.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Install Docker
    apt-get update
    apt-get install -y docker.io

    # Start Docker automatically
    systemctl enable --now docker

    # Allow ubuntu user to run Docker
    usermod -aG docker ubuntu

    # Configure SSH directory
    mkdir -p /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh

    # Install GitHub Actions deployment public key
    echo '${var.deployment_public_key}' >> /home/ubuntu/.ssh/authorized_keys

    # Set SSH permissions
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    chmod 600 /home/ubuntu/.ssh/authorized_keys
  EOF

  tags = {
    Name = "medicart-ec2"
  }
}
