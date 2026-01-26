resource "azurerm_resource_group" "test" {
  name     = "acctestRG-${random_integer.number.result}"
  location = "eastus"

  managed_by = "test"
}
