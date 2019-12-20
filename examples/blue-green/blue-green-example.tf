provider "aws" {
  region = "us-west-2"
}

module "acs" {
  source = "git@github.com:byu-oit/terraform-aws-acs-info.git?ref=v1.0.4"
  env    = "dev"
}

module "simple_alb" {
    source = "git@github.com:byu-oit/terraform-aws-alb.git?ref=v1.1.0"
//  source = "../../"
  name   = "blue-green-example"
  vpc_id     = module.acs.vpc.id
  subnet_ids = module.acs.public_subnet_ids
  is_blue_green = true

  default_target_group_config = {
    type                 = "ip"
    deregistration_delay = 60 // deregister
    slow_start           = 15
    health_check = {
      path                = "/"
      interval            = null
      timeout             = null
      healthy_threshold   = null
      unhealthy_threshold = null
    }
    stickiness_cookie_duration = 86400
  }
  target_groups = [
    {
      listener_ports = [
        80,
        443,
        8001 // test listener
      ]
      name_suffix = "blue"
      port        = 8000
      config      = null // use default
    },
    {
      listener_ports = []
      name_suffix    = "green"
      port           = 8000
      config = {
        type = "ip"
        deregistration_delay = null
        slow_start           = null
        health_check = {
          path                = "/green"
          interval            = null
          timeout             = null
          healthy_threshold   = 4
          unhealthy_threshold = 2
        }
        stickiness_cookie_duration = null
      }
    }
  ]
}
