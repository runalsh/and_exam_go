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

resource "aws_ecr_repository" "app_repo_go" {
  name = "gorepo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "repo_policy" {
  repository = aws_ecr_repository.app_repo_go.name
  # policy     = file("life_go_ecr.json")

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