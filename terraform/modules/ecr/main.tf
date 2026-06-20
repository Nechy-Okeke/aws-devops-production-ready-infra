data "external" "ecr_repo_exists" {
  program = [
    "bash",
    "-c",
    <<'EOF'
set -euo pipefail
REPO="${REPO_NAME}"
REGION="${AWS_REGION}"

if aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1; then
  echo '{"exists":"true"}'
else
  echo '{"exists":"false"}'
fi
EOF
  ]

  query = {
    REPO_NAME   = "${var.project_name}-app"
    AWS_REGION  = var.aws_region
  }
}

locals {
  ecr_repo_exists = data.external.ecr_repo_exists.result.exists == "true"
}

resource "aws_ecr_repository" "this" {
  count = local.ecr_repo_exists ? 0 : 1

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
