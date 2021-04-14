
resource "aws_lb" "application_w_instance" {
  load_balancer_type               = "application"
  name                             = var.load_balancer_name
  internal                         = var.load_balancer_is_internal
  security_groups                  = var.security_groups
  subnets                          = var.subnets
  idle_timeout                     = var.idle_timeout
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = var.enable_http2
  ip_address_type                  = var.ip_address_type
  tags = merge(
    var.tags,
    {
      "Name" = var.load_balancer_name
    },
  )

  access_logs {
    enabled = true
    bucket  = var.log_bucket_name
    prefix  = var.log_location_prefix
  }

  timeouts {
    create = var.load_balancer_create_timeout
    delete = var.load_balancer_delete_timeout
    update = var.load_balancer_update_timeout
  }

  count = var.target_type_is_lambda ? 0 : 1
}

resource "aws_lb_target_group" "main_w_instance" {
  name     = var.target_groups[count.index]["name"]
  vpc_id   = var.vpc_id
  port     = var.target_groups[count.index]["backend_port"]
  protocol = upper(var.target_groups[count.index]["backend_protocol"])
  deregistration_delay = lookup(
    var.target_groups[count.index],
    "deregistration_delay",
    var.target_groups_defaults["deregistration_delay"],
  )
  target_type = lookup(
    var.target_groups[count.index],
    "target_type",
    var.target_groups_defaults["target_type"],
  )

  health_check {
    interval = lookup(
      var.target_groups[count.index],
      "health_check_interval",
      var.target_groups_defaults["health_check_interval"],
    )
    path = lookup(
      var.target_groups[count.index],
      "health_check_path",
      var.target_groups_defaults["health_check_path"],
    )
    port = lookup(
      var.target_groups[count.index],
      "health_check_port",
      var.target_groups_defaults["health_check_port"],
    )
    healthy_threshold = lookup(
      var.target_groups[count.index],
      "health_check_healthy_threshold",
      var.target_groups_defaults["health_check_healthy_threshold"],
    )
    unhealthy_threshold = lookup(
      var.target_groups[count.index],
      "health_check_unhealthy_threshold",
      var.target_groups_defaults["health_check_unhealthy_threshold"],
    )
    timeout = lookup(
      var.target_groups[count.index],
      "health_check_timeout",
      var.target_groups_defaults["health_check_timeout"],
    )
    protocol = upper(
      lookup(
        var.target_groups[count.index],
        "healthcheck_protocol",
        var.target_groups[count.index]["backend_protocol"],
      ),
    )
    matcher = lookup(
      var.target_groups[count.index],
      "health_check_matcher",
      var.target_groups_defaults["health_check_matcher"],
    )
  }

  stickiness {
    type = "lb_cookie"
    cookie_duration = lookup(
      var.target_groups[count.index],
      "cookie_duration",
      var.target_groups_defaults["cookie_duration"],
    )
    enabled = lookup(
      var.target_groups[count.index],
      "stickiness_enabled",
      var.target_groups_defaults["stickiness_enabled"],
    )
  }

  tags = merge(
    var.tags,
    {
      "Name" = var.target_groups[count.index]["name"]
    },
  )
  count      = var.target_type_is_lambda ? 0 : var.target_groups_count
  depends_on = [aws_lb.application_w_instance]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "frontend_http_tcp_w_instance" {
  load_balancer_arn = element(
    concat(
      aws_lb.application_w_instance.*.arn,
      aws_lb.application_w_lambda.*.arn,
    ),
    0,
  )
  port     = var.http_tcp_listeners[count.index]["port"]
  protocol = var.http_tcp_listeners[count.index]["protocol"]
  count    = var.target_type_is_lambda ? 0 : var.http_tcp_listeners_count

  default_action {
    target_group_arn = aws_lb_target_group.main_w_instance[lookup(var.http_tcp_listeners[count.index], "target_group_index", count.index)].id
    type             = "forward"
  }
}

resource "aws_lb_listener" "frontend_https_w_instance" {
  load_balancer_arn = element(
    concat(
      aws_lb.application_w_instance.*.arn,
      aws_lb.application_w_lambda.*.arn,
    ),
    0,
  )
  port            = var.https_listeners[count.index]["port"]
  protocol        = "HTTPS"
  certificate_arn = var.https_listeners[count.index]["certificate_arn"]
  ssl_policy = lookup(
    var.https_listeners[count.index],
    "ssl_policy",
    var.listener_ssl_policy_default,
  )
  count = var.target_type_is_lambda ? 0 : var.https_listeners_count

  default_action {
    target_group_arn = aws_lb_target_group.main_w_instance[lookup(var.https_listeners[count.index], "target_group_index", count.index)].id
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "https_listener_w_instance" {
  listener_arn    = aws_lb_listener.frontend_https_w_instance[lookup(var.extra_ssl_certs[count.index], "https_listener_index", count.index)].arn
  certificate_arn = var.extra_ssl_certs[count.index]["certificate_arn"]
  count           = var.target_type_is_lambda ? 0 : var.extra_ssl_certs_count
}

/* Attaching target group to EC2 instances */

resource "aws_lb_target_group_attachment" "tg_attachment_w_instance" {
  target_group_arn = aws_lb_target_group.main_w_instance[lookup(var.target_groups_attachments[count.index], "target_group_index", count.index)].arn
 # target_id = var.instance_ids[lookup(var.target_groups_attachments[count.index], "instance_index", count.index)]
  target_id = element(var.instance_ids , lookup(var.target_groups_attachments[count.index], "instance_index", count.index))
  port  = var.target_groups_attachments[count.index]["port"]
  count = var.target_type_is_lambda ? 0 : var.target_groups_attachments_count
}

/* Condition based routing of https request to target */

/*resource "aws_lb_listener_rule" "static_https_w_instance" {
  listener_arn = aws_lb_listener.frontend_https_w_instance[lookup(var.https_listeners_rules[count.index], "listener_index", count.index)].id

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main_w_instance[lookup(
      var.https_listeners_rules[count.index],
      "target_group_index",
      0,
    )].id
  }

  condition {
   field = var.https_listeners_rules[count.index]["field"]
   
    values = [var.https_listeners_rules[count.index]["values"]]
  }

  count = var.target_type_is_lambda ? 0 : var.https_listeners_rules_count
}*/

/* Condition based routing of http/tcp request to target group  */

/*resource "aws_lb_listener_rule" "static_w_instance" {
  listener_arn = aws_lb_listener.frontend_http_tcp_w_instance[lookup(
    var.http_tcp_listeners_rules[count.index],
    "listener_index",
    0,
  )].id

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main_w_instance[lookup(
      var.http_tcp_listeners_rules[count.index],
      "target_group_index",
      0,
    )].id
  }

  condition {
   field = var.http_tcp_listeners_rules[count.index]["field"]
    
    values = [var.http_tcp_listeners_rules[count.index]["values"]]
  }

  count = var.target_type_is_lambda ? 0 : var.http_tcp_listeners_rules_count
}

*/