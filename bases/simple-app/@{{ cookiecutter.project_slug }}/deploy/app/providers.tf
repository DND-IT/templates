locals {
  region = "@{{ cookiecutter.aws_region }}"
}
terraform {
  required_version = "~> 1.11.0"

  backend "s3" {
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
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

locals {
  stack        = module.platform_ssm.stacks[0]
  cluster_name = module.platform_ssm.lookup[local.stack].cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.id]
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "infra_local" {
  backend = "s3"
  config = {
    bucket = "tf-state-${data.aws_caller_identity.current.account_id}"
    key    = "terraform.tfstate"
    region = local.region
  }
}

module "platform_ssm" {
  source  = "tx-pts-dai/kubernetes-platform/aws//modules/ssm"
  version = "0.11.3"

  base_prefix       = "infrastructure"
  stack_type        = "platform"
  stack_name_prefix = ""

  lookup = ["cluster_name"]
}
