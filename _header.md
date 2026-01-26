# Azure Resource Group - AzAPI Replicator Module

This module replicates the behavior of Azure Resource Manager (AzureRM) provider resources using the AzAPI provider. It generates the necessary locals, variables, validations, and configurations to ensure exact behavioral parity with the original AzureRM provider.

## Purpose

When migrating from `azurerm_*` resources to `azapi_resource`, users lose all provider-level protections including automatic validations, defaults, and type coercions. This replicator module rebuilds those protections by:

- **Exact Replication**: Reproduces ALL AzureRM provider logic including validations, defaults, conditionals, transformations, ForceNew triggers, and CustomizeDiff behaviors
- **Validation Migration**: Implements all provider validations in Terraform native validation blocks for fast plan-time feedback
- **Sensitive Field Handling**: Properly manages sensitive and write-only fields using ephemeral variables and version tracking
- **ForceNew Logic**: Replicates resource replacement triggers including complex CustomizeDiff conditions