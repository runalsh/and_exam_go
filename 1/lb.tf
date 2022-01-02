resource "aws_lb" "web" {
  name                       = "${var.prefix}lb-golang"
  load_balancer_type         = "application"
  subnets                    = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  security_groups            = [aws_security_group.elb.id]
  enable_deletion_protection = false
}



resource "aws_lb_target_group" "lb_target_group" {
  name        = "${var.prefix}tg-golang"
  port        = "80"
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 3
    interval            = 5
    matcher             = "200,301,302"
  }
}

resource "aws_lb_listener" "web-listener" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}