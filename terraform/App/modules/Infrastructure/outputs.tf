output "application_name" {
  value       = argocd_application.infrastructure.metadata[0].name
  description = "Name of the Argo CD Application for infrastructure."
}

output "project_name" {
  value       = argocd_project.infrastructure.metadata[0].name
  description = "Argo CD project name for infrastructure."
}
