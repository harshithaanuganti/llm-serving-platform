terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
  required_version = ">= 1.5"
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source       = "./modules/vpc"
  cluster_name = var.cluster_name
  aws_region   = var.aws_region
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = var.cluster_name
  aws_region   = var.aws_region
  node_type    = var.node_type
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnet_ids
}