module "acs" {
  source = "git@github.com:byu-oit/terraform-aws-acs-info.git?ref=v1.0.2"
  env = "dev"
}

locals {
  public_ports = [
  for port_mapping in var.port_mappings:
  tostring(port_mapping.public_port)
  ]
  target_ports = [
  for port_mapping in var.port_mappings:
  tostring(port_mapping.target_port)
  ]
  public_ports_set = toset(local.public_ports)
  target_ports_set = toset(local.target_ports)
  port_mappings = zipmap(local.public_ports, local.target_ports)

  health_check_ports = [
  for hc in var.health_checks:
  tostring(hc.port)
  ]
  health_checks_with_defaults = [
  for hc in var.health_checks:
  {
    path = hc.path
    interval = hc.interval != null ? hc.interval : 30
    timeout = hc.timeout != null ? hc.timeout : 5
    healthy_threshold = hc.healthy_threshold != null ? hc.healthy_threshold : 3
    unhealthy_threshold = hc.unhealthy_threshold != null ? hc.unhealthy_threshold : 2
  }
  ]

  health_checks = zipmap(local.health_check_ports, local.health_checks_with_defaults)
}

resource "aws_alb" "alb" {
  name = var.name
  subnets = var.subnet_ids
  security_groups = [aws_security_group.alb-sg.id]
  idle_timeout = var.idle_timeout
  tags = var.tags
}

resource "aws_security_group" "alb-sg" {
  name = "${var.name}-sg"
  description = "Controls access to the ${var.name} ALB"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.port_mappings
    content {
      protocol = "tcp"
      from_port = ingress.value.public_port
      to_port = ingress.value.public_port
      cidr_blocks = [
        "0.0.0.0/0"]
    }
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_alb_target_group" "groups" {
  for_each = local.target_ports_set

  name = "${var.name}-tg-${each.key}"
  port = each.value
  protocol = "HTTP"
  vpc_id = var.vpc_id
  deregistration_delay = var.deregistration_delay
  health_check {
    path = local.health_checks[each.value].path
//    protocol = local.health_checks[each.value].health_check_protocol
    interval = local.health_checks[each.value].interval
    timeout = local.health_checks[each.value].timeout
    healthy_threshold = local.health_checks[each.value].healthy_threshold
    unhealthy_threshold = local.health_checks[each.value].unhealthy_threshold
  }

  tags = var.tags
}

resource "aws_alb_listener" "listeners" {
  for_each = local.port_mappings

  load_balancer_arn = aws_alb.alb.arn
  port = tonumber(each.key)

  protocol = tonumber(each.key) == 443 ? "HTTPS" : "HTTP"
  certificate_arn = tonumber(each.key) == 443 ? module.acs.certificate.arn : null

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.groups[each.value].arn
  }
}