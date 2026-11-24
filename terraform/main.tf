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
  description = "Allow HTTP and restricted SSH access"
  vpc_id      = "vpc-054f04198f63827f9"

  # Allow public HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH only from your IP
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
    apt-get update
    apt-get install -y docker.io
    systemctl enable --now docker
    usermod -aG docker ubuntu
  EOF

  tags = {
    Name = "medicart-ec2"
  }
}