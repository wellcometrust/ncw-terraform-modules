resource "aws_db_instance" "rds-instance" {
  identifier           = var.db_name
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  license_model        = var.db_licence_model
  instance_class       = var.db_instance_class
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = var.subnet_group_name

  vpc_security_group_ids = [
    var.vpc_security_group_ids,
  ]

  multi_az                   = true
  backup_retention_period    = var.back_up_retention_period
  allocated_storage          = var.allocated_storage
  storage_type               = var.storage_type
  skip_final_snapshot        = false
  storage_encrypted          = true
  publicly_accessible        = false
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  timezone                   = "GMT Standard Time"

  tags {
    Name        = "${var.db_name} - RDS Instance"
    Owner         = var.Owner
    Division        = var.Division
    Department    = var.Department
    Cost          = var.Cost
    Terraform     = var.Terraform
    Environment   = var.Environment
    Use           = var.Use
  }
}

resource "aws_db_subnet_group" "rds-subnet-group" {
  name        = var.subnet_group_name
  description = "${var.db_name} - Subnet Group"
  subnet_ids  = [var.subnet_ids]

  tags {
    Name        = "${var.db_name}-subnet-group"
    Owner         = var.Owner
    Division        = var.Division
    Department    = var.Department
    Cost          = var.Cost
    Terraform     = var.Terraform
    Environment   = var.Environment
    Use           = var.Use
  }
}
