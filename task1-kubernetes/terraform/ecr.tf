resource "aws_ecr_repository" "dev-frontend" {
  name                 = "${var.cluster_name}-dev-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.cluster_name}-dev-frontend"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "dev-backend" {
  name                 = "${var.cluster_name}-dev-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.cluster_name}-dev-backend"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "dev-postgres" {
  name                 = "${var.cluster_name}-dev-postgres"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.cluster_name}-dev-postgres"
    Environment = var.environment
  }
}