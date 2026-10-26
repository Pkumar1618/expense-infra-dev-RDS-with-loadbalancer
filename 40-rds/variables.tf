variable "project_name" {
  default = "expense"
}

variable "environment" {
  default = "dev"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  default = {
    Project     = "expense"
    Terraform   = "true"
    Environment = "dev"
  }
}

variable "rds_tags" {
  default = {
    Component = "mysql"
  }
}

variable "zone_name" {
  default = "daws81.online"
}