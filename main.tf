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
    # security_groups = [aws_security_group.load_balancer.id]
  }

  # ingress {
  #   description = "TLS from VPC"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # ingress {
  #   description = "TLS from VPC"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    description     = "TLS from VPC"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
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

resource "aws_iam_policy" "webapp_s3" {
  name        = "WebAppS3"
  description = "Allows EC2 instances to perform S3 bucket operations"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.s3.bucket}",
        "arn:aws:s3:::${aws_s3_bucket.s3.bucket}/*"
      ]
    }
  ]
}
POLICY
}


resource "aws_iam_role" "ec2_csye6225" {
  name = "EC2-CSYE6225"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "webapp_s3_policy_attachment" {
  policy_arn = aws_iam_policy.webapp_s3.arn
  role       = aws_iam_role.ec2_csye6225.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.ec2_csye6225.name
}

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "web_instance_profile"
  role = aws_iam_role.ec2_csye6225.name
}

resource "aws_security_group" "database" {
  name = "database"

  description = "RDS Security Group for webapp"
  vpc_id      = aws_vpc.vpc.id

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

resource "aws_s3_bucket_public_access_block" "s3_bucket_access" {
  bucket = aws_s3_bucket.s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {

  bucket = aws_s3_bucket.s3.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
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
  identifier        = "csye6225"
  engine            = var.db_engine
  engine_version    = var.db_version
  instance_class    = "db.t3.micro"
  allocated_storage = 10

  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = aws_db_parameter_group.aws_db_pg.name
  skip_final_snapshot  = true

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

data "aws_route53_zone" "hosted_zone" {
  name = "${var.profile}.${var.domain_name}"
}

resource "aws_route53_record" "hosted_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "${var.profile}.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.webapp_lb.dns_name
    zone_id                = aws_lb.webapp_lb.zone_id
    evaluate_target_health = true
  }
}
resource "aws_security_group" "load_balancer_sg" {

  name        = "load_balancer_sg"
  description = "Allow TLS inbound/outbound traffic"
  vpc_id      = aws_vpc.vpc.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "webapp_target" {
  name     = "webapptarget"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    path     = "/healthz"
    interval = 30
  }
}


resource "aws_lb" "webapp_lb" {
  name                       = "webapplb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.load_balancer_sg.id]
  subnets                    = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id, aws_subnet.public_subnet[2].id]
  enable_deletion_protection = false
}
#
resource "aws_lb_listener" "webapp_listner" {
  load_balancer_arn = aws_lb.webapp_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_target.arn
  }
}


resource "aws_launch_template" "webapp_template" {
  name          = "webapp_lauch_template"
  image_id      = data.aws_ami.amzLinux.id
  instance_type = "t2.micro"
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 8
      volume_type           = "gp2"
      delete_on_termination = true
    }

  }

  network_interfaces {
    associate_public_ip_address = true
    device_index                = 0
    security_groups             = [aws_security_group.application.id]
    subnet_id                   = aws_subnet.public_subnet[0].id
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.web_instance_profile.name
  }

  user_data = base64encode(templatefile("user_data.sh", {
    db_host   = aws_db_instance.csye6225.address,
    db_port   = aws_db_instance.csye6225.port,
    db_user   = aws_db_instance.csye6225.username,
    db_pwd    = var.db_password,
    db        = aws_db_instance.csye6225.db_name,
    db_engine = aws_db_instance.csye6225.engine,
    s3_bucket = aws_s3_bucket.s3.bucket,
  s3_region = aws_s3_bucket.s3.region }))

  lifecycle {
    prevent_destroy = false
  }

}
resource "aws_autoscaling_group" "webapp_autoScaling_grp" {
  name             = "webapp_autoScaling_grp"
  min_size         = 1
  max_size         = 3
  default_cooldown = 60
  launch_template {
    version = "$Latest"
    name = aws_launch_template.webapp_template.name
  }
  target_group_arns = [aws_lb_target_group.webapp_target.arn]
  vpc_zone_identifier = [aws_subnet.public_subnet[0].id]
}

resource "aws_autoscaling_attachment" "webapp_autoScaling_attachment" {
  autoscaling_group_name = aws_autoscaling_group.webapp_autoScaling_grp.name
  lb_target_group_arn    = aws_lb_target_group.webapp_target.arn
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 4
  alarm_description   = "This metric checks if CPU usage is higher than 4% for the past 2 minutes"
  alarm_actions       = [aws_autoscaling_policy.scale_up_policy.arn]
  actions_enabled     = true
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_autoScaling_grp.name
  }
}
resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  alarm_name          = "low-cpu-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 3
  alarm_description   = "This metric checks if CPU usage is lower than 3% for the past 2 minutes"
  alarm_actions       = [aws_autoscaling_policy.scale_down_policy.arn]
  actions_enabled     = true
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_autoScaling_grp.name
  }
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale-up-policy"
  policy_type            = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.webapp_autoScaling_grp.name
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
}
resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale_down_policy"
  policy_type            = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.webapp_autoScaling_grp.name
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
}

resource "aws_cloudwatch_log_group" "csye6225_log_group" {
  name = "csye6225"
}

resource "aws_cloudwatch_log_stream" "csye6225_log_stream" {
  log_group_name = aws_cloudwatch_log_group.csye6225_log_group.name
  name           = "webapp"
}