# This cross-account role sets up logging to Cloudwatch for the MSSP and gives read access to EC2/ALB configuration"
resource "aws_iam_role" "wt-panorama-cross-account-instance-role" {
  assume_role_policy = file("${path.module}/policies/ec2-trust.json")
  description        = "IAM Cross Account Instance Role, that sets up Cloudwatch Logging and MSSP and gives read access to EC2/ALB configuration"
  name               = "WT_Panorama_Cross_Account_Instance_Role"
  tags = {
    Name        = "WT_Panorama_Cross_Account_Instance_Role"
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Monitoring  = var.Monitoring
    Owner       = var.Owner
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

resource "aws_iam_instance_profile" "wt-panorama-cross-account-instance-profile" {
  name = "WT_Panorama_Instance_Role"
  role = aws_iam_role.wt-panorama-cross-account-instance-role.name
  tags = {
    Name        = "WT_Panorama_Cross_Account_Instance_Profile"
    Cost        = var.Cost
    Department  = var.Department
    Division    = var.Division
    Environment = var.Environment
    Monitoring  = var.Monitoring
    Owner       = var.Owner
    Terraform   = var.Terraform
    Use         = var.Use
  }
}

# Policy attachment for SSM
resource "aws_iam_role_policy_attachment" "amazon-ecs-role-for-ssm-attachnment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.wt-panorama-cross-account-instance-role.id
}

# Policy attachment SSM Instance Core
resource "aws_iam_role_policy_attachment" "amazon-ssm-managed-instance-core-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.wt-panorama-cross-account-instance-role.id
}

# Policy attachment for Cloud Watch Logging
resource "aws_iam_role_policy_attachment" "cloudwatch-agent-server-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.wt-panorama-cross-account-instance-role.id
}

# Policy attachment to allow reading EC2 instances and ALBs configuration
resource "aws_iam_role_policy_attachment" "amazon-ec2readonly-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = aws_iam_role.wt-panorama-cross-account-instance-role.id
}