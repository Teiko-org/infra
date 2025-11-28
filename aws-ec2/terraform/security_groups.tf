resource "aws_security_group" "public" {
  name        = "${var.project_name}-public-sg"
  description = "Security group for public instances (frontend/proxy)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-public-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_security_group" "private" {
  name        = "${var.project_name}-private-sg"
  description = "Security group for private instances (backend)"
  vpc_id      = aws_vpc.main.id

  # Backend acessível apenas a partir das públicas (porta 8080).
  ingress {
    description     = "Backend HTTP from public instances"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  ingress {
    description = "RabbitMQ AMQP interno"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "RabbitMQ console interno"
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # SSH opcionalmente apenas a partir do seu IP (usa o mesmo CIDR das públicas).
  ingress {
    description = "SSH administrativo"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-private-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for DB instance (MySQL/MariaDB)"
  vpc_id      = aws_vpc.main.id

  # MySQL acessível apenas a partir dos backends.
  ingress {
    description     = "MySQL a partir dos backends"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.private.id]
  }

  # SSH administrativo (pode ser endurecido depois com bastion/VPN).
  ingress {
    description = "SSH administrativo"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-db-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}


