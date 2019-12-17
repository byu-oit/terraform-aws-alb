# aws-terraform-alb
Terraform module to create Application Load Balancer, Target Group(s) and Listener(s)

## Usage
```hcl
module "simple_alb" {
  source = "git@github.com:byu-oit/terraform-aws-alb.git?ref=v1.0.1"
  name = "example"
  port_mappings = [
    {
      public_port = 80
      target_port = 8000
    },
    {
      public_port = 443
      target_port = 8000
    }
  ]
  vpc_id = module.acs.vpc.id
  subnet_ids = module.acs.public_subnet_ids

  health_checks = [
    {
      port = 8000
      path = "/"
      interval = null
      timeout = null
      healthy_threshold = null
      unhealthy_threshold = null
    }
  ]
}
```

## Inputs

| Name | Description | Default |
| --- | --- | --- |
| name | Application Load Balancer name | |
| port_mappings | List of port mappings you want the ALB to map. See [below](#port_mappings)| |
| vpc_id | ID of the VPC | |
| subnet_ids | List of subnet IDs for the targets of the ALB | |
| health_checks | List of health check configurations. You need one health check config per target port. Se [below](#health_checks)| |
| deregistration_delay | ALB deregistration delay in seconds | 60 |
| idel_timeout | The time in seconds that the connection is allowed to be idle | 60 |
| tags | Tags to attach to the ALB and target groups | {} |

#### port_mappings
Needs to be a list of objects defined as:
```hcl
[{
  public_port: number
  target_port: number
}]
```
The `public_port` is the exposed port that the load balancer or the internet sees. The `target_port` is where load balancer sends the traffic to.

Under the hood this module creates target groups for every `target_port` defined here and listeners for every mapping defined here.

#### health_checks
Needs to be a list of objects defined as:
```hcl
[{
  path = string
  port = number
  interval = number
  timeout = number
  healthy_threshold = number
  unhealthy_threshold = number
}]
```
You need to define one (and only one) health check for each `target_port` defined in your `port_mappings` list because AWS target groups need to have a health check defined and cannot be disabled (except for lambda load balancer target groups).

**Defaults**
```hcl
path = "/"
port = <target_port>
interval = 30
timeout = 5
healthy_threshold = 3
unhealthy_threshold = 2
```

In order to use built in defaults you need to set the attribute to `null` (since terraform doesn't support optional attributes in objects yet). Example in the [usage section](#usage) above.

## Outputs
| Name | Description |
| --- | --- |
| alb | The Application Load Balancer (ALB) [object](https://www.terraform.io/docs/providers/aws/r/lb.html#attributes-reference) |
| target_groups | List of Target Group [objects](https://www.terraform.io/docs/providers/aws/r/lb_target_group.html#attributes-reference) |
| listeners | List of load balancer Listener [objects](https://www.terraform.io/docs/providers/aws/r/lb_listener.html#attributes-reference) |
| alb_security_group | The ALB's security group [object](https://www.terraform.io/docs/providers/aws/r/security_group.html#attributes-reference) |