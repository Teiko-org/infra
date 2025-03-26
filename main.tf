provider "azurerm" {
  features {}
}

# Grupo de Recursos
resource "azurerm_resource_group" "carambolo_rg" {
  name     = "carambolo-rg"
  location = "East US"
}

# Plano de Serviço para o Front-End (ajustado para F1 - Free)
resource "azurerm_app_service_plan" "frontend_plan" {
  name                = "frontend-plan"
  location            = azurerm_resource_group.carambolo_rg.location
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Free"
    size = "F1"
  }
}

# Aplicação Front-End com integração ao GitHub
resource "azurerm_app_service" "frontend_app" {
  name                = "frontend-app-carambolo"
  location            = azurerm_resource_group.carambolo_rg.location
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  app_service_plan_id = azurerm_app_service_plan.frontend_plan.id

  site_config {
    linux_fx_version = "NODE|18-lts"
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "18"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Configuração do Deployment via GitHub
resource "azurerm_app_service_source_control" "frontend_deploy" {
  app_id   = azurerm_app_service.frontend_app.id
  repo_url = "https://github.com/Teiko-org/frontend"
  branch   = "main"
  use_manual_integration = false
}

# Plano de Serviço para o Back-End
resource "azurerm_app_service_plan" "backend_plan" {
  name                = "backend-plan"
  location            = azurerm_resource_group.carambolo_rg.location
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Free"
    size = "F1"
  }
}

# Aplicação Back-End
resource "azurerm_app_service" "backend_app" {
  name                = "backend-app-carambolo"
  location            = azurerm_resource_group.carambolo_rg.location
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  app_service_plan_id = azurerm_app_service_plan.backend_plan.id

  site_config {
    linux_fx_version = "NODE|18-lts"
  }

  app_settings = {
    "DB_HOST"     = azurerm_mysql_server.mysql_server.fqdn
    "DB_USER"     = azurerm_mysql_server.mysql_server.administrator_login
    "DB_PASSWORD" = azurerm_mysql_server.mysql_server.administrator_login_password
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }
}

resource "azurerm_app_service_source_control" "backend_deploy" {
  app_id   = azurerm_app_service.frontend_app.id
  repo_url = "https://github.com/Teiko-org/backend"
  branch   = "main"
  use_manual_integration = false
}

# Banco de Dados MySQL
resource "azurerm_mysql_server" "mysql_server" {
  name                = "mysql-server-carambolo"
  location            = azurerm_resource_group.carambolo_rg.location
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  sku_name            = "B_Gen5_1"
  storage_mb          = 5120
  administrator_login = "carambolo"
  administrator_login_password = "caramboloDev123"

  version = "8.0"
}

resource "azurerm_mysql_database" "mysql_db" {
  name                = "carambolo_db"
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  server_name         = azurerm_mysql_server.mysql_server.name
  charset            = "utf8"
  collation          = "utf8_general_ci"
}

# Regras de Firewall para o Banco de Dados
resource "azurerm_mysql_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.carambolo_rg.name
  server_name         = azurerm_mysql_server.mysql_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}
