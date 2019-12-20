provider "aws" {
  region = "us-west-2"
}

module "acs" {
  source = "git@github.com:byu-oit/terraform-aws-acs-info.git?ref=v1.0.4"
  env    = "dev"
}

module "simple_alb" {
    source = "git@github.com:byu-oit/terraform-aws-alb.git?ref=v1.1.0"
//  source = "../../" // used for local testing
  name   = "simple-example"
  vpc_id     = module.acs.vpc.id
  subnet_ids = module.acs.public_subnet_ids

  default_target_group_config = {
    type                 = "ip" // or instance or lambda
    deregistration_delay = null
    slow_start           = null
    health_check = {
      path                = "/"
      interval            = null
      timeout             = null
      healthy_threshold   = null
      unhealthy_threshold = null
    }
    stickiness_cookie_duration = null
  }
  target_groups = [
    {
      listener_ports = [
        80,
        443
      ]
      name_suffix = "main"
      port        = 8000
      config      = null // use default
    }
  ]
}