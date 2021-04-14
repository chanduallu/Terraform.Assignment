resource "aws_lb" "application_w_lambda" {
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

  count = var.target_type_is_lambda ? 1 : 0
}

resource "aws_lb_target_group" "main_w_lambda" {
  name = var.target_groups[count.index]["name"]
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
/*  lambda_multi_value_headers_enabled = lookup(
    var.target_groups[count.index],
    "lambda_multi_value_headers_enabled",
    var.target_groups_defaults["lambda_multi_value_headers_enabled"],
  )*/

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
  count      = var.target_type_is_lambda ? var.target_groups_count : 0
  depends_on = [aws_lb.application_w_lambda]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "frontend_http_tcp_w_lambda" {
  load_balancer_arn = element(concat(aws_lb.application_w_lambda.*.arn, [""]), 0)
  port              = var.http_tcp_listeners[count.index]["port"]
  protocol          = var.http_tcp_listeners[count.index]["protocol"]
  count             = var.target_type_is_lambda ? var.http_tcp_listeners_count : 0

  default_action {
    target_group_arn = aws_lb_target_group.main_w_lambda[lookup(var.http_tcp_listeners[count.index], "target_group_index", count.index)].id
    type             = "forward"
  }
}

resource "aws_lb_listener" "frontend_https_w_lambda" {
  load_balancer_arn = element(concat(aws_lb.application_w_lambda.*.arn, [""]), 0)
  port              = var.https_listeners[count.index]["port"]
  protocol          = "HTTPS"
  certificate_arn   = var.https_listeners[count.index]["certificate_arn"]
  ssl_policy = lookup(
    var.https_listeners[count.index],
    "ssl_policy",
    var.listener_ssl_policy_default,
  )
  count = var.target_type_is_lambda ? var.https_listeners_count : 0

  default_action {
    target_group_arn = aws_lb_target_group.main_w_lambda[lookup(var.https_listeners[count.index], "target_group_index", count.index)].id
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "https_listener_w_lambda" {
  listener_arn    = aws_lb_listener.frontend_https_w_instance[lookup(var.extra_ssl_certs[count.index] ,"https_listener_index", count.index)].arn
  certificate_arn = var.extra_ssl_certs[count.index]["certificate_arn"]
  count           = var.target_type_is_lambda ? var.extra_ssl_certs_count : 0
}

/* Attaching target group to Lambda */

resource "aws_lb_target_group_attachment" "tg_attachment_w_lambda" {
  target_group_arn = aws_lb_target_group.main_w_lambda[lookup(
    var.target_groups_attachments[count.index],
    "target_group_index",
    0,
  )].arn
  target_id = var.target_ids[lookup(
    var.target_groups_attachments[count.index],
    "target_index",
    0,
  )]
  depends_on = [aws_lambda_permission.allow_alb]
  count      = var.target_type_is_lambda ? var.target_groups_attachments_count : 0
}

/* Condition based routing of https request to target */

/*resource "aws_lb_listener_rule" "static_https_w_lambda" {
  listener_arn = aws_lb_listener.frontend_https_w_lambda[lookup(var.https_listeners_rules[count.index], "listener_index", count.index)].id

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main_w_lambda[lookup(
      var.https_listeners_rules[count.index],
      "target_group_index",
      0,
    )].id
  }

  condition {
    field = var.https_listeners_rules[count.index]["field"]
    
    values = [var.https_listeners_rules[count.index]["values"]]
  }

  count = var.target_type_is_lambda ? var.https_listeners_rules_count : 0
}*/

/* Condition based routing of http/tcp request to target group  */

/*resource "aws_lb_listener_rule" "static_w_lambda" {
  listener_arn = aws_lb_listener.frontend_http_tcp_w_lambda[lookup(
    var.http_tcp_listeners_rules[count.index],
    "listener_index",
    0,
  )].id

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main_w_lambda[lookup(
      var.http_tcp_listeners_rules[count.index],
      "target_group_index",
      0,
    )].id
  }

condition {
  field = var.http_tcp_listeners_rules[count.index]["field"]
    
    values = [var.http_tcp_listeners_rules[count.index]["values"]]
  }

  count = var.target_type_is_lambda ? var.http_tcp_listeners_rules_count : 0
}*/

resource "aws_lambda_permission" "allow_alb" {
  count         = var.target_type_is_lambda ? length(var.lambda_function_arns) : 0
  statement_id  = "AllowExecutionFromlb-${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arns[count.index]
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = var.target_group_arns[count.index]
}

