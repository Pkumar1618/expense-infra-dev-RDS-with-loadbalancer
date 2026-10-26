variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "zone_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "backend_tags" {
  type = map(string)
}

variable "backend_key_name" {
  description = "Name of an existing EC2 key pair for backend bootstrap"
  type        = string
}

variable "backend_private_key_path" {
  description = "Local path to the matching private key file"
  type        = string
}

# variable "project_name" {
#   default = "expense"
# }

# variable "environment" {
#   default = "dev"
# }

# variable "common_tags" {
#   default = {
#     Project     = "expense"
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }

# variable "backend_tags" {
#   default = {
#     Component = "backend"
#   }
# }

# variable "zone_name" {
#   default = "daws81.online"
# }
