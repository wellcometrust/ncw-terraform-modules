# rds-sql-server
This module is set up for an sql server only because the variables required to set up an SQL RDS instace are slightly different between RDS database types.

Can be easily tweaked for other DB types.

## DB Username and Password
Obviously we don't want any DB usernames or passwords stored in Git!  Currently what you need to do to get around this is: -

* Created a terraform.tfvars file in the root of the terraform stack i.e. not in the module directory <br><br>
* gitignore the terraform.tfvars file so it is NEVER pushed to Github <br><br>
* In the variables file in the root of terraform stack declare the variables <br>
    variable "db_username" {} <br>
    variable "db_password" {} <br><br>
* In the terraform.tfvars file give the variables their value <br>
    db_username = "XXXXXXXXXXXXXX" <br>
    db_password = "XXXXXXXXXXXXXX" <br><br>
* In the terraform file where you are declaring your values for the module, declare the values as variables <br>
    db_password = "${var.db_password}" <br>
    db_username = "${var.db_username}"

