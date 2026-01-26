# Migration Plan: azurerm_resource_group → azapi_resource

## Resource Type Identification

**Source**: `azurerm_resource_group`  
**Target**: `azapi_resource`

### Evidence from AzureRM Provider Source Code

Based on the `create` function analysis:

```go
// From: github.com/hashicorp/terraform-provider-azurerm/internal/services/resource
import "github.com/hashicorp/go-azure-sdk/resource-manager/resources/2023-07-01/resourcegroups"

parameters := resourcegroups.ResourceGroup{
    Location: location.Normalize(d.Get("location").(string)),
    Tags:     tags.Expand(d.Get("tags").(map[string]interface{})),
}
```

**Proof**: The import path `resource-manager/resources/2023-07-01/resourcegroups` indicates:
- Azure Resource Type: `Microsoft.Resources/resourceGroups`
- API Version used in provider: `2023-07-01`

### AzAPI Configuration

- **type**: `Microsoft.Resources/resourceGroups@2023-07-01` (or latest: `2025-04-01`)
- **Available API Versions**: 2015-11-01, 2016-02-01, 2016-07-01, 2016-09-01, 2017-05-10, 2018-02-01, 2018-05-01, 2019-03-01, 2019-05-01, 2019-05-10, 2019-07-01, 2019-08-01, 2019-10-01, 2020-06-01, 2020-08-01, 2020-10-01, 2021-01-01, 2021-04-01, 2022-09-01, 2023-07-01, 2024-03-01, 2024-11-01, 2025-03-01, 2025-04-01

## Schema Analysis

From the `resourceResourceGroup()` schema definition:

```go
Schema: map[string]*pluginsdk.Schema{
    "name": commonschema.ResourceGroupName(),          // Required
    "location": commonschema.Location(),               // Required
    "tags": commonschema.Tags(),                      // Optional
    "managed_by": {                                   // Optional
        Type:         pluginsdk.TypeString,
        Optional:     true,
        ValidateFunc: validation.StringIsNotEmpty,
    },
},

Identity: &schema.ResourceIdentity{
    SchemaFunc: pluginsdk.GenerateIdentitySchema(&commonids.ResourceGroupId{}),
},
```

## Planning Task List

| No. | Path | Type | Required | Status | Proof Doc Markdown Link |
|-----|------|------|----------|--------|-------------------------|
| 1 | name | Argument | Yes | ✅ Completed | [1.name.md](1.name.md) |
| 2 | location | Argument | Yes | ✅ Completed | [2.location.md](2.location.md) |
| 3 | tags | Argument | No | ✅ Completed | [3.tags.md](3.tags.md) |
| 4 | managed_by | Argument | No | ✅ Completed | [4.managed_by.md](4.managed_by.md) |
| 5 | __check_root_hidden_fields__ | HiddenFieldsCheck | Yes | ✅ Completed | [5.__check_root_hidden_fields__.md](5.__check_root_hidden_fields__.md) |
| 6 | identity | Block | No | ❌ Not Applicable | [6.identity.md](6.identity.md) |
| 7 | timeouts | Block | No | ✅ Completed | [7.timeouts.md](7.timeouts.md) |
| 8 | timeouts.create | Argument | No | ✅ Completed | [8.timeouts.create.md](8.timeouts.create.md) |
| 9 | timeouts.delete | Argument | No | ✅ Completed | [9.timeouts.delete.md](9.timeouts.delete.md) |
| 10 | timeouts.read | Argument | No | ✅ Completed | [10.timeouts.read.md](10.timeouts.read.md) |
| 11 | timeouts.update | Argument | No | ✅ Completed | [11.timeouts.update.md](11.timeouts.update.md) |

## Notes for Executor

- **name**: Maps to azapi_resource `name` parameter (top-level, not in body)
- **location**: Maps to azapi_resource `location` parameter (top-level, not in body)
- **tags**: Maps to azapi_resource body `tags` field
- **managed_by**: Maps to azapi_resource body `managedBy` field (note camelCase in Azure API)
- **identity**: Identity block needs special handling in azapi_resource `identity` parameter
- **__check_root_hidden_fields__**: Verify no additional fields exist in Azure API schema that are not exposed in azurerm schema
