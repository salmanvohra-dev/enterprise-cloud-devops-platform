locals {
  cluster_name = "enterprise-eks-prod"
}

module "vpc" {
  source       = "../../modules/vpc"
  cluster_name = local.cluster_name
  vpc_cidr     = "10.100.0.0/16"
}

module "eks" {
  source       = "../../modules/eks"
  cluster_name = local.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}
module "karpenter" {
  source            = "../../modules/karpenter"
  cluster_name      = local.cluster_name
  cluster_id        = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.oidc_issuer_url
}