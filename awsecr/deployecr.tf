

terraform {

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  default = "eu-central-1"
}

# resource "aws_s3_bucket" "terraform_state" {
  # bucket = "py-app-ecr-state"
  # lifecycle {
    # prevent_destroy = true
  # }
  # versioning {
    # enabled = true
  # }
  # server_side_encryption_configuration {
    # rule {
      # apply_server_side_encryption_by_default {
        # sse_algorithm = "AES256"
      # }
    # }
  # }
# }


resource "aws_ecr_repository" "app_repo_go" {
  name = "gorepo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "repo_policy" {
  repository = aws_ecr_repository.app_repo_go.name

policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "more 5 to trash",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

# придется сохранять, ничего умнее не придумал
# альтернатива - обьединить ecr ecs dep в один tf и сохранять его

terraform {
  backend "s3" {
    bucket = "py-app-ecr-state"
    key    = "awsecr/terraform.tfstate"
    region = "eu-central-1"
  }
}

#=============================================================

resource "aws_s3_bucket" "terraform_ecs_state" {
  bucket = "py-app-ecs-state"
  lifecycle {
    prevent_destroy = true
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = "py-app-ecr-state"
  lifecycle {
    prevent_destroy = true
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
