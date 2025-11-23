resource "aws_instance" "ec2_front"{
  ami                    = "ami-0341d95f75f311023" # Amazon Linux 2
  instance_type          = "t3.micro"
  key_name               = "tismed-2025"
  vpc_security_group_ids = [aws_security_group.tm-frontend-sg.id]
  iam_instance_profile   = "ecr-ec2-terraform-role"
  user_data              = file("user_data.sh")
  tags = {
    Name        = "tismed-frontend"
    provisioner = "terraform"
  }
}
resource "aws_security_group" "tm-frontend-sg" {
  name        = "tismed-frontend-sg"
  description = "Security group for tismed-frontend"
  tags = {
    Name        = "tismed-frontend-sg"
    provisioner = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_3001" {
  type              = "ingress"
  from_port         = 3001
  to_port           = 3001
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tm-frontend-sg.id
}
resource "aws_security_group_rule" "ingress_3000" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tm-frontend-sg.id
}
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tm-frontend-sg.id
}

