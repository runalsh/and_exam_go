terraform {

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

}

resource "aws_ecr_repository" "app_repo_go" {
  name = "gorepo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "repo_policy" {
  repository = aws_ecr_repository.app_repo_go.name
  policy     = file("life_go_ecr.json")
}
