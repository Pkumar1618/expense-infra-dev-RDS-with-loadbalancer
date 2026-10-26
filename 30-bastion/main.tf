module "bastion" {
  source = "terraform-aws-modules/ec2-instance/aws"

  ami  = data.aws_ami.prashanth.id
  name = local.resource_name

  instance_type = "t3.micro"
  # key_name = "user1"
  # monitoring = true

  create_security_group = false

  vpc_security_group_ids = [local.bastion_sg_id]
  subnet_id              = local.public_subnet_id

  security_group_egress_rules = {
    ipv4_default = {
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all IPv4 traffic"
      ip_protocol = "-1"
    }
  }

  tags = merge(
    var.common_tags,
    var.bastion_tags,
    {
      Name = local.resource_name
    }
  )
}
