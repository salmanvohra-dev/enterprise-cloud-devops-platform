resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.0.0"
  timeout          = 300 
  wait             = false
  disable_webhooks = true
  cleanup_on_fail  = false

  set = [
    {
      name  = "settings.clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "settings.clusterEndpoint"
      value = module.eks.cluster_endpoint
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.karpenter.karpenter_controller_role_arn
    },
    {
      name  = "replicas"
      value = "1"
    }
  ]
}

# 1. IAM Policy for AWS Load Balancer Controller
resource "aws_iam_policy" "load_balancer_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Permissions for AWS Load Balancer Controller to manage ALBs/NLBs"
  policy      = file("${path.module}/iam_policy.json")
}

# 2. IAM Role with Web Identity (IRSA via EKS OIDC)
resource "aws_iam_role" "load_balancer_controller" {
  name = "prod-aws-lbc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(module.eks.oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  policy_arn = aws_iam_policy.load_balancer_controller.arn
  role       = aws_iam_role.load_balancer_controller.name
}

# 3. Helm Release (Clean YAML/yamlencode Syntax)
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.1"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName = module.eks.cluster_name
      vpcId       = module.vpc.vpc_id
      region      = "us-east-1"
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.load_balancer_controller.arn
        }
      }
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.load_balancer_controller
  ]
}
# 4. ArgoCD Helm Release (GitOps Engine)
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6"
  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      server = {
        # Testing/demo ke liye NodePort ya LoadBalancer kar sakte ho, 
        # par production ingress use karne ke liye ClusterIP best hai:
        service = {
          type = "ClusterIP"
        }
        # Insecure mode HTTP offloading ke liye (agar ALB SSL terminate karega):
        extraArgs = ["--insecure"]
      }
      # Single node dev/demo testing mein memory optimize karne ke liye:
      redis = {
        enabled = true
      }
      controller = {
        replicas = 1
      }
      repoServer = {
        replicas = 1
      }
    })
  ]

  depends_on = [
    helm_release.karpenter,
    helm_release.aws_load_balancer_controller
  ]
}