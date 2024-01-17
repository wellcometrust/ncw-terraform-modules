# This role sets up logging to Cloudwatch for the MSSP and gives read access to EC2/ALB configuration"
resource "aws_iam_role" "wt-panorama-instance-role" {
  assume_role_policy = file("${path.module}/policies/ec2-trust.json")
  description        = "IAM Instance Role, that sets up Cloudwatch Logging and MSSP and gives read access to EC2/ALB configuration"
  name               = "WT_Panorama_Instance_Role"
  tags = {
    Name        = "WT_Panorama_Instance_Role"
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Owner       = var.Owner
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

resource "aws_iam_instance_profile" "wt-panorama-instance-profile" {
  name = "WT_Panorama_Instance_Role"
  role = aws_iam_role.wt-panorama-instance-role.name
  tags = {
    Name        = "WT_Panorama_Instance_Profile"
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Owner       = var.Owner
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

# Policy attachment for SSM
resource "aws_iam_role_policy_attachment" "amazon-ecs-role-for-ssm-attachnment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.wt-panorama-instance-role.id
}

# Policy attachment SSM Instance Core
resource "aws_iam_role_policy_attachment" "amazon-ssm-managed-instance-core-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.wt-panorama-instance-role.id
}

# Policy attachment for Cloud Watch Logging
resource "aws_iam_role_policy_attachment" "cloudwatch-agent-server-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.wt-panorama-instance-role.id
}

# Policy attachment to allow reading EC2 instances and ALBs configuration
resource "aws_iam_role_policy_attachment" "amazon-ec2readonly-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = aws_iam_role.wt-panorama-instance-role.id
}

# Policy to extend the role to all AWS accounts
resource "aws_iam_policy" "panorama-role-for-other-accounts-policy" {
  policy      = file("${path.module}/policies/wt-panorama-policy.json")
  description = "This policy allows Panorama instances to assume a role in other AWS accounts"
  name        = "WT_Panorama-AssumeRole"
  tags = {
    Name        = "WT_Panorama-AssumeRole"
    Owner       = var.owner
    Terraform   = var.terraform
    Environment = "All"
    Cost        = var.cost-a281
    Division    = var.division
    Department  = var.department
    Monitoring  = var.Monitoring
    Use         = var.use-palo
  }
}

resource "aws_iam_role_policy_attachment" "panorama-role-for-other-accounts-policy-attachment" {
  policy_arn = aws_iam_policy.panorama-role-for-other-accounts-policy.arn
  role       = aws_iam_role.wt-panorama-instance-role.id
}