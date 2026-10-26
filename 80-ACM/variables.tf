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

variable "zone_name" {
  default = "daws81.online"
}

variable "zone_id" {
    default = "Z0571223ZB0IC5GJ0MT"
}