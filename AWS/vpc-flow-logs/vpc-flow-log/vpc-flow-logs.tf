# VPC Flow Logs for VPC
resource "aws_flow_log" "prod-vpc-flow-log" {
  iam_role_arn   = "${var.vpc_flow_log_role_arn}"
  log_group_name = "${aws_cloudwatch_log_group.prod-vpc-flow-log-group.name}"
  vpc_id         = "${var.vpc_id}"
  traffic_type   = "ALL"
}
