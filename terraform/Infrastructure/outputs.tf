output "infrastructure_application_name" {
  value       = module.Infrastructure.application_name
  description = "Name of the Argo CD Application for infrastructure."
}

output "infrastructure_project_name" {
  value       = module.Infrastructure.project_name
  description = "Argo CD project name for infrastructure."
}
