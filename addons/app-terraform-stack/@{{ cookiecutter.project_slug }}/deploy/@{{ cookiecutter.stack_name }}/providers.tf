locals {
  region = "@{{ cookiecutter.aws_region }}"
}

terraform {
  required_version = "~> 1.13.0"

  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Terraform   = "true"
      Environment = var.environment
      GithubRepo  = var.github_repo
      GithubOrg   = var.github_org
    }
  }
}
