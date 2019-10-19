variable "subnet" {
  type        = "string"
  description = "Subnet Can Be Entered Using terraform apply -var=subnet=x.x.x.x/x"
}

data "aws_vpc" "selected" {
  tags = {
    Name = "AdsDev"
  }
}

output "vpc" {
  value = "${data.aws_vpc.selected.tags}"
}

data "aws_ec2_transit_gateway_vpc_attachment" "corp_tga" {
  filter {
    name   = "vpc-id"
    values = ["${data.aws_vpc.selected.id}"]
  }
}

output "tga" {
  value = "${data.aws_ec2_transit_gateway_vpc_attachment.corp_tga.id}"
}

data "aws_ec2_transit_gateway" "corp_tg" {
  filter {
    name   = "owner-id"
    values = ["120371505781"]
  }
}

output "tg" {
  value = "${data.aws_ec2_transit_gateway.corp_tg.id}"
}

data aws_route_table "rtable" {
  tags {
    Name = "Ads_Private"
  }
}

output "route_table" {
  value = "${data.aws_route_table.rtable.id}"
}

resource "aws_route" "route" {
  route_table_id         = "${data.aws_route_table.rtable.id}"
  destination_cidr_block = "${var.subnet}"
  transit_gateway_id     = "${data.aws_ec2_transit_gateway.corp_tg.id}"
}
