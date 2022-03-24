output "app_alb_dns" {
  value = module.ecr_api_server.api_server_alb_dns_name
}
output "app_ecs_cluster_name" {
  value = module.ecr_api_server.api_server_ecs_cluster_name
}

output "app_ecr_repository_arn" {
  value = module.ecr_api_server.api_server_ecr_arn
}

output "app_ecr_repository_url" {
  value = module.ecr_api_server.api_server_ecr_repository_url
}
