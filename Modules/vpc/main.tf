terraform {
  required_version = ">= 0.10.3" # introduction of Local Values configuration language feature
}

locals {
  max_subnet_length = max(
    length(var.private_subnets),
    length(var.ecs_subnets),
    length(var.data_subnets),
    )
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? local.max_subnet_length > 0 ? length(var.azs) : 0 : local.max_subnet_length
}

######
# VPC
######
resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block                       = var.cidr
  instance_tenancy                 = var.instance_tenancy
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  tags = merge(
    {
      "Name"          = format("%s", var.name)
      "Resource_Role" = "VPC"
    },
    var.vpc_tags,
    var.tags,
  )
}

###################
# Additional VPC CIDR Block
###################
resource "aws_vpc_ipv4_cidr_block_association" "vpc_secondary_cidr" {
  count      = var.enable_secondary_cidr ? 1 : 0
  vpc_id     = aws_vpc.this[0].id
  cidr_block = var.secondary_cidr
}

###################
# VPC Flow Logs
###################
## can be used once role is created

/*
data "aws_iam_role" "vpc_flowlog_role" {
  name = "VPCFlowlogsRole"
}

resource "aws_cloudwatch_log_group" "vpc_flowlog" {
  name = "VPCFlowlogs"
}

#flow log to cloudwatch
resource "aws_flow_log" "vpc_flow_log" {
  count                = var.create_vpc_flowlogs ? 1 : 0
  log_destination      = aws_cloudwatch_log_group.vpc_flowlog.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = data.aws_iam_role.vpc_flowlog_role.arn
  vpc_id               = aws_vpc.this[0].id
  traffic_type         = "ALL"
}

*/

###################
# DHCP Options Set
###################
resource "aws_vpc_dhcp_options" "this" {
  count = var.create_vpc && var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(
    {
      "Name"          = format("%s", var.name)
      "Resource_Role" = "DHCP_Options"
    },
    var.dhcp_options_tags,
    var.tags,
  )
}

###############################
# DHCP Options Set Association
###############################
resource "aws_vpc_dhcp_options_association" "this" {
  count = var.create_vpc && var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.this[0].id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "this" {
  count = var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = merge(
    {
      "Name"          = format("%s", var.name)
      "Resource_Role" = "IGW"
    },
    var.igw_tags,
    var.tags,
  )
}

################
# Publiс routes
################
resource "aws_route_table" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = merge(
    {
      "Name"          = format("%s-public", var.name)
      "Resource_Role" = "Route_Table"
    },
    var.public_route_table_tags,
    var.tags,
  )
}

resource "aws_route" "public_internet_gateway" {
  count = var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

#################
# Private routes
#################
resource "aws_route_table" "private" {
  count = var.create_vpc && local.max_subnet_length > 0 ? local.nat_gateway_count : 0

  vpc_id = aws_vpc.this[0].id

  tags = merge(
    {
      "Name"          = var.single_nat_gateway ? "${var.name}-private" : format("%s-private-%s", var.name, element(var.azs, count.index))
      "Resource_Role" = "Route_Table"
    },
    var.private_route_table_tags,
    var.tags,
  )

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = [propagating_vgws]
  }
}

#################
# data routes
#################
resource "aws_route_table" "data" {
  count = var.create_vpc && var.create_data_subnet_route_table && length(var.data_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = merge(
    var.tags,
    var.data_route_table_tags,
    {
      "Name"          = "${var.name}-data"
      "Resource_Role" = "Route_Table"
    },
  )
}



#################
# ecs routes
#################
resource "aws_route_table" "ecs" {
  count = var.create_vpc && var.create_ecs_subnet_route_table && length(var.ecs_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = merge(
    var.tags,
    var.ecs_route_table_tags,
    {
      "Name"          = "${var.name}-ecs"
      "Resource_Role" = "Route_Table"
    },
  )
}




################
# Public subnet
################
resource "aws_subnet" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 && false == var.one_nat_gateway_per_az || length(var.public_subnets) >= length(var.azs) ? length(var.public_subnets) : 0

  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    {
      "Name" = format("%s-public-%s", var.name, element(var.azs, count.index))
    },
    var.public_subnet_tags,
    var.tags,
    {
      "Tier"          = "Public"
      "Resource_Role" = "Subnet"
    },
  )
}

#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count = var.create_vpc && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  vpc_id            = aws_vpc.this[0].id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      "Name" = format("%s-private-%s", var.name, element(var.azs, count.index))
    },
    var.public_subnet_tags,
    var.tags,
    {
      "Tier"          = "Private"
      "Resource_Role" = "Subnet"
    },
  )
}

##################
# data subnet
##################
resource "aws_subnet" "data" {
  count = var.create_vpc && length(var.data_subnets) > 0 ? length(var.data_subnets) : 0

  vpc_id            = aws_vpc.this[0].id
  cidr_block        = var.data_subnets[count.index]
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      "Name" = format("%s-db-%s", var.name, element(var.azs, count.index))
    },
    var.data_subnet_tags,
    var.tags,
  )
}

resource "aws_db_subnet_group" "data" {
  count = var.create_vpc && length(var.data_subnets) > 0 && var.create_data_subnet_group ? 1 : 0

  name        = lower(var.name)
  description = "data subnet group for ${var.name}"
  subnet_ids  = aws_subnet.data.*.id

  tags = merge(
    {
      "Name" = format("%s-data-%s", var.name, element(var.azs, count.index))
    },
    var.public_subnet_tags,
    var.tags,
    {
      "Tier"          = "Data"
      "Resource_Role" = "Subnet"
    },
  )
}



#####################
# ecs subnet
#####################
resource "aws_subnet" "ecs" {
  count = var.create_vpc && length(var.ecs_subnets) > 0 ? length(var.ecs_subnets) : 0

  vpc_id            = aws_vpc.this[0].id
  cidr_block        = var.ecs_subnets[count.index]
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      "Name" = format("%s-ecs-%s", var.name, element(var.azs, count.index))
    },
    var.public_subnet_tags,
    var.tags,
    {
      "Tier"          = "ECS"
      "Resource_Role" = "Subnet"
    },
  )
}



##############
# NAT Gateway
##############
locals {
  nat_gateway_ips = split(
    ",",
    var.reuse_nat_ips ? join(",", var.external_nat_ip_ids) : join(",", aws_eip.nat.*.id),
  )
}

resource "aws_eip" "nat" {
  count = var.create_vpc && var.enable_nat_gateway && false == var.reuse_nat_ips ? local.nat_gateway_count : 0

  vpc = true

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
      "Resource_Role" = "EIP"
    },
    var.nat_eip_tags,
    var.tags,
  )
}

resource "aws_nat_gateway" "this" {
  count = var.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
    aws_subnet.public.*.id,
    var.single_nat_gateway ? 0 : count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
      "Resource_Role" = "NAT_Gateway"
    },
    var.nat_gateway_tags,
    var.tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat_gateway" {
  count = var.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)

  timeouts {
    create = "5m"
  }
}


##########################
# Route table association
##########################
resource "aws_route_table_association" "private" {
  count = var.create_vpc && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(
    aws_route_table.private.*.id,
    var.single_nat_gateway ? 0 : count.index,
  )
}

resource "aws_route_table_association" "data" {
  count = var.create_vpc && length(var.data_subnets) > 0 ? length(var.data_subnets) : 0

  subnet_id = element(aws_subnet.data.*.id, count.index)
  route_table_id = element(
    coalescelist(aws_route_table.data.*.id, aws_route_table.private.*.id),
    var.single_nat_gateway || var.create_data_subnet_route_table ? 0 : count.index,
  )
}


resource "aws_route_table_association" "ecs" {
  count = var.create_vpc && length(var.ecs_subnets) > 0 ? length(var.ecs_subnets) : 0

  subnet_id = element(aws_subnet.ecs.*.id, count.index)
  route_table_id = element(
    coalescelist(aws_route_table.ecs.*.id, aws_route_table.private.*.id),
    var.single_nat_gateway || var.create_ecs_subnet_route_table ? 0 : count.index,
  )
}


resource "aws_route_table_association" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

