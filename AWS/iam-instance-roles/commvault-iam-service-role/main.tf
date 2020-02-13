# This is a custom role, with a custom policy that should only be given to Commvault instances in AWS
resource "aws_iam_role" "wt-commvault-role" {
  assume_role_policy = file("${path.module}/policies/ec2-trust.json")
  description        = "IAM Instance Role fopr Commvault Instances"
  name               = "WT_Commvault_IAM_Service_Role"
  tags = {
    Name        = "WT_Commvault_IAM_Service_Role"
    Owner       = var.owner
    Managed     = var.managed
    Environment = "All"
    Internal    = ""
    Cost        = var.cost
    Division    = var.division
    Department  = var.department
  }
}

esource "aws_iam_instance_profile" "wt-commvault-instance-profile" {
  name = "WT_Commvault_IAM_Instance_Profile"
  role = aws_iam_role.wt-commvault-role.name
}

resource "aws_iam_policy" "wt-commvault-role-policy" {
  policy = file("${path.module}/policies/commvault.json")
  name   = "WT_Commvault_IAM_Role_Policy"
}

resource "aws_iam_policy_attachment" "wt-commvault-policy-attachement" {
  name       = "WT_Commvault_Policy_Attachment"
  policy_arn = aws_iam_policy.wt-commvault-role-policy.arn
  roles      = [aws_iam_role.wt-commvault-role.name, aws_iam_role.wt-commvault-glacier-role.name, aws_iam_role.wt-commvault-s3-role.name]
}


# Comvault Access to S3
resource "aws_iam_role" "wt-commvault-s3-role" {
  assume_role_policy = file("${path.module}/policies/s3-trust.json")
  description        = "IAM Service Role allowing access for Commvault to S3"
  name               = "WT_Commvault_S3_Service_Role"
  tags = {
    Name        = "WT_Commvault_S3_Service_Role"
    Owner       = var.owner
    Managed     = var.managed
    Environment = "All"
    Internal    = ""
    Cost        = var.cost
    Division    = var.division
    Department  = var.department
  }
}

resource "aws_iam_policy" "wt-commvault-s3-role-policy" {
  policy = file("${path.module}/policies/commvault-s3-policy.json")
  name   = "WT_Commvault_S3_Role_Policy"
}

resource "aws_iam_policy_attachment" "wt-commvault-s3-policy-attachement" {
  name       = "WT_Commvault_S3_Policy_Attachment"
  policy_arn = aws_iam_policy.wt-commvault-s3-role-policy.arn
  roles      = [aws_iam_role.wt-commvault-s3-role.name]
}

# Comvault Access to Glacier
resource "aws_iam_role" "wt-commvault-glacier-role" {
  assume_role_policy = file("${path.module}/policies/ec2-trust.json")
  description        = "IAM Service Role allowing access for Commvault to Glacier bucket"
  name               = "WT_Commvault_Glacier_Service_Role"
  tags = {
    Name        = "WT_Commvault_Glacier_Service_Role"
    Owner       = var.owner
    Managed     = var.managed
    Environment = "All"
    Internal    = ""
    Cost        = var.cost
    Division    = var.division
    Department  = var.department
  }
}

resource "aws_iam_policy" "wt-commvault-glacier-role-policy" {
  policy = file("${path.module}/policies/commvault-glacier-policy.json")
  name   = "WT_Commvault_Glacier_Role_Policy"
}

resource "aws_iam_policy_attachment" "commvault-glacier-policy-attachement" {
  name       = "WT_Commvault_Glacier_Policy_Attachment"
  policy_arn = aws_iam_policy.wt-commvault-glacier-role-policy.arn
  roles      = [aws_iam_role.wt-commvault-glacier-role.name]
}
