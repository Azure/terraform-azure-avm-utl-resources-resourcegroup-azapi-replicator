variable "location" {
  type        = string
  description = "(Required) The Azure Region where the Resource Group should exist. Changing this forces a new Resource Group to be created."
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) The Name which should be used for this Resource Group. Changing this forces a new Resource Group to be created."
  nullable    = false
}

variable "subscription_id" {
  type        = string
  description = "(Required) The Subscription ID in which the Resource Group should exist. Changing this forces a new Resource Group to be created."
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "managed_by" {
  type        = string
  default     = null
  description = "(Optional) The ID of the resource or application that manages this Resource Group."

  validation {
    condition     = var.managed_by == null || var.managed_by != ""
    error_message = "The managed_by value must not be an empty string."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags which should be assigned to the Resource Group."

  validation {
    condition     = var.tags == null || length(var.tags) <= 50
    error_message = "A maximum of 50 tags can be applied to each resource."
  }
  validation {
    condition = var.tags == null || alltrue([
      for k, v in var.tags : length(k) <= 512
    ])
    error_message = "The maximum length for a tag key is 512 characters."
  }
  validation {
    condition = var.tags == null || alltrue([
      for k, v in var.tags : length(v) <= 256
    ])
    error_message = "The maximum length for a tag value is 256 characters."
  }
}

variable "timeouts" {
  type = object({
    create = optional(string, "90m")
    delete = optional(string, "90m")
    read   = optional(string, "5m")
    update = optional(string, "90m")
  })
  default = {
    create = "90m"
    delete = "90m"
    read   = "5m"
    update = "90m"
  }
  description = <<-EOT
 - `create` - (Optional) Specifies the timeout for create operations. Defaults to 90 minutes.
 - `delete` - (Optional) Specifies the timeout for delete operations. Defaults to 90 minutes.
 - `read` - (Optional) Specifies the timeout for read operations. Defaults to 5 minutes.
 - `update` - (Optional) Specifies the timeout for update operations. Defaults to 90 minutes.
EOT
  nullable    = false
}
