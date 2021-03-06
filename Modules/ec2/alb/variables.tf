variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to false."
  default     = false
}

variable "enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancers."
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Indicates whether cross zone load balancing should be enabled in application load balancers."
  default     = false
}

variable "extra_ssl_certs" {
  description = "A list of maps describing any extra SSL certificates to apply to the HTTPS listeners. Required key/values: certificate_arn, https_listener_index (the index of the listener within https_listeners which the cert applies toward)."
  type        = list(map(string))
  default     = []
}

variable "extra_ssl_certs_count" {
  description = "A manually provided count/length of the extra_ssl_certs list of maps since the list cannot be computed."
  default     = 0
}

variable "https_listeners" {
  description = "A list of maps describing the HTTPS listeners for this ALB. Required key/values: port, certificate_arn. Optional key/values: ssl_policy (defaults to ELBSecurityPolicy-2016-08), target_group_index (defaults to 0)"
  type        = list(map(string))	
  default     = []
}

variable "https_listeners_count" {
  description = "A manually provided count/length of the https_listeners list of maps since the list cannot be computed."
  default     = 0
}

variable "http_tcp_listeners" {
  description = "A list of maps describing the HTTPS listeners for this ALB. Required key/values: port, protocol. Optional key/values: target_group_index (defaults to 0)"
  type        = list(map(string))	
  default     = []
}

variable "http_tcp_listeners_count" {
  description = "A manually provided count/length of the http_tcp_listeners list of maps since the list cannot be computed."
  default     = 0
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle."
  default     = 60
}

variable "ip_address_type" {
  description = "The type of IP addresses used by the subnets for your load balancer. The possible values are ipv4 and dualstack."
  default     = "ipv4"
}

variable "listener_ssl_policy_default" {
  description = "The security policy if using HTTPS externally on the load balancer. [See](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-policy-table.html)."
  default     = "ELBSecurityPolicy-2016-08"
}

variable "load_balancer_is_internal" {
  description = "Boolean determining if the load balancer is internal or externally facing."
  default     = false
}

variable "load_balancer_create_timeout" {
  description = "Timeout value when creating the ALB."
  default     = "10m"
}

variable "load_balancer_delete_timeout" {
  description = "Timeout value when deleting the ALB."
  default     = "10m"
}

variable "load_balancer_name" {
  description = "The resource name and Name tag of the load balancer."
}

variable "load_balancer_update_timeout" {
  description = "Timeout value when updating the ALB."
  default     = "10m"
}

variable "log_bucket_name" {
  description = "S3 bucket (externally created) for storing load balancer access logs. Required if logging_enabled is true."
  #default     = ""
}

variable "log_location_prefix" {
  description = "S3 prefix within the log_bucket_name under which logs are stored."
  default     = ""
}

variable "subnets" {
  description = "A list of subnets to associate with the load balancer. e.g. ['subnet-1a2b3c4d','subnet-1a2b3c4e','subnet-1a2b3c4f']"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "security_groups" {
  description = "The security groups to attach to the load balancer. e.g. [\"sg-edcd9784\",\"sg-edcd9785\"]"
  type        = list(string)
}

variable "target_groups" {
  description = "A list of maps containing key/value pairs that define the target groups to be created. Order of these maps is important and the index of these are to be referenced in listener definitions. Required key/values: name, backend_protocol, backend_port. Optional key/values are in the target_groups_defaults variable."
  type        = any
  default     = []
}

variable "target_groups_count" {
  description = "A manually provided count/length of the target_groups list of maps since the list cannot be computed."
  default     = 0
}

variable "target_groups_defaults" {
  description = "Default values for target groups as defined by the list of maps."
  type        = map(string)

  default = {
    "cookie_duration"                    = 86400
    "deregistration_delay"               = 300
    "health_check_interval"              = 10
    "health_check_healthy_threshold"     = 3
    "health_check_path"                  = "/"
    "health_check_port"                  = "traffic-port"
    "health_check_timeout"               = 5
    "health_check_unhealthy_threshold"   = 3
    "health_check_matcher"               = "200-299"
    "stickiness_enabled"                 = true
    "target_type"                        = "instance"
#    "lambda_multi_value_headers_enabled" = true
  }
}

variable "vpc_id" {
  description = "VPC id where the load balancer and other resources will be deployed."
}

variable "target_ids" {
  description = " List of target_ids need to added to Target Group"
  type        = list(any)
  default     = []
}

variable "instance_ids" {
  description = " List of instance_ids need to added to Target Group"
  type        = list(any)
  default     = []
}

variable "target_groups_attachments" {
  description = "A list of maps containing key/value pairs that define the target groups attachment to be created. Order of these maps is important and the index of these are to be referenced in target group definitions. Required key/values: port, target_group_index, instance_index."
  type        = list(map(string))	
  default     = []
}

variable "target_groups_attachments_count" {
  description = "A manually provided count/length of the target_groups attachment list of maps since the list cannot be computed."
  default     = 0
}

variable "http_tcp_listeners_rules" {
  description = "A list of maps containing key/value pairs that define the listner rule to be created for http/tcp requests. Order of these maps is important and the index of these are to be referenced in target group and listner definitions. Required key/values: target_group_index, listener_index"
  type        = list(map(string))	
  default     = []
}

variable "https_listeners_rules" {
  description = "A list of maps containing key/value pairs that define the target groups attachment to be created for https requests. Order of these maps is important and the index of these are to be referenced in target group definitions. Required key/values: listener_index, target_group_index."
  type        = list(map(string))	
  default     = []
}

variable "https_listeners_rules_count" {
  description = "A manually provided count/length of the https_listeners_rules_count list of maps since the list cannot be computed."
  default     = 0
}

variable "http_tcp_listeners_rules_count" {
  description = "A manually provided count/length of the https_listeners_rules_count list of maps since the list cannot be computed."
  default     = 0
}

variable "target_type_is_lambda" {
  default = false
}

variable "lambda_function_arns" {
  type    = list(string)
  default = []
}

variable "target_group_arns" {
  type    = list(string)
  default = []
}

