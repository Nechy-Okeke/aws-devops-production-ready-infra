resource "aws_ecr_repository" "this" {
  name = "${var.project_name}-app"

  # Production/CI safety: allow destroy even if the repository already has images.
  force_delete = var.force_delete_images

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-ecr"
  }
}
