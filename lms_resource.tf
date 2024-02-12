#VPC Data Center

resource "aws_vpc" "lms-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "lms-vpc"
  }
}

#Subnet

resource "aws_subnet" "lms-fe-subnet" {
  vpc_id     = aws_vpc.lms-vpc.id
  cidr_block = "10.0.0.0/20"
availability_zone = "ap-southeast-2b"
map_public_ip_on_launch = "true"
  tags = {
    Name = "lms-fe-subnet"
  }
}
resource "aws_subnet" "lms-be-subnet" {
  vpc_id     = aws_vpc.lms-vpc.id
  cidr_block = "10.0.16.0/20"
availability_zone = "ap-southeast-2c"
map_public_ip_on_launch = "true"
  tags = {
    Name = "lms-be-subnet"
  }
}
resource "aws_subnet" "lms-db-subnet" {
  vpc_id     = aws_vpc.lms-vpc.id
  cidr_block = "10.0.32.0/20"
availability_zone = "ap-southeast-2a"
map_public_ip_on_launch = "false"
  tags = {
    Name = "lms-db-subnet"
  }
}

#Internet Gateway

resource "aws_internet_gateway" "lms-igw" {
  vpc_id = aws_vpc.lms-vpc.id

  tags = {
    Name = "lms-gateway"
  }
}

#Route Table

resource "aws_route_table" "lms-rtb" {
  vpc_id = aws_vpc.lms-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lms-igw.id
  }

tags = {
    Name = "lms-route-table"
  }
}

resource "aws_route_table" "lms-rtb-db" {
  vpc_id = aws_vpc.lms-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lms-nat-gateway.id
  }

tags = {
    Name = "lms-route-table-db"
  }
}


# Route Table - Subnet Association

resource "aws_route_table_association" "lms-rt-sn" {
  subnet_id      = aws_subnet.lms-fe-subnet.id
  route_table_id = aws_route_table.lms-rtb.id
}

resource "aws_route_table_association" "lms-rt1-sn" {
  subnet_id      = aws_subnet.lms-be-subnet.id
  route_table_id = aws_route_table.lms-rtb.id
}

resource "aws_route_table_association" "lms-rt2-sn" {
  subnet_id      = aws_subnet.lms-db-subnet.id
  route_table_id = aws_route_table.lms-rtb-db.id
}

# AWS EIP
resource "aws_eip" "nat1" {
  instance = null
}


# NAT Gateway

resource "aws_nat_gateway" "lms-nat-gateway" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.lms-be-subnet.id

 tags = {
   Name = "lms ng"
  }
#  depends_on = [aws_internet_gateway.lms-igw]
}

# Security Group

resource "aws_security_group" "lms-fe-sg" {
  name        = "lms-fe-sg"
  description = "Allow SSH - HTTP inbound traffic"
  vpc_id      = aws_vpc.lms-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lms-fe-sg"
  }
}

resource "aws_security_group" "lms-be-sg" {
  name        = "lms-be-sg"
  description = "Allow SSH - HTTP inbound traffic"
  vpc_id      = aws_vpc.lms-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lms-be-sg"
  }
}

resource "aws_security_group" "lms-db-sg" {
  name        = "lms-db-sg"
  description = "Allow SSH - HTTP inbound traffic"
  vpc_id      = aws_vpc.lms-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   
  ingress {
    description = "postgresql"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
   ingress {
    description = "HTTPS"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lms-db-sg"
  }
}

#NACL
resource "aws_network_acl" "lms-nacl" {
  vpc_id = aws_vpc.lms-vpc.id

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "0"
    to_port    = "0"
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "0"
    to_port    = "0"
  }

  tags = {
    Name = "lms-nacl"
  }
}

#NACL Subnet Associtaion

resource "aws_network_acl_association" "nacl" {
  network_acl_id = aws_network_acl.lms-nacl.id
  subnet_id      = aws_subnet.lms-fe-subnet.id
}

resource "aws_network_acl_association" "nacl1" {
  network_acl_id = aws_network_acl.lms-nacl.id
  subnet_id      = aws_subnet.lms-be-subnet.id
}

resource "aws_network_acl_association" "nacl2" {
  network_acl_id = aws_network_acl.lms-nacl.id
  subnet_id      = aws_subnet.lms-db-subnet.id
}


# AWS Instance
resource "aws_instance" "lms-fe-ec2" {
  ami           = "ami-0f2967bce46537146"
  instance_type = "t2.micro"
  key_name = "sydney"
  subnet_id = aws_subnet.lms-fe-subnet.id
  vpc_security_group_ids = [aws_security_group.lms-fe-sg.id]

  tags = {
    Name = "lms-fe-server"
  }
}

resource "aws_instance" "lms-be-ec2" {
  ami           = "ami-0f2967bce46537146"
  instance_type = "t2.micro"
  key_name = "sydney"
  subnet_id = aws_subnet.lms-be-subnet.id
  vpc_security_group_ids = [aws_security_group.lms-be-sg.id]
  user_data = file("be.sh")

  tags = {
    Name = "lms-be-server"
  }
}

resource "aws_instance" "lms-db-ec2" {
  ami           = "ami-0f2967bce46537146"
  instance_type = "t2.micro"
  key_name = "sydney"
  subnet_id = aws_subnet.lms-db-subnet.id
  vpc_security_group_ids = [aws_security_group.lms-db-sg.id]
  user_data = file("db.sh") 
  tags = {
    Name = "lms-db-server"
  }
}

