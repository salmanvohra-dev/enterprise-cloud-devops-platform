# 1. Random suffix taaki S3 bucket ka naam globally unique rahe
resource "random_id" "velero_bucket_suffix" {
  byte_length = 4
}

# 2. Velero Backup S3 Bucket
resource "aws_s3_bucket" "velero_backups" {
  bucket        = "salman-eks-velero-backups-${random_id.velero_bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "velero-cluster-backups"
    Environment = "prod"
  }
}

# Bucket par Server-Side Encryption (Security Best Practice)
resource "aws_s3_bucket_server_side_encryption_configuration" "velero_enc" {
  bucket = aws_s3_bucket.velero_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public Access Block (Koi bahar se backup na dekh sake)
resource "aws_s3_bucket_public_access_block" "velero_public_block" {
  bucket                  = aws_s3_bucket.velero_backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# FinOps: 30 din purane backups auto-delete taaki S3 bill na badhe
resource "aws_s3_bucket_lifecycle_configuration" "velero_lifecycle" {
  bucket = aws_s3_bucket.velero_backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# 3. Velero IRSA IAM Role (EKS ServiceAccount ko AWS permissions dene ke liye)
data "aws_iam_policy_document" "velero_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:velero:velero-server"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "velero_irsa" {
  name               = "eks-velero-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.velero_assume_role.json
}

# Velero ko S3 aur EC2/EBS Snapshots ki permissions
resource "aws_iam_role_policy" "velero_policy" {
  name = "velero-s3-ec2-snapshot-policy"
  role = aws_iam_role.velero_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${aws_s3_bucket.velero_backups.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.velero_backups.arn
      }
    ]
  })
}

# 4. Outputs (Inki values hum ArgoCD Velero chart mein use karenge)
output "velero_bucket_name" {
  value       = aws_s3_bucket.velero_backups.bucket
  description = "Velero backups ke liye S3 bucket ka naam"
}

output "velero_iam_role_arn" {
  value       = aws_iam_role.velero_irsa.arn
  description = "Velero ServiceAccount ke liye IAM Role ARN"
}