resource "azurerm_resource_group" "test" {
  name     = "acctestRG-${random_integer.number.result}"
  location = "eastus"

  tags = {
    environment = "Production"
    cost_center = "MSFT"
  }
}
