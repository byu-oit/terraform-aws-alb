output "alb" {
  value = aws_alb.alb
}

output "target_groups" {
  value = aws_alb_target_group.groups
}

output "listeners" {
  value = aws_alb_listener.listeners
}

output "alb_security_group" {
  value = aws_security_group.alb-sg
}