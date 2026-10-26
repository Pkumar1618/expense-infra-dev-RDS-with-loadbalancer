module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = local.resource_name

  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  db_name  = "transactions"
  username = "root"

  manage_master_user_password = false

  password_wo         = var.db_password
  password_wo_version = 1

  port = 3306

  vpc_security_group_ids = [
    local.mysql_sg_id
  ]

  db_subnet_group_name = local.database_subnet_group_name

  skip_final_snapshot = true

  tags = merge(
    var.common_tags,
    var.rds_tags
  )

  family               = "mysql8.0"
  major_engine_version = "8.0"

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]
}

data "aws_route53_zone" "main" {
  name         = var.zone_name
  private_zone = false
}

resource "aws_route53_record" "mysql" {
  zone_id = data.aws_route53_zone.main.zone_id

  name = "mysql-${var.environment}.${var.zone_name}"

  type = "CNAME"
  ttl  = 1

  records = [
    module.db.db_instance_address
  ]

  allow_overwrite = true
}


# module "db" {
#     source = "terraform-aws-modules/rds/aws"

#     identifier = local.resource_name # expense-dev

#     engine = "mysql"
#     engine_version = "8.0" 
#     instance_class = "db.t3.micro"
#     allocated_storage = 5

#     db_name = "transaction"
#     username = "root"
#     manage_master_user_password = false
#     password = "ExpenseApp1"
#     port = 3306

#     # iam_database_authentication_enabled = true

#     vpc_security_group_ids = [local.mysql_sg_id]
#     skip_final_snapshot = true

#     # maintenance_window = "Mon:00:00-Mon:03:00"
#     # backup_window = "03:00-06:00"

#     # Enhanced Monitoring - see example for deatils on how to create the role 
#     # by yourself, in case you don't want to create to automatically

#     # monitoring_interval = "30"
#     # monitoring_role_name = "MyRDSMonitoringRole"

#     tags = merge(
#         var.common_tags,
#         var.rds_tags,

#     )

#     # DB Subnet group
#     db_subnet_group_name = local.database_subnet_group_name

#     # DB parameter group
#     family = "mysql8.0"

#     # DB option group
#     major_engine_version = "8.0"

#     # Database Deletion Protection 
#     # deletion_protection = true

#     parameters = [
#         {
#             name = "character_set_client"
#             value = "utf8mb4"
#         },
#         {
#             name = "character_set_server"
#             value = "utf8mb4"
#         }

#     ]

#     options = [
#         {
#             option_name = "MARIADB_AUDIT_PLUGIN"

#             option_settings = [
#                 {
#                     name = "SERVER_AUDIT_EVENTS"
#                     value = "CONNECT"
#                 },
#                 {
#                     name = "SERVER_AUDIT_FILE_ROTATIONS"
#                     value = "37"
#                 },
#             ]
#         },
#     ]

# }