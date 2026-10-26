# resource "aws_key_pair" "openvpn" {
#   key_name   = "openvpn"
#   public_key = file("${path.module}/openvpn.pub")
# }

resource "aws_key_pair" "openvpn" {
  key_name   = "openvpn"
  public_key = file("${path.module}/openvpn.pub")
}

module "vpn" {
  source   = "terraform-aws-modules/ec2-instance/aws"
  key_name = aws_key_pair.openvpn.key_name

  create_security_group = false

  ami           = data.aws_ami.joindevops.id
  name          = local.resource_name
  instance_type = "t3.micro"

  vpc_security_group_ids = [local.vpn_sg_id]
  subnet_id              = local.public_subnet_id

  tags = merge(
    var.common_tags,
    var.vpn_tags,
    {
      Name = local.resource_name
    }
  )
}


# module "vpn" {
#   source   = "terraform-aws-modules/ec2-instance/aws"
#   key_name = aws_key_pair.openvpn.key_name

#   ami  = data.aws_ami.prashanth.id
#   name = local.resource_name

#   instance_type = "t3.micro"

#   vpc_security_group_ids = [local.vpn_sg_id]
#   subnet_id              = local.public_subnet_id

#   source_dest_check = false

#   security_group_egress_rules = {
#     ipv4_default = {
#       cidr_ipv4   = "0.0.0.0/0"
#       description = "Allow all IPv4 traffic"
#       ip_protocol = "-1"
#     }
#   }

#   tags = merge(
#     var.common_tags,
#     var.vpn_tags,
#     {
#       Name = local.resource_name
#     }
#   )
# }
