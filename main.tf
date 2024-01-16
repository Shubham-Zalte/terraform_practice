resource "aws_vpc" "my_vpc" {
  cidr_block = var.cidr_vpc
}

resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "RTA1" {
  route_table_id = aws_route_table.RT.id
  subnet_id = aws_subnet.subnet1.id
}

resource "aws_route_table_association" "RTA2" {
  route_table_id = aws_route_table.RT.id
  subnet_id = aws_subnet.subnet2.id
}

resource "aws_security_group" "my_sg" {
  name = "my_sg"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    description = "Allow all traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Name = "my_sg"
  }
}

resource "aws_instance" "webserver1" {
  ami = var.ubuntu_ami_id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet1.id
  vpc_security_group_ids = [ aws_security_group.my_sg.id ]
  user_data_base64 = base64encode(file("scripts/userdata1.sh"))
}

resource "aws_instance" "webserver2" {
  ami = var.ubuntu_ami_id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet2.id
  vpc_security_group_ids = [ aws_security_group.my_sg.id ]
  user_data_base64 = base64encode(file("scripts/userdata2.sh"))
}

resource "aws_lb" "my_lb" {
  name = "mylb"
  internal = false
  load_balancer_type = "application"
  security_groups = [ aws_security_group.my_sg.id ]
  subnets = [ aws_subnet.subnet1.id, aws_subnet.subnet2.id ]
  tags = {
    lb = "load balancer"
  }
}

resource "aws_lb_target_group" "my_tg" {
  name     = "tf-test-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "TGA1" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "TGA2" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

output "lb_dns_name" {
  value = aws_lb.my_lb.dns_name
}