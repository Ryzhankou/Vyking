output "application_name" {
  value       = argocd_application.app.metadata[0].name
  description = "Name of the Argo CD Application."
}

output "project_name" {
  value       = argocd_project.app.metadata[0].name
  description = "Argo CD project name."
}
