provider "aws" {
  version = "~> 2.42"
  region  = "us-west-2"
}

module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info?ref=v1.2.1"
  env    = "dev"
}

module "blue_green_alb" {
  source = "github.com/byu-oit/terraform-aws-alb?ref=v1.2.1"
  //  source        = "../../"
  name       = "blue-green-example"
  vpc_id     = module.acs.vpc.id
  subnet_ids = module.acs.public_subnet_ids
  target_groups = {
    blue = {
      port                       = 8000
      type                       = "ip" // or instance or lambda
      deregistration_delay       = null
      slow_start                 = null
      stickiness_cookie_duration = null
      health_check = {
        path                = "/"
        interval            = null
        timeout             = null
        healthy_threshold   = null
        unhealthy_threshold = null
      }
    },
    green = {
      port                       = 8000
      type                       = "ip" // or instance or lambda
      deregistration_delay       = null
      slow_start                 = null
      stickiness_cookie_duration = null
      health_check = {
        path                = "/"
        interval            = null
        timeout             = null
        healthy_threshold   = null
        unhealthy_threshold = null
      }
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
        target_group   = "blue"
        ignore_changes = false
      }
    }
  }
}
