
module "backend" {
  source = "terraform-aws-modules/ec2-instance/aws"

  ami                    = data.aws_ami.prashanth.id
  name                   = local.resource_name
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.backend_sg_id]
  subnet_id              = local.private_subnet_id

  # Configure these using your own EC2 key pair.
  key_name = var.backend_key_name

  tags = merge(
    var.common_tags,
    var.backend_tags,
    {
      Name = local.resource_name
    }
  )
}

# Configure the temporary instance.
resource "null_resource" "backend" {
  triggers = {
    instance_id = module.backend.id
  }

  connection {
    type        = "ssh"
    host        = module.backend.private_ip
    user        = "ec2-user"
    private_key = file(pathexpand(var.backend_private_key_path))
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${var.backend_tags.Component}.sh"
    destination = "/tmp/backend.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/backend.sh",
      "sudo sh /tmp/backend.sh ${var.backend_tags.Component} ${var.environment}"
    ]
  }
}

# Stop the temporary instance after configuration.
resource "aws_ec2_instance_state" "backend" {
  instance_id = module.backend.id
  state       = "stopped"

  depends_on = [null_resource.backend]
}

# Create an AMI from the configured, stopped instance.
resource "aws_ami_from_instance" "backend" {
  name               = local.resource_name
  source_instance_id = module.backend.id

  depends_on = [aws_ec2_instance_state.backend]
}

# Target group for backend application instances.
resource "aws_lb_target_group" "backend" {
  name     = local.resource_name
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    matcher             = "200-299"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
  }

  tags = merge(var.common_tags, var.backend_tags)
}

# Launch template uses the newly created AMI.
resource "aws_launch_template" "backend" {
  name          = local.resource_name
  image_id      = aws_ami_from_instance.backend.id
  instance_type = "t3.micro"

  instance_initiated_shutdown_behavior = "terminate"
  update_default_version               = true

  vpc_security_group_ids = [local.backend_sg_id]

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.common_tags,
      var.backend_tags,
      {
        Name = local.resource_name
      }
    )
  }
}

# Auto Scaling Group deploys backend instances in private subnets.
resource "aws_autoscaling_group" "backend" {
  name                      = local.resource_name
  min_size                  = 2
  max_size                  = 10
  desired_capacity          = 2
  health_check_type         = "ELB"
  health_check_grace_period = 180

  target_group_arns = [aws_lb_target_group.backend.arn]

  vpc_zone_identifier = local.private_subnet_ids

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }

    triggers = ["launch_template"]
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

  depends_on = [aws_lb_target_group.backend]
}

# Maintain average CPU utilization near 70%.
resource "aws_autoscaling_policy" "backend" {
  name                   = "${local.resource_name}-cpu-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.backend.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

# Forward requests for the backend hostname to the backend target group.
resource "aws_lb_listener_rule" "backend" {
  listener_arn = local.app_alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    host_header {
      values = [
        "${var.backend_tags.Component}.app-${var.environment}.${var.zone_name}"
      ]
    }
  }

  tags = merge(var.common_tags, var.backend_tags)
}
