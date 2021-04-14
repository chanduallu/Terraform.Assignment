#######################
# Launch configuration
#######################
resource "aws_launch_configuration" "this" {
  count = var.create_lc ? 1 : 0

  name_prefix                 = "${coalesce(var.lc_name, var.name)}-"
  image_id                    = var.image_id
  instance_type               = var.instance_type
  iam_instance_profile        = var.iam_instance_profile
  key_name                    = var.key_name
  security_groups             = var.security_groups
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = var.user_data
  enable_monitoring           = var.enable_monitoring
  spot_price                  = var.spot_price
  placement_tenancy           = var.spot_price == "" ? var.placement_tenancy : ""
  ebs_optimized               = var.ebs_optimized
  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      no_device             = lookup(ebs_block_device.value, "no_device", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }
  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      device_name  = ephemeral_block_device.value.device_name
      virtual_name = ephemeral_block_device.value.virtual_name
    }
  }
  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

####################
# Autoscaling group
####################
resource "aws_autoscaling_group" "this" {
  count = var.create_asg ? 1 : 0

  name_prefix = "${join(
    "-",
    compact(
      [
        coalesce(var.asg_name, var.name),
        var.recreate_asg_when_lc_changes ? element(concat(random_pet.asg_name.*.id, [""]), 0) : "",
      ],
    ),
  )}-"
  launch_configuration = var.create_lc ? element(concat(aws_launch_configuration.this.*.name, [""]), 0) : var.launch_configuration
  vpc_zone_identifier  = var.vpc_zone_identifier
  max_size             = var.max_size
  min_size             = var.min_size
  desired_capacity     = var.desired_capacity

  load_balancers            = var.load_balancers
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type

  min_elb_capacity          = var.min_elb_capacity
  wait_for_elb_capacity     = var.wait_for_elb_capacity
  target_group_arns         = var.target_group_arns
  default_cooldown          = var.default_cooldown
  force_delete              = var.force_delete
  termination_policies      = var.termination_policies
  suspended_processes       = var.suspended_processes
  placement_group           = var.placement_group
  enabled_metrics           = var.enabled_metrics
  metrics_granularity       = var.metrics_granularity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  protect_from_scale_in     = var.protect_from_scale_in

  tags = concat(
    [
      {
        "key"                 = "Name"
        "value"               = var.name
        "propagate_at_launch" = true
      },
    ],
    var.tags,
    local.tags_asg_format,
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_pet" "asg_name" {
  count = var.recreate_asg_when_lc_changes ? 1 : 0

  separator = "-"
  length    = 2

  keepers = {
    # Generate a new pet name each time we switch launch configuration
    lc_name = var.create_lc ? element(concat(aws_launch_configuration.this.*.name, [""]), 0) : var.launch_configuration
  }
}

