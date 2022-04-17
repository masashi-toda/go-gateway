output "container_name" {
  value = "${var.container_name}"
}

output "container_port" {
  value = "${var.container_port}"
}

output "cluster_name" {
  value = "${aws_ecs_cluster.app.name}"
}

output "task_definition_arn" {
  value = "${aws_ecs_task_definition.app.arn}"
}

output "service_name" {
  value = "${aws_ecs_service.app.name}"
}
