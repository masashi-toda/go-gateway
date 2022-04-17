output "outputs" {
  value = {
    alb_dns = module.alb.dns_name
    nlb_dns = module.nlb.dns_name
    ecr_repo_url = module.ecr.repository_url
  }
}
