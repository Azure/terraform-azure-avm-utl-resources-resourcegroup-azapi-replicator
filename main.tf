locals {
  azapi_header = {
    type                 = "Microsoft.Resources/resourceGroups@2023-07-01"
    name                 = var.name
    location             = var.location
    parent_id            = "/subscriptions/${var.subscription_id}"
    tags                 = var.tags
    ignore_null_property = true
    retry                = null
  }
  body = {
    managedBy  = var.managed_by
    properties = {}
  }
  locks = []
  replace_triggers_external_values = {
    name     = { value = var.name }
    location = { value = var.location }
  }
  sensitive_body = {
    properties = {}
  }
  sensitive_body_version = {}
}
