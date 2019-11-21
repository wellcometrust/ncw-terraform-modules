# Instance details
output "ec2_instance_id" {
  value = aws_instance.ec2-with-ebs.id
}

output "ec2_instance_az" {
  value = aws_instance.ec2-with-ebs.availability_zone
}
