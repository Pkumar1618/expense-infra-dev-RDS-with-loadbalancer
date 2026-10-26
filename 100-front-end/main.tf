
module "frontend" {
  source = "terraform-aws-modules/ec2-instance/aws"

  ami                         = data.aws_ami.prashanth.id
  name                        = local.resource_name
  instance_type               = "t3.micro"
  subnet_id                   = local.public_subnet_ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [local.frontend_sg_id]
  key_name                    = var.frontend_key_name

  tags = merge(
    var.common_tags,
    var.frontend_tags,
    {
      Name = local.resource_name
    }
  )
}

# Configure the temporary frontend EC2 instance.
resource "null_resource" "frontend" {
  triggers = {
    instance_id = module.frontend.id
  }

  connection {
    type        = "ssh"
    host        = module.frontend.public_ip
    user        = "ec2-user"
    private_key = file(pathexpand(var.frontend_private_key_path))
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${var.frontend_tags.Component}.sh"
    destination = "/tmp/frontend.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/frontend.sh",
      "sudo sh /tmp/frontend.sh ${var.frontend_tags.Component} ${var.environment}"
    ]
  }
}

# Stop the temporary instance after configuration.
resource "aws_ec2_instance_state" "frontend" {
  instance_id = module.frontend.id
  state       = "stopped"

  depends_on = [null_resource.frontend]
}

# Create an AMI from the configured instance.
resource "aws_ami_from_instance" "frontend" {
  name               = local.resource_name
  source_instance_id = module.frontend.id

  depends_on = [aws_ec2_instance_state.frontend]
}

# Target group for frontend instances.
resource "aws_lb_target_group" "frontend" {
  name        = local.resource_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    matcher             = "200-299"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
  }

  tags = merge(
    var.common_tags,
    var.frontend_tags
  )
}

# Launch template for frontend Auto Scaling instances.
resource "aws_launch_template" "frontend" {
  name          = local.resource_name
  image_id      = aws_ami_from_instance.frontend.id
  instance_type = "t3.micro"

  instance_initiated_shutdown_behavior = "terminate"
  update_default_version               = true

  vpc_security_group_ids = [local.frontend_sg_id]
  key_name               = var.frontend_key_name

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.common_tags,
      var.frontend_tags,
      {
        Name = local.resource_name
      }
    )
  }
}

# Auto Scaling Group for frontend instances.
resource "aws_autoscaling_group" "frontend" {
  name                      = local.resource_name
  min_size                  = 2
  max_size                  = 10
  desired_capacity          = 2
  health_check_type         = "ELB"
  health_check_grace_period = 180

  target_group_arns = [
    aws_lb_target_group.frontend.arn
  ]

  vpc_zone_identifier = local.public_subnet_ids

  launch_template {
    id      = aws_launch_template.frontend.id
    version = aws_launch_template.frontend.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = local.resource_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

# Scale based on average CPU utilization.
resource "aws_autoscaling_policy" "frontend" {
  name                   = "${local.resource_name}-cpu-target"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.frontend.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

# Route requests to the frontend target group by hostname.
resource "aws_lb_listener_rule" "frontend" {
  listener_arn = local.web_alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = [
        "expense-${var.environment}.${var.zone_name}"
      ]
    }
  }

  tags = merge(
    var.common_tags,
    var.frontend_tags
  )
}




