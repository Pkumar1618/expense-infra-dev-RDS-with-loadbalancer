module "web_alb" {
  source = "terraform-aws-modules/alb/aws"

  internal              = false
  name                  = "${local.resource_name}-web-alb"
  vpc_id                = local.vpc_id
  subnets               = local.public_subnet_ids
  security_groups       = [data.aws_ssm_parameter.web_alb_sg_id.value]
  create_security_group = false
  enable_delete_protection = false

  tags = merge(
    var.common_tags,
    var.web_alb_sg_tags
  )
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = module.web_alb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Hello, I am from Application ALB</h1>"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = module.web_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.https_certificate_arn
  alpn_policy       = "HTTP2Preferred"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Hello, I am from web ALB HTTPS</h1>"
      status_code  = "200"
    }
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "4.1.0"

  zone_name = var.zone_name

  records = [
    {
      name = "expense-${var.environment}"
      type = "A"

      alias = {
        name                   = module.web_alb.dns_name
        zone_id                = module.web_alb.zone_id
        evaluate_target_health = true
      }

      allow_overwrite = true
    }
  ]
}
#   # here Security Group I have created the separatly.
#   security_group_ingress_rules = {
#     all_http = {
#       from_port   = 80
#       to_port     = 80
#       ip_protocol = "tcp"
#       description = "HTTP web traffic"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#     all_https = {
#       from_port   = 443
#       to_port     = 443
#       ip_protocol = "tcp"
#       description = "HTTPS web traffic"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#   }
#   security_group_egress_rules = {
#     all = {
#       ip_protocol = "-1"
#       cidr_ipv4   = "10.0.0.0/16"
#     }
#   }

#   access_logs = {
#     bucket = "my-alb-logs"
#   }

#   listeners = {
#     ex-http-https-redirect = {
#       port     = 80
#       protocol = "HTTP"
#       redirect = {
#         port        = "443"
#         protocol    = "HTTPS"
#         status_code = "HTTP_301"
#       }
#     }
#     ex-https = {
#       port            = 443
#       protocol        = "HTTPS"
#       certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

#       forward = {
#         target_group_key = "ex-instance"
#       }
#     }
#   }

#   target_groups = {
#     ex-instance = {
#       name_prefix      = "h1"
#       protocol         = "HTTP"
#       port             = 80
#       target_type      = "instance"
#       target_id        = "i-0f6d38a07d50d080f"
#     }
#   }


