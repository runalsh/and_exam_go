resource "aws_ecs_cluster" "cluster" {
  name               = var.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.cap_provider.name]

}

resource "aws_ecs_capacity_provider" "cap_provider" {
  name = "${var.prefix}capacity-provider-golang"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

# update file container-def, so it's pulling image from ecr
resource "aws_ecs_task_definition" "task-definition" {
  family                = "${var.prefix}web-golang"
  container_definitions = file("container-definition.json")
  network_mode          = "bridge"

}

resource "aws_ecs_service" "service" {
  name                               = "${var.prefix}golang-service"
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.task-definition.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = "50"
  deployment_maximum_percent         = "200"
  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = "${var.prefix}golang-container"
    container_port   = 80
  }
  # Optional: Allow external changes without Terraform plan difference(for example ASG)
  lifecycle {
    ignore_changes = [desired_count]
  }
  launch_type = "EC2"
  depends_on  = [aws_lb_listener.web-listener]
}

