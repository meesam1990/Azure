# Virtual Network
resource "azurerm_virtual_network" "dev_vnet" {
  name                = var.vnet_name
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "dev_nsg" {
  name                = "dev-buddiedeals-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Public Subnets
resource "azurerm_subnet" "public" {
  count               = length(var.public_subnets)
  name                = "public-subnet-${count.index + 1}"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.dev_vnet.name
  address_prefixes    = [element(var.public_subnets, count.index)]

  service_endpoints   = ["Microsoft.Storage"]
}

# Private Subnets
resource "azurerm_subnet" "private" {
  count               = length(var.private_subnets)
  name                = "private-subnet-${count.index + 1}"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.dev_vnet.name
  address_prefixes    = [element(var.private_subnets, count.index)]

  service_endpoints   = ["Microsoft.Storage"]
}

# Attach NSG to Public Subnets
resource "azurerm_subnet_network_security_group_association" "public_nsg_association" {
  count               = length(var.public_subnets)
  subnet_id           = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.dev_nsg.id
}

# Attach NSG to Private Subnets
resource "azurerm_subnet_network_security_group_association" "private_nsg_association" {
  count               = length(var.private_subnets)
  subnet_id           = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.dev_nsg.id
}

# Public IP for NAT Gateway (for outbound internet from private subnets)
resource "azurerm_public_ip" "nat_gateway_public_ip" {
  name                = "nat-gateway-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NAT Gateway
resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "nat-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

# Associate NAT Gateway with Private Subnets
resource "azurerm_subnet_nat_gateway_association" "private_nat_assoc" {
  count        = length(var.private_subnets)
  subnet_id    = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

# Public Route Table
resource "azurerm_route_table" "public_route_table" {
  name                = "public-route-table"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "route-to-internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }
}

# Associate Public Route Table with Public Subnets
resource "azurerm_subnet_route_table_association" "public_route_assoc" {
  count               = length(var.public_subnets)
  subnet_id           = azurerm_subnet.public[count.index].id
  route_table_id      = azurerm_route_table.public_route_table.id
}

# Private Route Table (to use NAT Gateway for Internet Access)
resource "azurerm_route_table" "private_route_table" {
  name                = "private-route-table"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "nat-gateway-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualNetworkGateway"
  }
}

# Associate Private Route Table with Private Subnets
resource "azurerm_subnet_route_table_association" "private_route_assoc" {
  count               = length(var.private_subnets)
  subnet_id           = azurerm_subnet.private[count.index].id
  route_table_id      = azurerm_route_table.private_route_table.id
}

# Storage Account for Terraform State
resource "azurerm_storage_account" "terraform_state" {
  name                     = var.storage_account_name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"

  network_rules {
    virtual_network_subnet_ids = [
      azurerm_subnet.private[0].id,
      azurerm_subnet.public[0].id
    ]
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# # Blob Container for Terraform State
# resource "azurerm_storage_container" "terraform_state" {
#   name                  = var.container_name
#   storage_account_name  = azurerm_storage_account.terraform_state.name
#   container_access_type = "private"
# }

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
}

# # Network Security Group Flow Logs
# resource "azurerm_monitor_diagnostic_setting" "vnet_flow_logs" {
#   name                       = "vnet-flow-logs"
#   target_resource_id         = azurerm_virtual_network.dev_vnet.id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

#   # enabled_log {
#   #   category = "AuditEvent"
#   # }

#   # metric {
#   #   category = "AllMetrics"
#   # }

# # Logs settings for Network Security Group Flow Logs
#   log {
#     category = "NetworkSecurityGroupFlowEvent"
#     enabled  = true

#     retention_policy {
#       enabled = true
#       days    = 15
#     }
#   }

#   # Metrics settings (optional)
#   metric {
#     category = "AllMetrics"
#     enabled  = true

#     retention_policy {
#       enabled = false
#     }
#   }
#}