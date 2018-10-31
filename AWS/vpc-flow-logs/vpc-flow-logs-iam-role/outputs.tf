output "vpc-flow-log-role-arn" {
  value = "${aws_iam_role.vpc_flow_logs_role.arn}"
}
