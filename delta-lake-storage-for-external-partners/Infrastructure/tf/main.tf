##################################################################################
# Main Terraform file - Step 1. Infrastructure
##################################################################################
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }

    azuread = {
      source = "hashicorp/azuread"
      version = "=1.4.0"
    }
  }
}

##################################################################################
# PROVIDERS
##################################################################################
provider "azurerm" {
  features {}
}

provider "azuread" {
}

##################################################################################
# DATA
##################################################################################
data "azurerm_subscription" "current" {
}

data "azuread_service_principal" "tsp" {
  display_name = var.tsp_account
}

##################################################################################
# RESOURCES - Azure Resource Group
##################################################################################
resource "azurerm_resource_group" "rg" {
  name = local.rg_name
  location = var.location
  tags = local.tags
}

##################################################################################
# RESOURCES - Azure Storage Account
##################################################################################
resource "azurerm_storage_account" "sa" {
  name                     = local.sa_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"
  min_tls_version = "TLS1_2"
  is_hns_enabled = true
  tags = local.tags
}

##################################################################################
# RESOURCES - Terraform Service Principle Role Assignment for the Storage Account
##################################################################################
resource "azurerm_role_assignment" "ara_tsp" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.tsp.object_id
}

##################################################################################
# RESOURCES - Archive Container
##################################################################################
resource "azurerm_storage_container" "carch" {
  name                  = "archive"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
  depends_on = [
    azurerm_role_assignment.ara_tsp
  ]
}

##################################################################################
# RESOURCES - Ingest Container
##################################################################################
resource "azurerm_storage_container" "cingst" {
  name                  = "ingest"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"

  depends_on = [
    azurerm_role_assignment.ara_tsp
  ]
}

##################################################################################
# RESOURCES - Service Container
##################################################################################
resource "azurerm_storage_container" "csrv" {
  name                  = "service"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"

  depends_on = [
    azurerm_role_assignment.ara_tsp
  ]
}

##################################################################################
# RESOURCES - Resources for Function App
# NOTE - Free App Service Plan used below isn't suitable for production env.
# TODO - improve App Service Plan configuration for production environment
##################################################################################
# App Service Plan for all Function Apps
resource "azurerm_app_service_plan" "asp" {
  name                = local.asp_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "FunctionApp"
  # Linux Consumption App Service Plan
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
  tags = local.tags
}

# Application Insights for all Function Apps
resource "azurerm_application_insights" "app_insights" {
  name                = local.apins_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "other"
}

# Function App for Infrastructure functions
resource "azurerm_function_app" "infr_fa" {
  name                = local.infr_fa_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.asp.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "1",
    "FUNCTIONS_WORKER_RUNTIME"    = "dotnet",
    "AzureWebJobsDisableHomepage" = "true",
    "SA_NAME"                     = local.sa_name,
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app_insights.instrumentation_key,
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
  }
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  version                    = "~3"
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.tags
}

##################################################################################
# RESOURCES - Fuction App Role Assignments
##################################################################################
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-reader
// Read, write, and delete Azure Storage containers and blobs.
resource "azurerm_role_assignment" "ara_infr_stor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app.infr_fa.identity[0].principal_id
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-queue-data-contributor
// Read, write, and delete Azure Storage queues and queue messages.
resource "azurerm_role_assignment" "ara_infr_queue" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_function_app.infr_fa.identity[0].principal_id
}

##################################################################################
# RESOURCES - Resources for Function App
# NOTE - Free App Service Plan used below isn't suitable for production env.
##################################################################################
# Function App
resource "azurerm_function_app" "conf_fa" {
  name                = local.conf_fa_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.asp.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "1",
    "FUNCTIONS_WORKER_RUNTIME"    = "dotnet",
    "AzureWebJobsDisableHomepage" = "true",
    "SA_NAME"                     = local.sa_name,
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app_insights.instrumentation_key,
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
  }
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  version                    = "~3"
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.tags
}

##################################################################################
# RESOURCES - Fuction App Role Assignments
##################################################################################
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-reader
// Read, write, and delete Azure Storage containers and blobs.
resource "azurerm_role_assignment" "ara_conf_stor" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app.conf_fa.identity[0].principal_id
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-queue-data-contributor
// Read, write, and delete Azure Storage queues and queue messages.
resource "azurerm_role_assignment" "ara_conf_queue" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_function_app.conf_fa.identity[0].principal_id
}

##################################################################################
# RESOURCES - Publish, Compress and Deploy Function App
##################################################################################
resource "null_resource" "fa_pubanddep" {
  triggers = {
    trigger = var.infr_fa_version
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = <<EOT
      # publish function app
      dotnet publish ../func/func.csproj -o ../func/publish -c Release
      
      # compress function app artefacts
      $compress = @{
        Path = "../func/publish/*"
        CompressionLevel = "Fastest"
        DestinationPath = "${var.fa_arch_path}"
      }
      Compress-Archive @compress -Force

      # deploy zipped function app
      az functionapp deployment source config-zip --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_function_app.infr_fa.name} --src ${var.fa_arch_path}
    EOT
  }

  depends_on = [
    azurerm_function_app.infr_fa
  ]
}
