# This role sets up logging to Cloudwatch for the MSSP
resource "aws_iam_role" "wt-standard-instance-role" {
  assume_role_policy = file("${path.module}/policies/ec2-trust.json")
  description        = "IAM Instance Role, that sets up Cloudwatch Logging and MSSP"
  name               = "WT_Standard_Instance_Role"
  tags = {
    Name        = "WT_Standard_Instance_Role"
    Owner       = var.owner
    Managed     = var.managed
    Environment = "All"
    Internal    = ""
    Cost        = var.cost
    Division    = var.division
    Department  = var.department
  }
}

resource "aws_iam_instance_profile" "wt-standard-instance-profile" {
  name = "WT_Standard_Instance_Role"
  role = aws_iam_role.wt-standard-instance-role.name
}

# Policy attachment for SSM
resource "aws_iam_role_policy_attachment" "amazon-ecs-role-for-ssm-attachnment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.wt-standard-instance-role.id
}

# Policy attachment SSM Instance Core
resource "aws_iam_role_policy_attachment" "amazon-ssm-managed-instance-core-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.wt-standard-instance-role.id
}

# Policy attachment for Cloud Watch Logging
resource "aws_iam_role_policy_attachment" "cloudwatch-agent-server-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.wt-standard-instance-role.id
}