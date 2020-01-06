terraform {
  required_version = ">= 0.12.16"
  required_providers {
    aws = ">= 2.42"
  }
}

locals {
  public_ports = keys(var.listeners)
  regular_listener_ports = toset(compact([
    for port in local.public_ports :
    (var.listeners[port].forward_to != null ? (! var.listeners[port].forward_to.ignore_changes ? port : null) : null)
  ]))
  ignore_forward_targets_listener_ports = toset(compact([
    for port in local.public_ports :
    (var.listeners[port].forward_to != null ? (var.listeners[port].forward_to.ignore_changes ? port : null) : null)
  ]))
  redirected_listener_ports = toset(compact([
    for port in local.public_ports :
    (var.listeners[port].redirect_to != null ? port : null)
  ]))
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

  // allow access to the ALB from anywhere for each and every listener port defined in the target_groups variable
  dynamic "ingress" {
    for_each = var.listeners
    content {
      protocol  = "tcp"
      from_port = ingress.key
      to_port   = ingress.key
      cidr_blocks = [
      "0.0.0.0/0"]
    }
  }

  // allow any outgoing traffic
  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  tags = var.tags
}

// Map of target groups keyed by the name_suffix
resource "aws_alb_target_group" "groups" {
  for_each = var.target_groups

  name     = "${var.name}-tg-${each.key}"
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type          = each.value.type
  deregistration_delay = each.value.deregistration_delay
  health_check {
    path                = each.value.health_check.path
    interval            = each.value.health_check.interval
    timeout             = each.value.health_check.timeout
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
  }
  stickiness {
    type            = "lb_cookie"
    cookie_duration = each.value.stickiness_cookie_duration
    enabled         = each.value.stickiness_cookie_duration != null
  }

  tags = var.tags

  depends_on = [aws_alb.alb]
}

// Map of listeners keyed by the listener port
resource "aws_alb_listener" "regular_listeners" {
  for_each = local.regular_listener_ports

  load_balancer_arn = aws_alb.alb.arn
  port              = tonumber(each.key)

  protocol        = var.listeners[each.key].protocol
  certificate_arn = var.listeners[each.key].https_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.groups[var.listeners[each.key].forward_to.target_group].arn
  }

  depends_on = [aws_alb.alb, aws_alb_target_group.groups]
}
resource "aws_alb_listener" "ignore_forward_target_listeners" {
  for_each = local.ignore_forward_targets_listener_ports

  load_balancer_arn = aws_alb.alb.arn
  port              = tonumber(each.key)

  protocol        = var.listeners[each.key].protocol
  certificate_arn = var.listeners[each.key].https_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.groups[var.listeners[each.key].forward_to.target_group].arn
  }

  lifecycle {
    ignore_changes = [default_action[0].target_group_arn]
  }
  depends_on = [aws_alb.alb, aws_alb_target_group.groups]
}

// Map of listeners keyed by the listener port
resource "aws_alb_listener" "redirected_listeners" {
  for_each = local.redirected_listener_ports

  load_balancer_arn = aws_alb.alb.arn
  port              = tonumber(each.key)

  protocol        = var.listeners[each.key].protocol
  certificate_arn = var.listeners[each.key].https_certificate_arn

  default_action {
    type = "redirect"
    redirect {
      host        = var.listeners[each.key].redirect_to.host
      path        = var.listeners[each.key].redirect_to.path
      port        = var.listeners[each.key].redirect_to.port
      protocol    = var.listeners[each.key].redirect_to.protocol
      status_code = "HTTP_301"
    }
  }

  depends_on = [aws_alb.alb, aws_alb_target_group.groups]
}