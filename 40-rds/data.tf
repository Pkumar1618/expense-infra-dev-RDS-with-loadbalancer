data "aws_ssm_parameter" "mysql_sg_id" {
  # /expense/dev/mysql_sg_id
  name = "/${var.project_name}/${var.environment}/mysql_sg_id"
}

data "aws_ssm_parameter" "database_subnet_group_name" {
  # /expense/dev/public_subnet_ids
  name = "/${var.project_name}/${var.environment}/database_subnet_group_name"
}

# whenever database subnet group will comes subnet ids not required.
# data "aws_ssm_parameter" "public_subnet_id" {
#   # /expense/dev/public_subnet_ids
#   name = "/${var.project_name}/${var.environment}/public_subnet_id"
# }

# In database we dont use the AMI 

# data "aws_ami" "prashanth" {
#   most_recent = true
#   owners      = ["973714476881"]

#   filter {
#     name   = "name"
#     values = ["Redhat-9-DevOps-Practice"]
#   }

#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }