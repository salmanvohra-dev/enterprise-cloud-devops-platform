terraform {
  backend "s3" {
    bucket         = "enterprise-devops-terraform-state-bucket22" # Apne bucket ka naam yahan dalna
    key            = "prod/eks-cluster/terraform.tfstate"
    region         = "us-east-1" # Apne bucket ka region yahan dalna
    #dynamodb_table = "enterprise-eks-terraform-locks"
    encrypt        = true
  }
}