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

variable "frontend_tags" {
  default = {
    Component = "frontend"
  }
}

variable "zone_name" {
  default = "daws81.online"
}

variable "frontend_key_name" {
  description = "Existing AWS EC2 key pair for frontend bootstrap"
  type        = string
}

variable "frontend_private_key_path" {
  description = "Local path to the matching private key"
  type        = string
}
