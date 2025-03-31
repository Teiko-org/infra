provider "azurerm" {
  features {}
  subscription_id = "c08931ec-17b7-432b-b383-79e2850655f0"
}

# Grupo de Recursos
resource "azurerm_resource_group" "carambolo_rg" {
  name     = "carambolo-rg"
  location = "East US"
}

# Plano de Serviço para o Front-End (ajustado para F1 - Free)
resource "azurerm_service_plan" "frontend_plan" {
  name                = "frontend-plan"
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  location            = azurerm_resource_group.carambolo_rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "frontend_app" {
  name                = "frontend-app-carambolo"
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  location            = azurerm_resource_group.carambolo_rg.location
  service_plan_id = azurerm_service_plan.frontend_plan.id

  site_config {
    application_stack {
      node_version = "22-lts"
    }
    always_on = false
    use_32_bit_worker = true
  }
}

# # Configuração do Deployment via GitHub
# resource "azurerm_app_service_source_control" "frontend_deploy" {
#   app_id   = azurerm_linux_web_app.frontend_app.id
#   repo_url = "https://github.com/Teiko-org/frontend"
#   branch   = "main"
#   use_manual_integration = false
# }

# Plano de Serviço para o Back-End
resource "azurerm_service_plan" "backend_plan" {
  name                = "backend-plan"
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  location            = azurerm_resource_group.carambolo_rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# Aplicação Back-End
resource "azurerm_linux_web_app" "backend_app" {
  name                = "backend-app-carambolo"
  location            = azurerm_resource_group.carambolo_rg.location
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  service_plan_id     = azurerm_service_plan.backend_plan.id

  site_config {
    application_stack {
    java_server = "TOMCAT"
    java_version = "11"
    java_server_version = "11"
    }
    always_on = false
  }
}

# resource "azurerm_app_service_source_control" "backend_deploy" {
#   app_id   = azurerm_linux_web_app.backend_app.id
#   repo_url = "https://github.com/Teiko-org/backend"
#   branch   = "main"
#   use_manual_integration = false
# }

# # Banco de Dados MySQL
# resource "azurerm_mysql_flexible_server" "mysql_server" {
#   name                = "mysql-server-carambolo"
#   location            = azurerm_resource_group.carambolo_rg.location
#   resource_group_name = azurerm_resource_group.carambolo_rg.name
#   sku_name            = "B_Standard_B1s"
#   administrator_login    = "carambolo"
#   administrator_password = var.db_password
#   version                = "8.0.21"  
# }

# resource "azurerm_mysql_flexible_database" "mysql_db" {
#   name                = "carambolo_db"
#   resource_group_name = azurerm_resource_group.carambolo_rg.name
#   server_name         = azurerm_mysql_flexible_server.mysql_server.name
#   charset            = "utf8"
#   collation          = "utf8_general_ci"
# }

# # Regras de Firewall para o Banco de Dados
# resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_services" {
#   name                = "AllowAzureServices"
#   resource_group_name = azurerm_resource_group.carambolo_rg.name
#   server_name         = azurerm_mysql_flexible_server.mysql_server.name
#   start_ip_address    = "0.0.0.0"
#   end_ip_address      = "255.255.255.255"
# }

# # Variável para senha segura
# variable "db_password" {
#   description = "Senha do banco de dados MySQL"
#   type        = string
#   sensitive   = true
# }