output "argocd_namespace" {
  value       = var.argocd_namespace
  description = "Kubernetes namespace where Argo CD is installed."
}

output "helm_release_name" {
  value       = helm_release.ArgoCD.name
  description = "Name of the Helm release for Argo CD."
}

output "helm_release_status" {
  value       = helm_release.ArgoCD.status
  description = "Status of the Argo CD Helm release."
}
