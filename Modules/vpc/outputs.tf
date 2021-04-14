# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = element(concat(aws_vpc.this.*.id, [""]), 0)
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = element(concat(aws_vpc.this.*.cidr_block, [""]), 0)
}

output "secondary_cidr" {
  description = "The secondary CIDR block of the VPC"
  value       = var.secondary_cidr
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = element(concat(aws_vpc.this.*.default_security_group_id, [""]), 0)
}

output "default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = element(concat(aws_vpc.this.*.default_network_acl_id, [""]), 0)
}

output "default_route_table_id" {
  description = "The ID of the default route table"
  value       = element(concat(aws_vpc.this.*.default_route_table_id, [""]), 0)
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = element(concat(aws_vpc.this.*.instance_tenancy, [""]), 0)
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = element(concat(aws_vpc.this.*.enable_dns_support, [""]), 0)
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = element(concat(aws_vpc.this.*.enable_dns_hostnames, [""]), 0)
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = element(concat(aws_vpc.this.*.main_route_table_id, [""]), 0)
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = [aws_subnet.private.*.id]
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = aws_subnet.private.*.cidr_block
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = [aws_subnet.public.*.id]
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = aws_subnet.public.*.cidr_block
}

output "data_subnets" {
  description = "List of IDs of data subnets"
  value       = [aws_subnet.data.*.id]
}

output "data_subnets_cidr_blocks" {
  description = "List of cidr_blocks of data subnets"
  value       = [aws_subnet.data.*.cidr_block]
}

output "data_subnet_group" {
  description = "ID of data subnet group"
  value       = element(concat(aws_db_subnet_group.data.*.id, [""]), 0)
}

output "ecs_subnets" {
  description = "List of IDs of ecs subnets"
  value       = [aws_subnet.ecs.*.id]
}

output "ecs_subnets_cidr_blocks" {
  description = "List of cidr_blocks of ecs subnets"
  value       = [aws_subnet.ecs.*.cidr_block]
}


# Route tables
output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = [aws_route_table.public.*.id]
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = [aws_route_table.private.*.id]
}

output "data_route_table_ids" {
  description = "List of IDs of data route tables"
  value       = [coalescelist(aws_route_table.data.*.id, aws_route_table.private.*.id)]
}


output "ecs_route_table_ids" {
  description = "List of IDs of ecs route tables"
  value       = [coalescelist(aws_route_table.ecs.*.id, aws_route_table.private.*.id)]
}



# Nat gateway
output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = [aws_eip.nat.*.id]
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = [aws_eip.nat.*.public_ip]
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = [aws_nat_gateway.this.*.id]
}

# Internet Gateway
output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = element(concat(aws_internet_gateway.this.*.id, [""]), 0)
}



data "aws_caller_identity" "current" {
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

data "aws_region" "current" {
}

output "region" {
  value = data.aws_region.current.name
}

