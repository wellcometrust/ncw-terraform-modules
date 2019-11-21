# Instance details
output "ec2_instance_id" {
  value = aws_instance.ec2-eip.id
}

output "eip-public-ip" {
  value = aws_eip.eip.public_ip
}
