variable "aws_region" {
  description = "AWS region for MediCart"
  type        = string
  default     = "ap-southeast-2"
}

variable "ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
  default     = "ami-0ba218121447b72f3"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "ssh_cidr" {
  description = "Your public IP address in CIDR notation"
  type        = string
}

variable "deployment_public_key" {
  description = "SSH public key used by GitHub Actions to connect to EC2"
  type        = string
}