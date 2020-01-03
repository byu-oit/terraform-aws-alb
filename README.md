![Latest GitHub Release](https://img.shields.io/github/v/release/byu-oit/terraform-aws-alb?sort=semver)

# AWS Terraform ALB
Terraform module to create Application Load Balancer, Target Group(s) and Listener(s)

## Usage
```hcl
module "simple_alb" {
  source = "git@github.com:byu-oit/terraform-aws-alb.git?ref=v1.1.0"
  name = "example"
  vpc_id = module.acs.vpc.id
  subnet_ids = module.acs.public_subnet_ids
  default_target_group_config = {
    type = "ip"
        deregistration_delay = null
        slow_start = null
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
      name_suffix    = "blue"
      listener_ports = [80]
      port           = 8000
      config         = null
    },
    {
      name_suffix    = "green"
      listener_ports = []
      port           = 8000
      config         = null
    }
  ]
}
```

## Requirements
* Terraform version 0.12.16 or greater

## Inputs

| Name | Description | Default |
| --- | --- | --- |
| name | Application Load Balancer name | |
| vpc_id | ID of the VPC | |
| subnet_ids | List of subnet IDs for the targets of the ALB | |
| default_target_group_config | Default configuration for `target_groups`. See [below](#default_target_group_config) | |
| target_groups | List of information defining the target groups to create. See [below](#target_groups) | |
| is_blue_green | Boolean to identify that this ALB will be used for blue green deployments. `true` will cause the listeners to ignore changes to the forwarded target group because code deploy can change that | false | 
| idle_timeout | The time in seconds that the connection is allowed to be idle | 60 |
| tags | Tags to attach to the ALB and target groups | {} |

**Note:** In order to use built in defaults you need to set the attribute to `null` (since terraform doesn't support optional attributes in objects yet). Example in the [usage section](#usage) above.

#### default_target_group_config
In order to not have to define target group configuration for every target group you define, you can define some 
defaults with this object. You can override the defaults on specific target groups if needed.
* `type` - (Optional) The type of target that you must specify when registering targets with this target group [`instance`, `ip`, or `lambda`]. Defaults to `instance`.
* `deregistration_delay` - (Optional) The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. Defaults to 300 seconds.
* `slow_start` - (Optional) The amount time for targets to warm up before the load balancer sends them a full share of requests. Defaults to 0 seconds.
* `stickiness_cookie_duration` - (Optional) Is provided, this will enable sticky sessions on the target group with a sticky session duration in seconds. Defaults to `null`.
* `health_check` - (Required) Some configuration about the required health check for each defined target group.
    * `path` - (Required) The destination for the health check request.
    * `interval` - (Optional) The approximate amount of time, in seconds, between health checks of an individual target. Defaults to 30 seconds.
    * `timeout` - (Optional) The amount of time, in seconds, during which no response means a failed health check. Must be between 2 and 120 seconds, and the default is 5 seconds.
    * `healthy_threshold` - (Optional) The number of consecutive health checks successes required before considering an unhealthy target healthy. Defaults to 3.
    * `unhealthy_threshold` - (Optional) The number of consecutive health check failures required before considering the target unhealthy. Defaults to 3.

#### target_groups
A list of objects that define the target groups to create along with the listener ports that forward traffic to each target group.
* `name_suffix` - (Required) The suffix to append to the end of the target group name. The target group name will be `<alb.name>-tg-<target_group.name_suffix>`. This will also be how the outputs are mapped.
* `listener_ports` - (Required) A list of public port numbers that you want to be forwarded to this target group. This will create ingress rules to the ALB's security group to allow traffic from anywhere to these specified ports.  
* `port` - (Required) The port on which targets receive traffic.
* `config` - (Optional) If provided, override all values in the [`default_target_group_config`](#default_target_group_config). (Same attributes as the  [`default_target_group_config`](#default_target_group_config) object).

## Outputs
| Name | Description |
| --- | --- |
| alb | The Application Load Balancer (ALB) [object](https://www.terraform.io/docs/providers/aws/r/lb.html#attributes-reference) |
| target_groups | Map of Target Group [objects](https://www.terraform.io/docs/providers/aws/r/lb_target_group.html#attributes-reference) |
| listeners | Map of load balancer Listener [objects](https://www.terraform.io/docs/providers/aws/r/lb_listener.html#attributes-reference) |
| alb_security_group | The ALB's security group [object](https://www.terraform.io/docs/providers/aws/r/security_group.html#attributes-reference) |

**Note:** the `target_groups` output will be a map of target group objects mapped on the `name_suffix` you provided in 
the [`target_groups`](#target_groups) variable. And the `listeners` output will be a map of listener objects mapped on
the listener/public port.

For example: the example module [above](#usage) will output something like:
```hcl
target_groups = {
  "blue" = {
    "arn" = "..."
    "name" = "example-tg-blue"
    // ...
  }
  "green" = {
    "arn" = "..."
    "name" = "example-tg-green"
    // ...
  }
}

listeners = {
  "80" = {
    "arn" = "..."
    "default_action" = {
      "target_group_arn" = "arn...example-tg-blue..."
      // ...
    }
    // ...
  }
}
``` 