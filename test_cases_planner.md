# Prompt: Extract Terraform Provider Test Cases

## Objective
Extract all valid atomic test configuration case names from a Terraform provider's acceptance test file for a given resource type. This list will be used to systematically test AzAPI migration scenarios.

**CRITICAL OUTPUT REQUIREMENT**: You MUST create a new file named `test_cases.md` in the workspace root directory containing all the extracted test cases in a markdown table format.

The `test_cases.md` file should contain a table with the following format:

| case name | file url | status | test status |
| ---       | ---      | ---    | ---         |
| basic     | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/{SERVICE_NAMESPACE}/{RESOURCE_NAME}_resource_test.go | Pending | Not Tested |
...

## Instructions

### Step 0: Determine Resource Name and Service Namespace
**CRITICAL**: Before starting, you MUST identify the correct resource name and service namespace:

1. **Resource Name**: Extract from the Terraform resource type by removing the `azurerm_` prefix
   - Example: `azurerm_private_dns_zone` → `private_dns_zone`
   - Example: `azurerm_orchestrated_virtual_machine_scale_set` → `orchestrated_virtual_machine_scale_set`

2. **Service Namespace**: Determine the Azure service category. Common namespaces include:
   - `compute` - Virtual machines, scale sets
   - `network` - VNets, subnets, load balancers, network interfaces
   - `privatedns` - Private DNS zones and records
   - `storage` - Storage accounts, blobs, queues
   - `keyvault` - Key vaults, secrets, keys
   - `containerservice` - AKS, container instances
   - To find the namespace: Use GitHub search for the resource file or check the Azure provider documentation

**Example Mappings**:
- `azurerm_private_dns_zone` → Resource: `private_dns_zone`, Namespace: `privatedns`
- `azurerm_orchestrated_virtual_machine_scale_set` → Resource: `orchestrated_virtual_machine_scale_set`, Namespace: `compute`
- `azurerm_virtual_network` → Resource: `virtual_network`, Namespace: `network`

### Step 1: Locate ALL Test Files
Find ALL acceptance test files for the target resource type in the HashiCorp Terraform provider repository. **IMPORTANT**: Many resources have their tests split across multiple files by feature area.

**Search Pattern**: `{RESOURCE_NAME}_resource*_test.go`

**Example 1**: For `azurerm_orchestrated_virtual_machine_scale_set` (resource: `orchestrated_virtual_machine_scale_set`, namespace: `compute`):
- Pattern: `orchestrated_virtual_machine_scale_set_resource*_test.go`
- This will match:
  - `orchestrated_virtual_machine_scale_set_resource_test.go` (main test file)
  - `orchestrated_virtual_machine_scale_set_resource_disk_data_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_disk_os_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_extensions_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_identity_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_network_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_other_test.go`
  - And any other split files

**Example 2**: For `azurerm_private_dns_zone` (resource: `private_dns_zone`, namespace: `privatedns`):
- Pattern: `private_dns_zone_resource*_test.go`
- This will match:
  - `private_dns_zone_resource_test.go` (main test file)
  - `private_dns_zone_resource_records_test.go` (if split by feature)
  - And any other split files

**How to Search**:
1. Use GitHub search with pattern: `filename:{RESOURCE_NAME}_resource repo:hashicorp/terraform-provider-azurerm path:internal/services/{SERVICE_NAMESPACE}`
2. Or fetch URLs for all matching files:
   - `https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/{SERVICE_NAMESPACE}/{RESOURCE_NAME}_resource_test.go`
   - `https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/{SERVICE_NAMESPACE}/{RESOURCE_NAME}_resource_*_test.go`
   - Continue for each file matching the pattern

**EXCLUSIONS**: 
- ❌ **IGNORE files containing `legacy` in the filename** (e.g., `*_resource_legacy_test.go`) - we don't care about legacy code

**CRITICAL**: You MUST scan ALL test files (except legacy), not just the main one, to get a complete list of test cases.

**IMPORTANT**: Always use the ACTUAL resource name (derived in Step 0) in your searches, NOT example names from this document.

### Step 2: Identify Test Configuration Functions Across ALL Files
Scan **ALL test files** for configuration functions that return Terraform HCL strings. These typically:
- Are methods on the resource's test struct (e.g., `(r ResourceType) functionName(data acceptance.TestData) string`)
- Return `fmt.Sprintf(...)` with Terraform configuration
- Are called within `TestStep.Config` in test methods

**Example Pattern**:
```go
func (ResourceTypeTestStruct) basic(data acceptance.TestData) string {
    return fmt.Sprintf(`
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-%[1]d"
  location = "%[2]s"
}
// ... more resources for the specific resource type
`, data.RandomInteger, data.Locations.Primary)
}
```

### Step 3: Classify Each Configuration Function

For each function found, determine its classification:

#### ✅ **INCLUDE** - Valid Atomic Test Cases:
- Functions used directly in `TestStep.Config` field
- Represent a specific feature or scenario to test
- Examples: `basic()`, `complete()`, `update()`, feature-specific test functions

#### ❌ **EXCLUDE** - Not Valid Test Cases:

1. **Helper/Template Functions**
   - Functions that are only called BY other test functions (never used directly in TestStep)
   - Provide shared infrastructure or common setup
   - Example: `natgateway_template()` that's only used via `%[3]s` injection in other configs

2. **Error Test Cases**
   - Functions used with `ExpectError` in TestStep
   - Validate that provider correctly rejects invalid configurations
   - Look for test steps with `ExpectError: regexp.MustCompile(...)` or `ExpectError: acceptance.RequiresImportError(...)`
   - Examples: `requiresImport()`, `skuProfileNotExist()`, `skuProfileWithoutSkuName()`

### Step 4: Analyze Test Methods for Usage

For each configuration function, check how it's used in test methods (`func TestAcc...`) **across ALL test files**:

**Direct Usage (INCLUDE)**:
```go
func TestAccResource_basic(t *testing.T) {
    data.ResourceTest(t, r, []acceptance.TestStep{
        {
            Config: r.basic(data),  // ✅ Direct usage
            Check: acceptance.ComposeTestCheckFunc(...),
        },
    })
}
```

**Error Test Usage (EXCLUDE)**:
```go
func TestAccResource_requiresImport(t *testing.T) {
    data.ResourceTest(t, r, []acceptance.TestStep{
        {
            Config: r.basic(data),
            Check: acceptance.ComposeTestCheckFunc(...),
        },
        {
            Config:      r.requiresImport(data),  // ❌ Used with ExpectError
            ExpectError: acceptance.RequiresImportError("azurerm_resource"),
        },
    })
}
```

**Helper Usage (EXCLUDE)**:
```go
func (r Resource) someTest(data acceptance.TestData) string {
    return fmt.Sprintf(`
%[3]s  // ❌ natgateway_template injected here, never used directly in TestStep
resource "azurerm_resource" "test" {
  // ...
}
`, data.RandomInteger, data.Locations.Primary, r.natgateway_template(data))
}
```

### Step 5: Organize the Final List

Group valid test cases by category for clarity:

#### Suggested Categories:
1. **Basic/Foundation Cases** - Core functionality, minimal configuration
2. **OS-Specific Cases** - Linux, Windows, different distributions
3. **Feature-Specific Cases** - Individual features like boot diagnostics, proximity placement groups
4. **Advanced Configuration Cases** - Complex scenarios, multiple features combined
5. **Update/Lifecycle Cases** - Testing updates, changes between configurations
6. **Edge Cases** - Regression tests, boundary conditions

### Step 6: Document Each Test Case

For each valid test case, provide:
1. **Function signature**: `r.functionName(data)`
2. **Brief description**: What feature/scenario it tests
3. **Key characteristics**: What makes it unique (e.g., "2 instances vs 1", "with Ed25519 SSH key")

## Output Format

**CRITICAL**: After completing the analysis, you MUST create a file named `test_cases.md` in the workspace root with the following content:

```markdown
# Test Cases for [Resource Type]

| case name | file url | status | test status |
| ---       | ---      | ---    | ---         |
| basic     | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/{SERVICE_NAMESPACE}/{RESOURCE_NAME}_resource_test.go | Pending | Not Tested |
| complete  | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/{SERVICE_NAMESPACE}/{RESOURCE_NAME}_resource_test.go | Pending | Not Tested |
...

---

## Detailed Analysis

### [Category Name] (X cases):
1. **`r.functionName(data)`** - Brief description
2. **`r.anotherFunction(data)`** - Brief description
   ...

### [Another Category] (Y cases):
...

---

## Removed Cases:
- ❌ `r.helperFunction(data)` - Helper/template function (only called by other configs)
- ❌ `r.errorCase(data)` - Error test case (used with ExpectError)
- ❌ `r.requiresImport(data)` - Error test case (validates import rejection)

**Total Valid Test Cases**: [Number]
```

**Important Notes for the Output File**:
- The table must list ONLY valid test cases (exclude helpers and error cases)
- Each test case must include the GitHub raw URL to the specific test file where it's defined
- All test cases should start with status "Pending" and test status "Not Tested"
- The "status" column tracks migration status, the "test status" column tracks testing status
- Include the detailed analysis section below the table for reference

## Example Analysis Workflow

**Example for `azurerm_private_dns_zone`:**
1. **Derive names**: Resource type `azurerm_private_dns_zone` → Resource: `private_dns_zone`, Namespace: `privatedns`
2. **Find ALL test files**: Search for `private_dns_zone_resource*_test.go` in `internal/services/privatedns`
3. **Scan all files for functions**: `func (r PrivateDnsZoneResource) basic(data acceptance.TestData) string` found in test file
4. **Check usage across all files**: Search for `r.basic(data)` in test files
5. **Found in**: `TestAccPrivateDnsZone_basic` with `Config: r.basic(data)` → ✅ INCLUDE
6. **Classification**: Basic configuration
7. **Add to list**: Under "Basic/Foundation Cases"
8. **CREATE `test_cases.md` FILE**: Write all valid test cases to the file with their URLs and status

## Validation Checklist

Before finalizing and **creating the `test_cases.md` file**:
- [ ] All test files matching `<resource_name>_resource*_test.go` pattern have been identified (excluding `*legacy*` files)
- [ ] All test files have been scanned for configuration functions (excluding legacy files)
- [ ] All functions used directly in `TestStep.Config` are included (from all files)
- [ ] All functions with `ExpectError` in same TestStep are excluded
- [ ] All helper functions (only called by other functions) are excluded
- [ ] All `requiresImport` variants are excluded
- [ ] Each case has a clear, descriptive label
- [ ] Cases are logically categorized
- [ ] Total count is accurate
- [ ] File source is documented for each test case
- [ ] **The `test_cases.md` file has been created in the workspace root directory**

## Common Pitfalls to Avoid

❌ **Don't include**: Functions that only provide infrastructure for other tests
❌ **Don't include**: Functions testing error conditions or validation failures
❌ **Don't include**: Functions testing import rejection scenarios
✅ **Do include**: Functions that test actual resource configurations that should work
✅ **Do include**: Functions testing updates between valid states
✅ **Do include**: Functions testing different feature combinations

## Notes

- **CRITICAL FIRST STEP**: Always start by determining the resource name (remove `azurerm_` prefix) and service namespace from the target resource type
- **CRITICAL**: Use the ACTUAL resource name in all searches - do NOT use example names from this document
- **CRITICAL**: Some test files are split across multiple `*_test.go` files - check ALL of them by using the pattern `{RESOURCE_NAME}_resource*_test.go`
- **EXCLUDE**: Files containing `legacy` in the filename (e.g., `*_resource_legacy_test.go`) - ignore these completely
- Use GitHub file search or fetch multiple URLs to retrieve all test files from the correct service namespace path
- Look for patterns like `_disk_`, `_network_`, `_identity_`, `_extensions_`, `_records_`, `_other_` in filenames (often indicate split test files by feature area)
- Look for patterns like `_template`, `_helper`, `_base` in function names (often indicate helpers)
- Test methods with "Error" or "Invalid" in their names often use error test cases
- Update test cases (testing A → B transitions) are valid if both A and B are valid configs
