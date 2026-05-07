resource "azurerm_container_registry" "demo" {
  name                          = var.acr_name
  resource_group_name           = azurerm_resource_group.demo.name
  location                      = azurerm_resource_group.demo.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = true

  tags = var.tags
}
