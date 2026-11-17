output "karpenter_node_role_name" {
  value = aws_iam_role.karpenter_node.name
}

output "karpenter_instance_profile_name" {
  value = aws_iam_instance_profile.karpenter.name
}

output "karpenter_controller_role_arn" {
  value = aws_iam_role.karpenter_controller.arn
}