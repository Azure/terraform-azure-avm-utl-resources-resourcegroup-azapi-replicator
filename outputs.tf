output "azapi_header" {
  depends_on = []
  value      = local.azapi_header
}

output "body" {
  value = local.body
}

output "locks" {
  value = local.locks
}

output "replace_triggers_external_values" {
  value = local.replace_triggers_external_values
}

output "retry" {
  value = local.azapi_header.retry
}

output "sensitive_body" {
  ephemeral = true
  sensitive = true
  value     = local.sensitive_body
}

output "sensitive_body_version" {
  value = local.sensitive_body_version
}

output "timeouts" {
  value = var.timeouts
}
