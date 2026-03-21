output "application_name" {
  value       = argocd_application.infrastructure.metadata[0].name
  description = "Name of the Argo CD Application"
}
