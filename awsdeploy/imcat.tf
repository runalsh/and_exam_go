

#==========================================IAM===============

provider "aws" {
  region = var.region
}

variable "region" {
  default = "eu-central-1"
}

variable "public_subnets" {
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

variable "key_name" {
  type    = string
  default = "grdgd678"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami*amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon", "self"]
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# resource "aws_s3_bucket" "terraform_ecs_state" {
  # bucket = "py-app-ecs-state"
  # lifecycle {
    # prevent_destroy = true
  # }
  # versioning {
    # enabled = true
  # }
  # server_side_encryption_configuration {
    # rule {
      # apply_server_side_encryption_by_default {
        # sse_algorithm = "AES256"
      # }
    # }
  # }
# }

terraform {
  backend "s3" {
    bucket = "py-app-ecs-state"
    key    = "awsecs/terraform.tfstate"
    region = "eu-central-1"
  }
}

#===============================VARIABLES=================================================



##ДАТЬ ecsTaskExecutionRole ПОЛИСИ  AmazonECSTaskExecutionRolePolicy 

resource "aws_iam_instance_profile" "ecs_service_role" {
  role = aws_iam_role.ecs-instance-role.name
}




resource "aws_iam_role" "ecs-instance-role" {
  name = "ecs-golang-instance-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
  role       = aws_iam_role.ecs-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


# ==================================VPC==============================================


resource "aws_internet_gateway" "igw_main" {
  vpc_id = aws_vpc.vpc_main.id
  tags = {
    Name = "go-int-gw"
  }
}

resource "aws_security_group" "sg_main" {
  name   = "aws-sec-group-main"
  description = "allowed 22 and 8080"
  vpc_id = aws_vpc.vpc_main.id 
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  # ingress {
    # cidr_blocks = ["0.0.0.0/0"]
    # from_port   = 8080
    # protocol    = "tcp"
    # to_port     = 8080
  # }
   # ingress {
    # cidr_blocks = ["0.0.0.0/0"]
    # from_port   = 22
    # protocol    = "tcp"
    # to_port     = 22
  # }
  # пусть будет иначе за LB нет соединения 
  # TODO создать для LB свою SG
   ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}


# resource "aws_subnet" "subnet_c" {
  # availability_zone_id    = "euc1-az3"
  # cidr_block              = "10.0.2.0/24"
  # map_public_ip_on_launch = true
  # vpc_id                  = aws_vpc.vpc_main.id
# }

# resource "aws_subnet" "subnet_a" {
  # availability_zone_id    = "euc1-az1"
  # cidr_block              = "10.0.1.0/24"
  # map_public_ip_on_launch = true
  # vpc_id                  = aws_vpc.vpc_main.id
# }

data "aws_availability_zones" "aviable_zones" {
  state                   = "available"
}

resource "aws_subnet" "subnets" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.aviable_zones.names[count.index]
  map_public_ip_on_launch = "true"
}

resource "aws_vpc" "vpc_main" {
  tags = {
    Name = "go-aws-vpc"
  }
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_route_table" "vpc_route" {
  vpc_id = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_main.id
  }
}

resource "aws_route_table_association" "vpc_route_assoc" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.vpc_route.id
}


# #==============================LAUNCH_ROCKET==============================

resource "aws_launch_configuration" "launcher" {
  name_prefix   = "launcher-go-ecs"
  associate_public_ip_address = false
  enable_monitoring           = true
  image_id                    = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.ecs_service_role.arn
  key_name             = aws_key_pair.generated_key.key_name
  security_groups = [aws_security_group.sg_main.id]
  user_data       = <<EOF
#! /bin/bash
echo "ECS_CLUSTER=go-cluster" >> /etc/ecs/ecs.config
EOF
    lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscale_group" {
  name                      = "autoscale_group-${aws_launch_configuration.launcher.name}"
  # default_cooldown        = 300
  desired_capacity        = 2
  health_check_grace_period = 10
  target_group_arns     = [aws_lb_target_group.lb_tg.arn]
  health_check_type       = "ELB"
  launch_configuration    = aws_launch_configuration.launcher.id
  max_size                = 4
  metrics_granularity     = "1Minute"
  min_size                = 0
  vpc_zone_identifier       = aws_subnet.subnets.*.id
  depends_on                = [aws_ecs_cluster.go-cluster]
  # service_linked_role_arn = aws_iam_role.awsserviceroleforautoscaling.arn
  protect_from_scale_in = true
  tag {
    key                 = "Description"
    propagate_at_launch = true
    value               = "This instance is the part of the Auto Scaling group which was created through ECS Console"
  }
   lifecycle {
    create_before_destroy = true
  }
}



#==================================ECS++++++++++++++++++++++++


resource "aws_ecs_cluster" "go-cluster" {
  name = "go-cluster"
  # capacity_providers = [aws_ecs_capacity_provider.ecs-capacity.name]  
}

# resource "aws_ecs_capacity_provider" "ecs-capacity" {
  # name = "capacity-provider-golang"
  # auto_scaling_group_provider {
    # auto_scaling_group_arn         = aws_autoscaling_group.autoscale_group.arn
   # managed_termination_protection = "ENABLED"
    # managed_scaling {
      # status          = "ENABLED"
      # target_capacity = 100
    # }
  # }
    # # lifecycle {
    # # create_before_destroy = true
  # # }
# }

resource "aws_ecs_task_definition" "task-definition" {
  family                = "definitiontaskgobridge"
  network_mode          = "bridge"
  container_definitions =  file("init-task-definition.json")
  # container_definitions = jsonencode([
    # {
      # name      = "go-container-ecr"
      # image     = "082046016299.dkr.ecr.eu-central-1.amazonaws.com/gorepo:latest"
      # cpu       = 256
      # memory    = 512
      # essential = true
      # portMappings = [
        # {
          # containerPort = 8080
          # hostPort      = 8080
        # }
      # ]
    # }
  # ])

}


resource "aws_ecs_service" "service" {
  name                               = "go-service"
  cluster                            = aws_ecs_cluster.go-cluster.id
  task_definition                    = aws_ecs_task_definition.task-definition.arn
  launch_type = "EC2"
  depends_on  = [aws_lb_listener.lb-listener]
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_tg.arn
    container_name   = "go-container-ecr"
    container_port   = 8080
  }
  desired_count                      = 2
  deployment_minimum_healthy_percent = "50"
  deployment_maximum_percent         = "100"
  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
}

#=================================BALANCER=========================

# resource "aws_lb" "web" {
  # name                       = "go-load-balancer"
  # load_balancer_type         = "application"
  # subnets                    = aws_subnet.subnets.*.id
  # security_groups            = [aws_security_group.sg_main.id]
  # enable_deletion_protection = false
  # internal           = false
# }



resource "aws_lb_target_group" "lb_tg" {
  name        = "go-load-balancer-tg"
  port        = "8080"
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_main.id
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 2
    interval            = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.web.arn
  port              = "8080"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}


#===========================SHOWMEWHATYOUHAVE===================

# output "alb_dns" {
  # value = aws_lb.web.dns_name
# }
