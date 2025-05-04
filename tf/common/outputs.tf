output "vpc_id" {
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
}

output "nat_public_ips" {
  # capture NAT IPs in case we want to allow-list these with external services
  value = module.vpc.nat_public_ips
}

output "bastion_instance_id" {
  value = module.bastion.id
}

output "bastion_ip" {
  value = module.bastion.public_ip
}

