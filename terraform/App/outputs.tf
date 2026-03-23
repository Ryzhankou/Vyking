output "root_application_name" {
  value       = argocd_application.root.metadata[0].name
  description = "Name of the root Argo CD Application (App of Apps)."
}
