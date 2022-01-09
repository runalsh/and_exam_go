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
    key    = "awsecr/awsecr.tfstate"
	lifecycle {
    prevent_destroy = true
	}
    versioning {
    enabled = true
  }
}}
