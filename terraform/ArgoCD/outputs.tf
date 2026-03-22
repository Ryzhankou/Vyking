output "argocd_namespace" {
  value       = module.ArgoCD.argocd_namespace
  description = "Kubernetes namespace where Argo CD is installed."
}

output "helm_release_status" {
  value       = module.ArgoCD.helm_release_status
  description = "Status of the Argo CD Helm release."
}
