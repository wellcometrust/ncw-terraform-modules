# Create a new EBS Volume
resource "aws_ebs_volume" "ebs" {
  availability_zone = var.availability-zone
  size              = var.size

  tags {
    Name          = var.Name
    Owner         = var.Owner
    Division        = var.Division
    Department    = var.Department
    Cost          = var.Cost
    Terraform     = var.Terraform
    Environment   = var.Environment
    Internal      = var.Internal
    Use           = var.Use
    BackUps       = var.BackUps
    Ansible       = var.Ansible
    PatchGroup    = var.PatchGroup
  }
}
