data "aws_ssm_parameter" "frontend_sg_id" {
  # /expense/dev/_sg_id
  name = "/${var.project_name}/${var.environment}/backend_sg_id"
}

data "aws_ssm_parameter" "public_subnet_id" {
  # /expense/dev/public_subnet_ids
  name = "/${var.project_name}/${var.environment}/public_subnet_id"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project_name}/${var.environment}/vpc_id"
}

data "aws_ssm_parameter" "web_alb_listener_arn" {
  name = "/${var.project_name}/${var.environment}/web_alb_listener_arn"
}


data "aws_ami" "prashanth" {
  most_recent = true
  owners      = ["973714476881"]

  filter {
    name   = "name"
    values = ["Redhat-9-DevOps-Practice"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}