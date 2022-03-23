resource "aws_lb" "nginx" {
  name               = "application-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public.id]
  subnets = module.vpc.public_subnets_id
  enable_deletion_protection = false

  tags = {
    Name = "terraform-ALB"
  }
}

resource "aws_lb_target_group" "nginx" {
  name     = "nginx-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  health_check {
    enabled = true
    path = "/"
  }
  tags = {
    Name = "ngnix-target-group"
  }
}

resource "aws_lb_listener" "nginx" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
    forward {
      target_group {
        arn = aws_lb_target_group.nginx.arn
      }
      stickiness {
        enabled  = true
        duration = 60
      }
    }
  }
}

resource "aws_lb_target_group_attachment" "nginx" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = aws_instance.web_app[count.index].id
  port             = 80
}
