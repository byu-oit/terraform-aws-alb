provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

module "acs" {
  source = "git@github.com:byu-oit/terraform-aws-acs-info.git?ref=v1.0.4"
  env    = "dev"
}

module "simple_alb" {
  source = "git@github.com:byu-oit/terraform-aws-alb.git?ref=v1.2.0"
  //  source     = "../../"
  name       = "simple-example"
  vpc_id     = module.acs.vpc.id
  subnet_ids = module.acs.public_subnet_ids
  target_groups = {
    main = {
      port                 = 8000
      type                 = "ip"
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
  }
  listeners = {
    80 = {
      protocol              = "HTTP"
      https_certificate_arn = null
      redirect_to = {
        host     = null
        path     = null
        port     = 443
        protocol = "HTTPS"
      }
      forward_to = null
    },
    443 = {
      protocol              = "HTTPS"
      https_certificate_arn = module.acs.certificate.arn
      redirect_to           = null
      forward_to = {
        target_group   = "main"
        ignore_changes = false
      }
    }
  }
}