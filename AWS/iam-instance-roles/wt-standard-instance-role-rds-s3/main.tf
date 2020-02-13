# This role sets up logging to Cloudwatch for the MSSP and in addition gives access to S3 and RDS for those EC2 instances that have it applied
resource "aws_iam_role" "wt-standard-instance-role-rds-s3" {
  assume_role_policy = file("${path.module}/policies/ec2-trust.json")
  description        = "IAM Instance Role, that sets up Cloudwatch Logging and MSSP and gives access to S3 and RDS"
  name               = "WT_Standard_Instance_Role_RDS_S3"
  tags = {
    Name        = "WT_Standard_Instance_Role_RDS_S3"
    Owner       = var.owner
    Managed     = var.managed
    Environment = "All"
    Internal    = ""
    Cost        = var.cost
    Division    = var.division
    Department  = var.department
  }
}

resource "aws_iam_instance_profile" "wt-standard-instance-profile-rds-s3" {
  name = "WT_Standard_Instance_Role_S3"
  role = aws_iam_role.wt-standard-instance-role-rds-s3.name
}

# Policy and attachment for SSM
resource "aws_iam_policy" "amazon-ec2-role-for-ssm" {
  policy = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role   = aws_iam_role.wt-standard-instance-role-rds-s3.id
}

resource "aws_iam_role_policy_attachment" "amazon-ecs-role-for-ssm-attachnment" {
  policy_arn = aws_iam_policy.amazon-ec2-role-for-ssm.arn
  role       = aws_iam_role.wt-standard-instance-role-rds-s3.id
}

# Policy and attachment SSM Instance Core
resource "aws_iam_policy" "amazon-ssm-managed-instance-core" {
  policy = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role   = aws_iam_role.wt-standard-instance-role-rds-s3.id
}

resource "aws_iam_role_policy_attachment" "amazon-ssm-managed-instance-core-attachment" {
  policy_arn = aws_iam_policy.amazon-ssm-managed-instance-core.arn
  role       = aws_iam_role.wt-standard-instance-role-rds-s3.id
}

# Policy and attachment for Cloud Watch Logging
resource "aws_iam_policy" "cloudwatch-agent-server-policy" {
  policy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role   = aws_iam_role.wt-standard-instance-role-rds-s3.id
}

resource "aws_iam_role_policy_attachment" "cloudwatch-agent-server-policy-attachment" {
  policy_arn = aws_iam_policy.cloudwatch-agent-server-policy.arn
  role       = aws_iam_role.wt-standard-instance-role-rds-s3.id
}

# Policy and attachement to allow access to all S3
resource "aws_iam_policy" "amazon-s3-full-access" {
  policy = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role   = aws_iam_role.wt-standard-instance-role-rds-s3.id
}

resource "aws_iam_role_policy_attachment" "amazon-s3-full-access-attachment" {
  policy_arn = aws_iam_policy.amazon-s3-full-access.arn
  role       = aws_iam_role.wt-standard-instance-role-rds-s3.id
}

# Policy and attachement to allow access to RDS
resource "aws_iam_policy" "amazon-rds-full-access" {
  policy = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  role   = aws_iam_role.wt-standard-instance-role-rds-s3.id
}

resource "aws_iam_role_policy_attachment" "amazon-rds-full-access-attachment" {
  policy_arn = aws_iam_policy.amazon-rds-full-access.arn
  role       = aws_iam_role.wt-standard-instance-role-rds-s3.id
}
