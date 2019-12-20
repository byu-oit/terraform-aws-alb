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
variable "default_target_group_config" {
  type = object({
    type = string // instance
    deregistration_delay = number // 300
    slow_start = number // 0
    stickiness_cookie_duration = number // null
    health_check = object({
      path                = string
      interval            = number
      timeout             = number
      healthy_threshold   = number
      unhealthy_threshold = number
    })
  })
  description = "Default configuration for `target_groups`"
}
variable "target_groups" {
  type = list(object({
    name_suffix = string
    listener_ports = list(number)
    port = number
    config = object({
      type = string
      deregistration_delay = number // 300
      slow_start = number // 0
      health_check = object({
        path                = string
        interval            = number
        timeout             = number
        healthy_threshold   = number
        unhealthy_threshold = number
      })
      stickiness_cookie_duration = number
    })
  }))
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