resource "aws_internet_gateway" "prod" {
  vpc_id = aws_vpc.prod.id

  tags {
    Name        = "${var.vpc_name} - Prod-gateway"
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
