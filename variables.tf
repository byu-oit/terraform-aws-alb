// Required
variable "name" {
  type        = string
  description = "Application Load Balancer name to be used for naming resources."
}
variable "vpc_id" {
  type        = string
  description = "ID of the VPC."
}
variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the targets of the ALB."
}
variable "target_groups" {
  type = map(object({
    port                 = number
    type                 = string
    deregistration_delay = number
    slow_start = number
    stickiness_cookie_duration = number
    health_check = object({
      path                = string
      interval            = number
      timeout             = number
      healthy_threshold   = number
      unhealthy_threshold = number
    })
  }))
  description = "Map of target groups with the key as the target group name suffix"
}
variable "listeners" {
  type = map(object({
    protocol              = string
    https_certificate_arn = string
    forward_to = object({
      target_group   = string
      ignore_changes = bool
    })
    redirect_to = object({
      host     = string
      path     = string
      port     = number
      protocol = string
    })
  }))
  description = "Map of listeners with the key as the public port of the listener"
}

// Optional
variable "idle_timeout" {
  type        = number
  description = "The time in seconds that the connection is allowed to be idle. Defaults to 60."
  default     = 60
}
variable "tags" {
  type        = map(string)
  description = "Tags to attach to the ALB and target groups. Defaults to {}"
  default     = {}
}