provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# Create VPC, subnets, and security groups (if not already created)

# Create ALB
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  enable_http2 = true
}

# Create HTTPS listener
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:your-account-id:certificate/your-acm-certificate-arn"
}

# Create a default target group
resource "aws_lb_target_group" "default_target_group" {
  name     = "default-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path     = "/"
    port     = "traffic-port"
    protocol = "HTTP"
  }
}

# Attach the default target group to the HTTPS listener
resource "aws_lb_listener_rule" "https_default_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default_target_group.arn
  }
}

# Additional rules and target groups can be added for more sophisticated routing

# Create a security group for the ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.my_vpc.id

  # Define inbound and outbound rules for ALB security group
  # ...
}
