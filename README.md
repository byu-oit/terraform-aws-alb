![Latest GitHub Release](https://img.shields.io/github/v/release/byu-oit/terraform-aws-alb?sort=semver)

# AWS Terraform ALB
Terraform module to create Application Load Balancer, Target Group(s) and Listener(s)

## Usage
```hcl
module "simple_alb" {
  source = "git@github.com:byu-oit/terraform-aws-alb.git?ref=v1.1.0"
  name       = "example"
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
```

## Requirements
* Terraform version 0.12.16 or greater

## Inputs

| Name | Description | Default |
| --- | --- | --- |
| name | Application Load Balancer name | |
| vpc_id | ID of the VPC | |
| subnet_ids | List of subnet IDs for the targets of the ALB | |
| target_groups | Map of information defining the target groups to create. See [below](#target_groups) | |
| listeners | Map of information defining the listeners to create. See [below](#listeners) | |
| idle_timeout | The time in seconds that the connection is allowed to be idle | 60 |
| tags | Tags to attach to the ALB and target groups | {} |

**Note:** In order to use built in defaults you need to set the attribute to `null` (since terraform doesn't support optional attributes in objects yet). Example in the [usage section](#usage) above.

#### target_groups
A map of objects that define the target groups to create. The map's key is the name (actually the name suffix that will 
be constructed with the name of the alb) of the target group you want to create.

The target group's name will be `<alb.name>-tg-<map_key>`. This will also be how the outputs are mapped.

For instance, the following will create two target groups named `example-tg-blue` and `example-tg-green`: 
```hcl
name       = "example"
vpc_id     = module.acs.vpc.id
subnet_ids = module.acs.public_subnet_ids
target_groups = {
  "blue" = {
  //...
  },
  "green" = {
  //...  
  } 
}
```

* `port` - (Required) The port of the target group.
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

#### listeners
A map of objects defining the listeners to create. The map's key is the listener or public port to create.

A listener can be configured to either forward traffic to a target group or to redirect traffic. Defining both will probably result in an error.

* `protocol` - (Optional) The protocol for connections from clients to the load balancer. Valid values are TCP, TLS, UDP, TCP_UDP, HTTP and HTTPS. Defaults to HTTP.
* `https_certificate_arn` - (Optional) The ARN of the default SSL server certificate. Exactly one certificate is required if the protocol is HTTPS.
* `forward_to` - (Optional) If this listener should forward traffic, define this object:
    * `target_group` - (Required) The target group name suffix (or mapped key in the `target_groups` variables) to forward traffic to.
    * `ignore_changes` - (Required) Boolean to tell terraform to ignore changes to this target group definition. This is useful when something else (like CodeDeploy) changes the listener's forwarded target group.
* `redirect_to` - (Optional) If this listener should redirect traffic, define this object:
    * `host` - (Optional) The hostname to direct traffic. This component is not percent-encoded. The hostname can contain #{host}. Defaults to #{host}.
    * `path` - (Optional) The absolute path, starting with the leading "/". This component is not percent-encoded. The path can contain #{host}, #{path}, and #{port}. Defaults to /#{path}.
    * `port` - (Optional) The port. Specify a value from 1 to 65535 or #{port}. Defaults to #{port}.
    * `protocol` - (Optional) The protocol. Valid values are HTTP, HTTPS, or #{protocol}. Defaults to #{protocol}.

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
  "443" = {
    "arn" = "..."
    "default_action" = {
      "target_group_arn" = "arn...example-tg-blue..."
      // ...
    }
    // ...
  }
}
``` 