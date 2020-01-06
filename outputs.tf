output "alb" {
  value = aws_alb.alb
}

output "target_groups" {
  value = aws_alb_target_group.groups
}

output "listeners" {
  value = merge(aws_alb_listener.regular_listeners, aws_alb_listener.ignore_forward_target_listeners, aws_alb_listener.redirected_listeners)
}

output "alb_security_group" {
  value = aws_security_group.alb-sg
}