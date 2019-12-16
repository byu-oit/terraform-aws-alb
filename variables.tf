// Required
variable "name" {
  type        = string
  description = "Application Load Balancer name to be used for naming resources."
}
variable "port_mappings" {
  type = list(object({
    public_port : number
    target_port : number
  }))
  description = "List of port mappings you want the ALB to map."
}
variable "vpc_id" {
  type        = string
  description = "ID of the VPC."
}
variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the targets of the ALB."
}
variable "health_checks" {
  type = list(object({
    path                = string
    port                = number
    interval            = number
    timeout             = number
    healthy_threshold   = number
    unhealthy_threshold = number
  }))
  description = "List of health check configurations. You need one health check config per target port."
}

// Optional
variable "deregistration_delay" {
  type        = number
  description = "ALB deregistration delay in seconds. Defaults to 60."
  default     = 60
}
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