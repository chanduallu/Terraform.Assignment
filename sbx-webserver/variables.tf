variable "env" {
  default = "sbx"
}

variable "region" {
  default = "ap-southeast-1"
}

variable "tags" {
  default = {
    platform               = "apache"
    project                = "Assignment"
    ComponentOwner         = "chandra"
    Environment            = "sbx"
  }
}

variable "sbx-webserver_keypair" {
  default = "sbx-webserver-key.pub"
}

variable "sbx-webserver-key" {
  default = "sbx-webserver-key"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "health_check" {
  default = {
    "cookie_duration"                  = 86400
    "deregistration_delay"             = 300
    "health_check_interval"            = 30
    "health_check_healthy_threshold"   = 3
    "health_check_path"                = "/index.html"
    "health_check_port"                = "80"
    "health_check_timeout"             = 15
    "health_check_unhealthy_threshold" = 5
    "health_check_matcher"             = "200-299"
    "stickiness_enabled"               = true
    "target_type"                      = "instance"
  }
}