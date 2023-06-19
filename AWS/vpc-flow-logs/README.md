# VPC Flow Logs

This module creates an VPC Flow Logs.

## Things to Note

* Before you run this first create the vpc-flow-logs-iam-role (another module).
* The output of that module is one of the inputs of this module.
* One role is needed per account, but an account can have multiple flow logs so seperated out

