resource "aws_launch_configuration" "lc" {
  name_prefix          = local.name_prefixes.lc
  image_id             = data.aws_ami.amazon_ecs_linux.id
  iam_instance_profile = aws_iam_instance_profile.ec2_role_profile.name
  security_groups      = [aws_security_group.isg.id]
  instance_type        = var.instance_type
  user_data = templatefile(
    "files/user_data/launch_configuration.tpl",
    {
      cluster_name = var.ecs_cluster_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name_prefix               = local.name_prefixes.asg
  vpc_zone_identifier       = aws_subnet.public_sn.*.id
  launch_configuration      = aws_launch_configuration.lc.name
  health_check_grace_period = var.asg.health_check_grace_period
  desired_capacity          = var.asg.desired_capacity
  min_size                  = var.asg.min_size
  max_size                  = var.asg.max_size
  health_check_type         = var.asg.health_check_type
  depends_on                = [aws_ecs_cluster.ecs_cluster]

  lifecycle {
    create_before_destroy = true
  }
}
