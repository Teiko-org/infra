data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db-subnet-group"
    Role = "db"
  })
}

resource "aws_db_instance" "db" {
  identifier = "${var.project_name}-db"

  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  max_allocated_storage = 100
  storage_type         = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az               = false
  publicly_accessible    = false
  deletion_protection    = false
  skip_final_snapshot    = true
  apply_immediately      = true
  backup_retention_period = 1

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rds-mysql"
    Role = "db"
  })
}

resource "aws_instance" "private" {
  count = 2

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_private
  subnet_id              = aws_subnet.private[count.index].id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = var.key_name

  associate_public_ip_address = false

  root_block_device {
    volume_size = var.root_volume_size_private
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data_private.sh.tpl", {
    shared_jwt          = var.shared_jwt
    aws_s3_bucket_name  = var.aws_s3_bucket_name
    aws_region          = var.aws_region
    db_host             = aws_db_instance.db.address
    db_name             = var.db_name
    db_username         = var.db_username
    db_password         = var.db_password
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-backend-${count.index == 0 ? "a" : "b"}"
    Role = "backend"
  })
}

resource "aws_instance" "public" {
  count = 2

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_public
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.public.id]
  key_name               = var.key_name

  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size_public
    volume_type = "gp3"
  }

  # Monta a lista de backends (todas as privadas) no formato IP:8080,IP:8080,...
  user_data = templatefile("${path.module}/user_data_public.sh.tpl", {
    api_upstreams = join(
      ",",
      [
        for inst in aws_instance.private :
        "${inst.private_ip}:8080"
      ]
    )
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-publica-${count.index == 0 ? "a" : "b"}"
    Role = "frontend-proxy"
  })
}


