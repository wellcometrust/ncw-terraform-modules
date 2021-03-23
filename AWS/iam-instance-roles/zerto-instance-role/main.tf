# This role sets up logging to Cloudwatch for the MSSP
resource "aws_iam_role" "zerto-instance-role" {
  assume_role_policy = file("${path.module}/policies/ec2-trust.json")
  description        = "IAM Instance Role for our Zerto Instance"
  name               = "Zerto_Instance_Role"
  tags = {
    Name        = "Zerto_Instance_Role"
    Ansible       = var.Ansible
    BackUps     = var.BackUps
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment    = var.Environment
    Inspector = var.Inspector
    Internal = var.Internal
    Owner = var.Owner
    PatchGroup = var.PatchGroup
    Terraform = var.Terraform
    Use = var.Use
  }
}

resource "aws_iam_instance_profile" "zerto-instance-profile" {
  name = "Zerto_Instance_Role"
  role = aws_iam_role.zerto-instance-role.name
}

resource "aws_iam_policy" "zerto-instance-iam-policy" {
  policy = file("${path.module}/policies/zerto-permissions-policy.json")
  description = "IAM Policy granting Access for Zerto instances"
  name = "Zerto_Instance_Policy"
}


# Policy attachment for SSM
resource "aws_iam_role_policy_attachment" "amazon-ecs-role-for-ssm-attachnment" {
  policy_arn = aws_iam_policy.zerto-instance-iam-policy.arn
  role       = aws_iam_role.zerto-instance-role.id
}
