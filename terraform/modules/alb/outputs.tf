output "arn" {
  value = "${aws_lb.alb.arn}"
}

output "dns_name" {
  value = "${aws_lb.alb.dns_name}"
}

output "listener_arn" {
  value = "${aws_lb_listener.alb.arn}"
}

output "target_group_arn" {
  value = {
    blue  = "${aws_lb_target_group.blue.arn}"
    green = "${aws_lb_target_group.green.arn}"
  }
}

output "target_group_name" {
  value = {
    blue  = "${aws_lb_target_group.blue.name}"
    green = "${aws_lb_target_group.green.name}"
  }
}

output "security_group_id" {
  value = "${aws_security_group.alb.id}"
}
