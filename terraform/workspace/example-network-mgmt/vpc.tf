resource "aws_vpc" "main" {
  cidr_block           = var.vpc_attributes.cidr_block
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  enable_classiclink   = "false"
  instance_tenancy     = "default" #you do not want dedicated as it is very $$$

  tags = {
    Name = var.vpc_attributes.tag_name
  }
}

# Stuck with some boilerplate code here due to Terraform limits
# Create Tier 1 of 3 - DMZ
resource "aws_subnet" "dmz_subnet" {
  # Create one subnet for each given availability zone.
  count = length(var.availability_zones)

  # For each subnet, use one of the specified availability zones.
  availability_zone = var.availability_zones[count.index]

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.cidrs.dmztier, 2, count.index + 1)

  tags = {
    Name = "${var.vpc_attributes.tag_name}-dmztier-${var.availability_zones[count.index]}"
    Tier = "dmz"
  }
}

# Create Tier 2 of 3 - APP
resource "aws_subnet" "apptier_subnet" {
  # Create one subnet for each given availability zone.
  count = length(var.availability_zones)

  # For each subnet, use one of the specified availability zones.
  availability_zone = var.availability_zones[count.index]

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.cidrs.apptier, 2, count.index + 1)

  tags = {
    Name = "${var.vpc_attributes.tag_name}-apptier-${var.availability_zones[count.index]}"
    Tier = "app"
  }
}

# Create Tier 3 of 3 - DATA
resource "aws_subnet" "datatier_subnet" {
  # Create one subnet for each given availability zone.
  count = length(var.availability_zones)

  # For each subnet, use one of the specified availability zones.
  availability_zone = var.availability_zones[count.index]

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.cidrs.datatier, 2, count.index + 1)

  tags = {
    Name = "${var.vpc_attributes.tag_name}-datatier-${var.availability_zones[count.index]}"
    Tier = "data"
  }
}

data "aws_subnet_ids" "dmztier" {
  vpc_id = aws_vpc.main.id

  tags = {
    Tier = "dmz"
  }
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = aws_vpc.main.id

  filter {
    name   = "tag:Tier"
    values = ["app", "data"]
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_attributes.tag_name}-igw"
  }
}

resource "aws_eip" "natgw_eip" {
  vpc        = true
  depends_on = ["aws_internet_gateway.igw"]
}

# Note: Picking the subnet for the NAT GW is a little funky. The Terraform Data
# Source returns a "set", not a "list". When we cast this to a list, the list is
# sorted by subnet id, which is just the subnet name and nothing to do with zone a, b, or c.
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.natgw_eip.id
  subnet_id     = tolist(data.aws_subnet_ids.dmztier.ids)[var.vpc_attributes.nat_gw_subnet]
  depends_on    = ["aws_internet_gateway.igw"]
}

resource "aws_route_table" "dmz" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id #Internet Gateway
  }

  tags = {
    Name = "dmz"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id #NAT Gateway
  }

  tags = {
    Name = "private"
  }
}

# The "Main" route table controls the routing for all subnets that are not
# explicitly associated with any other route table. We want these to be private
resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "dmz" {
  count          = length(data.aws_subnet_ids.dmztier.ids)
  route_table_id = aws_route_table.dmz.id
  subnet_id      = tolist(data.aws_subnet_ids.dmztier.ids)[count.index] # N.B. the to list is because of this: https://www.reddit.com/r/Terraform/comments/bwo2w1/how_are_we_now_supposed_to_iterate_over_a_list_to/
}

resource "aws_route_table_association" "private" {
  count          = length(data.aws_subnet_ids.private_subnets.ids)
  route_table_id = aws_route_table.private.id
  subnet_id      = tolist(data.aws_subnet_ids.private_subnets.ids)[count.index] # N.B. the to list is because of this: https://www.reddit.com/r/Terraform/comments/bwo2w1/how_are_we_now_supposed_to_iterate_over_a_list_to/
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-2.s3"
}

resource "aws_vpc_endpoint_route_table_association" "example" {
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No rules in a security group means that no remote IP Address can access your
  # instance on any protocol, and no outbound traffic from the instance is allowed
  # on any protocol either.
}
