provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
    Name        = ""
    Application = "ayan"
    Environment = "production"
    Tier        = ""
    Criticality = "high"
    Requestor   = ""
    Support     = "deepak@regelcloud.com"
    Client      = ""
    CostCenter  = "ayan"
  }
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = "prod-vpc"
  }
}
#main vpc
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "prog-igw"
  }
}
#public subnet
resource "aws_subnet" "public" {
  count = "${length(var.subnet_cidrs_public)}"
  vpc_id = aws_vpc.main.id
  cidr_block = "${var.subnet_cidrs_public[count.index]}"
  #availability_zone = "${var.availability_zones[count.index]}"
  tags = {
    Name = "prod-public-subnet-[count.index]"
  }
}
#private subnet app
resource "aws_subnet" "private_app" {
  count = "${length(var.subnet_cidrs_private_app)}"
  vpc_id = aws_vpc.main.id
  cidr_block = "${var.subnet_cidrs_private_app[count.index]}"
  #availability_zone = "${var.availability_zones[count.index]}"
  
  tags = {
    Name = "prod-private-app-subnet-${[count.index]}"
  }
}

#private subnet for db

resource "aws_subnet" "private_db" {
  count = "${length(var.subnet_cidrs_private_db)}"
  vpc_id = aws_vpc.main.id
  cidr_block = "${var.subnet_cidrs_private_db[count.index]}"
  #availability_zone = "${var.availability_zones[count.index]}"
  tags = {
    Name = "prod-private-db-subnet-${[count.index]}"
  }
}
#route table for public subnet

resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IGW.id
    }
  tags = {
    Name = "prod-public-route-table"
  }
}

#elastic ip
resource "aws_eip" "nateIP" {
  vpc = true

  tags = {
    Name = "prod-eip"
  }
}

#Nat Gateway

resource "aws_nat_gateway" "NATgw" {
  allocation_id = aws_eip.nateIP.id
  count = "${length(var.subnet_cidrs_public)}"
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "prod-nat-gateway"
  }
}
#route table for private app subnet

resource "aws_route_table" "privateRT-app" {
  vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        
        nat_gateway_id = aws_nat_gateway.NATgw[count.index]
    }
    tags = {
      Name = "prod-private-app-route-table"
    }
}

#route table for private db subnet

resource "aws_route_table" "privateRT-db" {
  vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        
        nat_gateway_id = aws_nat_gateway.NATgw.id
    }
    tags = {
      Name = "prod-private-db-route-table"
    }
}
#route table association for public subnet

resource "aws_route_table_association" "publicRTassociation" {
  count = "${length(var.subnet_cidrs_public)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = aws_route_table.publicRT.id

  #tags = {
     # Name = "prod-private-db-route-table"
 # }
}

#route table association for private app subnet

resource "aws_route_table_association" "privateRTassociation-app" {
  count = "${length(var.subnet_cidrs_private_app)}"
  subnet_id = "${element(aws_subnet.private_app.*.id, count.index)}"
  route_table_id = aws_route_table.privateRT-app.id

  #tags = {
  #  Name = "prod-private-app-subnet-association"
  #}
}

#route table association for private db subnet

resource "aws_route_table_association" "privateRTassociation-db" {
  count = "${length(var.subnet_cidrs_private_db)}"
  subnet_id = "${element(aws_subnet.private_db.*.id, count.index)}"
  route_table_id = aws_route_table.privateRT-db.id

  #tags = {
   # Name = "prod-private-db-subnet-association"
  #}
}