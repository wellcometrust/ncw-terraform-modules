resource "aws_eip" "eip" {
  instance = aws_instance.ec2-eip.id
  vpc      = true

  tags {
    Name        = "${var.Name} - EIP"
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
