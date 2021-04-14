output "id" {
  description = "List of IDs of instances"
  value       =  element(aws_instance.this.*.id, 0)
}

output "arn" {
  description = "List of ARNs of instances"
  value       = element(aws_instance.this.*.arn, 0)
}

output "availability_zone" {
  description = "List of availability zones of instances"
  value       = element(aws_instance.this.*.availability_zone, 0)
}

output "placement_group" {
  description = "List of placement groups of instances"
  value       = element(aws_instance.this.*.placement_group, 0)
}

output "key_name" {
  description = "List of key names of instances"
  value       = element(aws_instance.this.*.key_name, 0)
}

output "password_data" {
  description = "List of Base-64 encoded encrypted password data for the instance"
  value       = element(aws_instance.this.*.password_data, 0)
}

output "public_dns" {
  description = "List of public DNS names assigned to the instances. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value       = element(aws_instance.this.*.public_dns, 0)
}

output "public_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = element(aws_instance.this.*.public_ip, 0)
}

output "ipv6_addresses" {
  description = "List of assigned IPv6 addresses of instances"
  value       = element(aws_instance.this.*.ipv6_addresses, 0)
}

output "primary_network_interface_id" {
  description = "List of IDs of the primary network interface of instances"
  value       = element(aws_instance.this.*.primary_network_interface_id, 0)
}

output "private_dns" {
  description = "List of private DNS names assigned to the instances. Can only be used inside the Amazon EC2, and only available if you've enabled DNS hostnames for your VPC"
  value       = element(aws_instance.this.*.private_dns, 0)
}

output "private_ip" {
  description = "List of private IP addresses assigned to the instances"
  value       = element(aws_instance.this.*.private_ip, 0)
}

output "security_groups" {
  description = "List of associated security groups of instances"
  value       = element(aws_instance.this.*.security_groups, 0)
}

output "vpc_security_group_ids" {
  description = "List of associated security groups of instances, if running in non-default VPC"
  value       = element(aws_instance.this.*.vpc_security_group_ids, 0)
}

output "subnet_id" {
  description = "List of IDs of VPC subnets of instances"
  value       = element(aws_instance.this.*.subnet_id, 0)
}

output "credit_specification" {
  description = "List of credit specification of instances"
  value       = element(aws_instance.this.*.credit_specification, 0)
}

output "instance_state" {
  description = "List of instance states of instances"
  value       = element(aws_instance.this.*.instance_state, 0)
}

output "root_block_device_volume_ids" {
  description = "List of volume IDs of root block devices of instances"
  value       = element(element([for device in aws_instance.this.*.root_block_device : device.*.volume_id], 0),0)
}

output "ebs_block_device_volume_ids" {
  description = "List of volume IDs of EBS block devices of instances"
  value       = [for device in aws_instance.this.*.ebs_block_device : device.*.volume_id]
}

output "tags" {
  description = "List of tags of instances"
  value       = element(aws_instance.this.*.tags, 0)
}

output "volume_tags" {
  description = "List of tags of volumes of instances"
  value       = element(aws_instance.this.*.volume_tags, 0)
}

output "instance_count" {
  description = "Number of instances to launch specified as argument to this module"
  value       = var.instance_count
}
