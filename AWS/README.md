# How to use these modules
1.  Create yourself a new .tf file
2.  Use module to let terraform know you want to use a module in this e.g. <br><br>
    ``` 
    module "vpc-flow-logs-role" {
      source = "modules/vpc-flow-logs-iam-role"
      name   = "VPC-flow-logs-iam-role"
    }
    ```
3.  Give values to all of the variables
4.  Run `terrafom get` to pull in the module
5.  Run your `terrafomr plan` to check changes
6.  Once happy run your `terraform apply` to roll out

Check the README.md in the module folder for additional information specific to the module. 

Any probs ask Kate :-)
