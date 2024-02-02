output "region" {
  value = var.region
}

output "server_id" {
  value = module.server.instance_id
}

output "vpc_cidr" {
  value = var.vpc_cidr
}
