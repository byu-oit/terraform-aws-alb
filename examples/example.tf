provider "aws" {
  region = "us-west-2"
}

module "acs" {
  source = "git@github.com:byu-oit/terraform-aws-acs-info.git?ref=v1.0.2"
  env    = "dev"
}

module "simple_alb" {
  source = "git@github.com:byu-oit/terraform-aws-alb.git?ref=v1.0.1"
  //  source = "../"
  name = "example"
  port_mappings = [
    {
      public_port = 80
      target_port = 8000
    },
    {
      public_port = 443
      target_port = 8000
    },
    {
      public_port = 40
      target_port = 40
    }
  ]
  vpc_id     = module.acs.vpc.id
  subnet_ids = module.acs.public_subnet_ids

  health_checks = [
    {
      port                = 8000
      path                = "/"
      interval            = null
      timeout             = null
      healthy_threshold   = null
      unhealthy_threshold = null
    },
    {
      port                = 40
      path                = "/health"
      interval            = null
      timeout             = null
      healthy_threshold   = null
      unhealthy_threshold = 3
    }
  ]
}
