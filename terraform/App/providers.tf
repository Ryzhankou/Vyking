# provider "kubernetes" {
# #   alias = "cluster"
#   config_path = "~/.kube/config"
#   config_context = "kind-dev-global-cluster-0"
#   # host                   = var.EKS_required ? data.aws_eks_cluster.eks_cluster.endpoint : null
#   # cluster_ca_certificate = var.EKS_required ? base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data) : null
#   # token                  = var.EKS_required ? data.aws_eks_cluster_auth.eks.token : null
# }

# provider "helm" {
#     kubernetes {
#         config_path = "~/.kube/config"
#         config_context = "kind-dev-global-cluster-0"
#         # host                   = var.EKS_required ? data.aws_eks_cluster.eks_cluster.endpoint : null
#         # cluster_ca_certificate = var.EKS_required ? base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data) : null
#         # token                  = var.EKS_required ? data.aws_eks_cluster_auth.eks.token : null
#     }
# }

provider "argocd" {
  port_forward_with_namespace = "argocd"

  username = "admin"
  password = var.argocd_admin_password

  config_path = "~/.kube/config"
  context     = "kind-dev-global-cluster-0"
}