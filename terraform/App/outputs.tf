output "infrastructure_application_name" {
  value       = module.Infrastructure.application_name
  description = "Name of the Argo CD Application for infrastructure."
}

output "infrastructure_project_name" {
  value       = module.Infrastructure.project_name
  description = "Argo CD project name for infrastructure."
}

output "app_application_name" {
  value       = module.App.application_name
  description = "Name of the Argo CD Application for frontend/backend."
}

output "app_project_name" {
  value       = module.App.project_name
  description = "Argo CD project name for the application."
}
