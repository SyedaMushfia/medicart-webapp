output "instance_id" {
  description = "MediCart EC2 instance ID"
  value       = aws_instance.medicart.id
}

output "public_ip" {
  description = "MediCart EC2 public IP"
  value       = aws_instance.medicart.public_ip
}

output "public_url" {
  description = "MediCart application URL"
  value       = "http://${aws_instance.medicart.public_ip}"
}