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

resource "aws_instance" "db" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type_db
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name               = var.key_name

  associate_public_ip_address = false

  root_block_device {
    volume_size = var.root_volume_size_db
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data_db.sh.tpl", {
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-db"
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
    shared_jwt                      = var.shared_jwt
    azure_storage_connection_string = var.azure_storage_connection_string
    azure_storage_container_name    = var.azure_storage_container_name
    db_host                         = aws_instance.db.private_ip
    db_name                         = var.db_name
    db_username                     = var.db_username
    db_password                     = var.db_password
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


