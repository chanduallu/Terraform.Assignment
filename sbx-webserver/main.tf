## terraform backend configuration ##

terraform {
  backend "s3" {
    bucket = "terraform-sbx-s3"
    key    = "sbx-vpc/sbx-webserver/statefile.tfstate"
    region = "ap-southeast-1"
  }
}

## Infra provider configuration ##

provider "aws" {
  region = var.region
}

## Data sources definitions ##


data "terraform_remote_state" "sbx-vpc" {
  backend = "s3"

  config = {
    bucket = "terraform-sbx-s3"
    key    = "sbx-vpc/statefile.tfstate"
    region = "ap-southeast-1"
  }
}


#########################
## Public ALB and ALB SG 
#########################

module "pub-alb-sg" {
  source = "../Modules/ec2/security-group"

  name        = "${var.env}-public-alb-sg"
  description = "alb public Security Group"
  vpc_id      = data.terraform_remote_state.sbx-vpc.outputs.vpc_id
  tags = merge(
    var.tags,
    {
      "Resource_Role" = "Security-Group"
    },
  )

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from Internet to access"
      cidr_blocks = "0.0.0.0/0"
    },
    
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "Outbound Access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "public-alb" {
  source = "../Modules/ec2/alb"

  load_balancer_is_internal        = false
  security_groups                  = [module.pub-alb-sg.this_security_group_id]
  subnets                          = data.terraform_remote_state.sbx-vpc.outputs.public_subnets[0]
  enable_cross_zone_load_balancing = true
  load_balancer_name               = "${var.env}-public-alb"
  tags = merge(
    var.tags,
    {
      "Resource_Role" = "Public ALB"
    },
  )
  log_location_prefix   = "alb-logs"
  log_bucket_name       = "${var.env}-alb-logging"
  vpc_id                = data.terraform_remote_state.sbx-vpc.outputs.vpc_id
  

  target_groups = [
    {
      "name"                = "Web-app-80"
      "backend_protocol"    = "HTTP"
      "backend_port"        = "80"
    }
    
  ]

  target_groups_count = 1
  
  http_tcp_listeners = [
    {
      "port"               = "80"
      "protocol"           = "HTTP"
      "target_group_index" = "0"
    },
  ]
 
  http_tcp_listeners_count = 1


  target_groups_defaults = var.health_check
  
  
}


## key pair can be generated before running the terraform init and create keypair in AWS by uncommenting below block

/*resource "aws_key_pair" "sbx-webserver-key" {
  key_name   = "sbx-webserver-key"
  public_key = file(var.sbx-webserver_keypair)
}*/

## Creating s3 logging bucket

module "s3-logging-bucket" {
  source = "../Modules/s3"

  name               = "${var.env}-s3-logging"
  acl                = "log-delivery-write"
  s3_logging_bucket  = "${var.env}-s3-logging"
  versioning_enabled = false
  sse_algorithm      = "AES256"
}

## Creating s3 logging bucket

module "alb-logging-bucket" {
  source = "../Modules/s3"

  name               = "${var.env}-alb-logging"
  s3_logging_bucket  = "${var.env}-s3-logging"
  versioning_enabled = false
  sse_algorithm      = "AES256"
  add_bucket_policy  = 1
  bucket_policy      = data.template_file.alb_bucket_policy.rendered
}

data "template_file" "alb_bucket_policy" {
  template = file("./alb_logging_policy.json")
  vars = {
      bucket = "${var.env}-alb-logging"
  }
}

## Creating App bucket
module "app-bucket" {
  source = "../Modules/s3"

  name               = "${var.env}-app-bucket"
  s3_logging_bucket  = "${var.env}-s3-logging"
  versioning_enabled = true
  sse_algorithm      = "AES256"
}

###### iam s3 policy ######

data "template_file" "s3_access_policy" {
  template = file("./s3_access_policy.json")
  vars = {
    app = "${var.env}-app-bucket"
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name   = "s3_access_policy"
  policy = data.template_file.s3_access_policy.rendered
}
## Iam Instance profile

module "sbx-webserver-role" {
  source      = "../Modules/ec2/ec2-iam-role"
  name        = "sbx_webserver_role"
  description = "Instance profile for webs erver"
  policy_arn  = [aws_iam_policy.s3_access_policy.arn]
}



module "sbx-webserver-security-group" {
  source = "../Modules/ec2/security-group"

  name        = "${var.env}-webserver-sg"
  description = "Security to allow requests from public alb and bastion"
  vpc_id      = data.terraform_remote_state.sbx-vpc.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow Access from bastion"
      cidr_blocks = data.terraform_remote_state.sbx-vpc.outputs.public_subnets_cidr_blocks[0]
    },
    
  ]

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "TCP"
      description              = "webserver alb ec2 rule"
      source_security_group_id = module.pub-alb-sg.this_security_group_id
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "Outbound Access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = merge(
    var.tags,
    {
      "Resource_Role" = "Webserver Security Group"
    },
  )
}

####################
## Java webserver 
####################

data "template_file" "user_config" {
  template = file("./cloud-config.yml")
  vars ={
    
  }
  }

data "template_cloudinit_config" "cloud_config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "main.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.user_config.rendered
  }
}

data "aws_ami" "latest-ami" {
most_recent = true
owners = ["137112412989"] 

  filter {
      name   = "name"
      values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}


module "web-server-asg" {
  source = "../Modules/ec2/autoscaling"
  name   = "${var.env}_webserver_HA"

  ## Webserver LC ##

  lc_name              = "${var.env}-webserver-lc"
  image_id             = data.aws_ami.latest-ami.id
  instance_type        = var.instance_type
  iam_instance_profile = module.sbx-webserver-role.name
  key_name             = var.sbx-webserver-key
  security_groups      = [module.sbx-webserver-security-group.this_security_group_id]
  root_block_device = [
    {
      volume_type           = "gp2"
      volume_size           = 20
      delete_on_termination = false
    },
  ]
  user_data = data.template_cloudinit_config.cloud_config.rendered

  #################################
  ## Webserver ASG ##
  #################################  

  asg_name                     = "${var.env}-webserver-asg"
  vpc_zone_identifier          = data.terraform_remote_state.sbx-vpc.outputs.private_subnets[0]
  max_size                     = 2
  min_size                     = 1
  desired_capacity             = 1
  wait_for_capacity_timeout    = 0
  health_check_grace_period    = 300
  force_delete                 = false
  health_check_type            = "EC2"
  recreate_asg_when_lc_changes = true
  target_group_arns            = [module.public-alb.target_group_arns[0]]
  tags_as_map = merge(
    var.tags,
    {
      "Resource_Role" = "webserver ASG"
    },
  )
}