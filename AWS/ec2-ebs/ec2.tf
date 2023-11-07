resource "aws_instance" "ec2-with-ebs" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_pair
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip
  disable_api_termination     = var.disable_api_termination
  source_dest_check           = var.source_dest_check
  iam_instance_profile        = var.iam_instance_profile
  ebs_optimized               = true
  private_ip                  = var.private_ip

  vpc_security_group_ids = [
    var.vpc_security_group_ids,
  ]

  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
  }

  ebs_block_device {
    device_name = var.ebs_device_name
    volume_type = var.ebs_volume_type
    volume_size = var.ebs_volume_size
  }

  tags {
    Name          = var.Name
    Owner         = var.Owner
    Division        = var.Division
    Department    = var.Department
    Cost          = var.Cost
    Terraform     = var.Terraform
    Environment   = var.Environment
    Internal      = var.Internal
    Monitoring    = var.Monitoring
    Use           = var.Use
    BackUps       = var.BackUps
    Ansible       = var.Ansible
    PatchGroup    = var.PatchGroup
  }
}
