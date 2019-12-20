module "acs" {
  source = "git@github.com:byu-oit/terraform-aws-acs-info.git?ref=v1.0.4"
  env    = "dev"
}

locals {
  public_ports_flattened = flatten(local.public_ports)
  target_ports = [
    for tg in var.target_groups:
    tg.port
  ]
  target_group_suffixes = [
    for tg in var.target_groups:
    tg.name_suffix
  ]
  mappings = flatten([
    for tg in var.target_groups:
    [
      for public_port in tg.listener_ports:
      {
        public_port = public_port
        target_group_suffix = tg.name_suffix
      }
    ]
  ])
  target_groups_map = zipmap(local.target_group_suffixes, var.target_groups)

  public_ports = [
  for p in local.mappings:
    tostring(p.public_port)
  ]
  listener_tg_suffixes = [
  for p in local.mappings:
    p.target_group_suffix
  ]
  listeners_map = zipmap(local.public_ports, local.listener_tg_suffixes)
}

resource "aws_alb" "alb" {
  name            = var.name
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.alb-sg.id]
  idle_timeout    = var.idle_timeout
  tags            = var.tags
}

resource "aws_security_group" "alb-sg" {
  name        = "${var.name}-sg"
  description = "Controls access to the ${var.name} ALB"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.public_ports
    content {
      protocol  = "tcp"
      from_port = ingress.value
      to_port   = ingress.value
      cidr_blocks = [
      "0.0.0.0/0"]
    }
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_alb_target_group" "groups" {
  for_each             = local.target_groups_map

  name                 = "${var.name}-tg-${each.value.name_suffix}"
  port                 = each.value.port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id

  target_type          = each.value.config != null ? each.value.config.type : var.default_target_group_config.type
  deregistration_delay = each.value.config != null ? each.value.config.deregistration_delay : var.default_target_group_config.deregistration_delay
  health_check {
    path                = each.value.config != null ? each.value.config.health_check.path : var.default_target_group_config.health_check.path
    interval            = each.value.config != null ? each.value.config.health_check.interval : var.default_target_group_config.health_check.interval
    timeout             = each.value.config != null ? each.value.config.health_check.timeout : var.default_target_group_config.health_check.timeout
    healthy_threshold   = each.value.config != null ? each.value.config.health_check.healthy_threshold : var.default_target_group_config.health_check.healthy_threshold
    unhealthy_threshold = each.value.config != null ? each.value.config.health_check.unhealthy_threshold : var.default_target_group_config.health_check.unhealthy_threshold
  }

  stickiness {
    type = "lb_cookie"
    cookie_duration = each.value.config != null? each.value.config.stickiness_cookie_duration : var.default_target_group_config.stickiness_cookie_duration
    enabled = each.value.config != null ? each.value.config.stickiness_cookie_duration != null : var.default_target_group_config.stickiness_cookie_duration != null
  }

  tags = var.tags

  depends_on = [aws_alb.alb]
}

resource "aws_alb_listener" "listeners" {
    for_each = local.listeners_map

  load_balancer_arn = aws_alb.alb.arn
  port              = tonumber(each.key)

  protocol        = tonumber(each.key) == 443 ? "HTTPS" : "HTTP"
  certificate_arn = tonumber(each.key) == 443 ? module.acs.certificate.arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.groups[each.value].arn
  }

  depends_on = [aws_alb.alb, aws_alb_target_group.groups]
}