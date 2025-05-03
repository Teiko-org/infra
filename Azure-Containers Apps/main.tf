provider "azurerm" {
  features {}
  subscription_id = "c08931ec-17b7-432b-b383-79e2850655f0"  
}

# Grupo de Recursos
resource "azurerm_resource_group" "carambolo_rg" {
  name     = "carambolo-rg"
  location = "East US"
}

# Container Registry
resource "azurerm_container_registry" "carambolo_acr" {
  name                = "caramboloacr123"
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  location            = azurerm_resource_group.carambolo_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Container App Environment
resource "azurerm_container_app_environment" "carambolo_env" {
  name                 = "carambolo-env"
  location             = azurerm_resource_group.carambolo_rg.location
  resource_group_name  = azurerm_resource_group.carambolo_rg.name
}

# BACKEND APP
resource "azurerm_container_app" "backend_app" {
  name                         = "carambolo-backend"
  container_app_environment_id = azurerm_container_app_environment.carambolo_env.id
  resource_group_name          = azurerm_resource_group.carambolo_rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "backend"
      image  = "${azurerm_container_registry.carambolo_acr.login_server}/backend:latest"
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "JAVA_OPTS"
        value = "-Xmx512m"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server   = azurerm_container_registry.carambolo_acr.login_server
    identity = "system"
  }

  identity {
    type = "SystemAssigned"
  }
}

# FRONTEND APP
resource "azurerm_container_app" "frontend_app" {
  name                         = "carambolo-frontend"
  container_app_environment_id = azurerm_container_app_environment.carambolo_env.id
  resource_group_name          = azurerm_resource_group.carambolo_rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.carambolo_acr.login_server}/frontend:latest"
      cpu    = 0.5
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server   = azurerm_container_registry.carambolo_acr.login_server
    identity = "system"
  }

  identity {
    type = "SystemAssigned"
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