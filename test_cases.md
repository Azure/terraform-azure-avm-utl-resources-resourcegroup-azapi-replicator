# Test Cases for azurerm_resource_group

| case name | file url | status | test status |
| ---       | ---      | ---    | ---         |
| basic | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/resource/resource_group_resource_test.go | Completed | test success |
| withTagsConfig | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/resource/resource_group_resource_test.go | Completed | test success |
| withTagsUpdatedConfig | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/resource/resource_group_resource_test.go | Completed | test success |
| withManagedByConfig | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/resource/resource_group_resource_test.go | Completed | test failed |
| withFeatureFlag | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/resource/resource_group_resource_test.go | Completed | test success |

---

## Detailed Analysis

### Basic/Foundation Cases (1 case):
1. **`basic(data)`** - Core functionality with minimal configuration: creates a resource group with name and location

### Feature-Specific Cases (2 cases):
2. **`withTagsConfig(data)`** - Tests resource group with tags (environment=Production, cost_center=MSFT)
3. **`withManagedByConfig(data)`** - Tests resource group with managed_by field set to "test"

### Update/Lifecycle Cases (1 case):
4. **`withTagsUpdatedConfig(data)`** - Tests updating tags on resource group (from 2 tags to 1, changing values)

### Advanced Configuration Cases (1 case):
5. **`withFeatureFlag(data, featureFlagEnabled)`** - Tests provider feature flag `prevent_deletion_if_contains_resources` with nested resources

---

## Removed Cases:
- ❌ `requiresImportConfig(data)` - Error test case (validates import rejection with RequiresImportError)

**Total Valid Test Cases**: 5

---

## Notes:
- **Resource Name**: `resource_group` (from `azurerm_resource_group`)
- **Service Namespace**: `resource`
- **Test File**: `resource_group_resource_test.go`
- **Identity Test File**: `resource_group_resource_identity_gen_test.go` exists but contains auto-generated identity tests that follow different patterns
- The resource group is one of the simplest Azure resources with only a few test cases covering basic functionality, tags, and managed_by fields
- The `withFeatureFlag` test case is special as it tests provider-level behavior rather than resource configuration
