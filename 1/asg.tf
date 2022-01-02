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

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}


resource "aws_launch_configuration" "lc" {
  name_prefix   = "${var.prefix}ecs-lc-golang"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  lifecycle {
    create_before_destroy = true
  }
  iam_instance_profile = aws_iam_instance_profile.ecs_service_role.name
  key_name             = aws_key_pair.generated_key.key_name
  security_groups      = [aws_security_group.web.id]
  user_data            = <<EOF
#! /bin/bash
sudo apt-get update
sudo echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
EOF
}

resource "aws_autoscaling_group" "asg" {
  name                      = "asg-${aws_launch_configuration.lc.name}"
  launch_configuration      = aws_launch_configuration.lc.name
  min_size                  = 0
  max_size                  = 6
  desired_capacity          = 2
  health_check_type         = "ELB"
  health_check_grace_period = 15
  vpc_zone_identifier       = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  target_group_arns     = [aws_lb_target_group.lb_target_group.arn]
  protect_from_scale_in = true
  lifecycle {
    create_before_destroy = true
  }
}
