# creating VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name = "VPC ${var.vpc_id}"
  }
}

data "aws_availability_zones" "all" {
  state = "available"
}

# Creating public subnet
resource "aws_subnet" "public_subnet" {
  count             = var.public_subnet
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.all.names, count.index % length(data.aws_availability_zones.all.names))

  tags = {
    Name = "Public subnet ${count.index + 1} - VPC ${var.vpc_id}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = var.private_subnet
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 4, count.index + 1)
  availability_zone = element(data.aws_availability_zones.all.names, count.index % length(data.aws_availability_zones.all.names))

  tags = {
    Name = "Private subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Internet gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "Public route table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Private route table"
  }
}

resource "aws_route_table_association" "aws_public_route_table_association" {
  count          = var.public_subnet
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "aws_private_route_table_association" {
  count          = var.private_subnet
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "application" {
  name        = "application"
  description = "Allow TLS inbound/outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
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
    Name = "allow_tls"
  }
}

data "aws_ami" "amzLinux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["csye6225*"]
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "webapp_ssh"
  public_key = var.rsa_public
}

resource "aws_instance" "webapp" {
  ami                         = data.aws_ami.amzLinux.id
  instance_type               = "t2.micro"
  disable_api_termination     = false
  associate_public_ip_address = true
  user_data                   = templatefile("user_data.sh", { db_host = aws_db_instance.csye6225.address, db_port = aws_db_instance.csye6225.port, db_user = aws_db_instance.csye6225.username, db_pwd = var.db_password, db = aws_db_instance.csye6225.db_name, db_engine = aws_db_instance.csye6225.engine, s3_bucket = aws_s3_bucket.s3.bucket, s3_region = aws_s3_bucket.s3.region, check = "testing" })

  key_name = aws_key_pair.ssh_key.key_name

  security_groups = [
    aws_security_group.application.id
  ]

  source_dest_check = true

  subnet_id = aws_subnet.public_subnet[0].id
  tags = {
    "Name" = "MyWebappServer"
  }

  tenancy = "default"

  vpc_security_group_ids = [
    aws_security_group.application.id
  ]

  lifecycle {
    prevent_destroy = false
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = 50
    volume_type           = "gp2"
  }
}

resource "aws_security_group" "database" {
  name = "database"

  description = "RDS Security Group for webapp"
  vpc_id      = aws_vpc.vpc.id

  # Only Postgres in
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

}

resource "aws_s3_bucket" "s3" {
  bucket        = "webapp-s3-bucket-${var.profile}-${random_uuid.uuid.result}"
  force_destroy = true
  tags = {
    Name        = "bucket ${var.profile}"
    Environment = "${var.profile}"
  }
}

resource "random_uuid" "uuid" {}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket = aws_s3_bucket.s3.id
  acl    = "private"
}

# lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_config" {

  bucket = aws_s3_bucket.s3.id

  rule {
    id     = "config"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_db_parameter_group" "aws_db_pg" {
  name   = "my-pg"
  family = "postgres14"

}

resource "aws_db_instance" "csye6225" {
  allocated_storage      = 10
  db_name                = var.db_name
  engine                 = var.db_engine
  engine_version         = var.db_version
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.aws_db_pg.name
  skip_final_snapshot    = true
  multi_az               = false
  apply_immediately      = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.pgsubnetgrp.name
  vpc_security_group_ids = [aws_security_group.database.id]
}


resource "aws_db_subnet_group" "pgsubnetgrp" {
  name       = "subnet-pg"
  subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]
}