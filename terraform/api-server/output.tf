output "api_server_ecs_cluster_name" {
  value = aws_ecs_cluster.app.name
}

output "api_server_ecr_arn" {
  value = aws_ecr_repository.app.arn
}

output "api_server_ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "api_server_alb_dns_name" {
  value = aws_lb.front.dns_name
}
