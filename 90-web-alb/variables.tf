variable "project_name" {
  default = "expense"
}

variable "environment" {
  default = "dev"
}

variable "common_tags" {
  default = {
    Project     = "expense"
    Terraform   = "true"
    Environment = "dev"
  }
}

variable "web_alb_sg_tags" {
  type    = map(string)
  default = {}
}

variable "zone_name" {
  default = "daws81.online"
}