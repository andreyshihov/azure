##################################################################################
# Main Terraform file 
##################################################################################
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
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

data "azurerm_resource_group" "rg" {
  name = local.rg_name
}

data "azurerm_storage_account" "sa" {
  name                = local.sa_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

##################################################################################
# RESOURCES - Security Group for Partner N (X)
##################################################################################
# TODO make a module with below resources
resource "azuread_group" "partner" {
  display_name            = "Partner ${count.index+1} (${var.accounts[count.index]})"
  prevent_duplicate_names = true
  count                   = length(var.accounts)
}

resource "azurerm_storage_container" "sac" {
  name                 = var.accounts[count.index]
  storage_account_name = data.azurerm_storage_account.sa.name
  count                = length(var.accounts)
}

resource "azurerm_role_assignment" "ra" {
  scope                = azurerm_storage_container.sac[count.index].resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_group.partner[count.index].object_id
  count                = length(var.accounts)
}

resource "azurerm_storage_blob" "init" {
  name                   = "init-container.json"
  storage_account_name   = data.azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.sac[count.index].name
  type                   = "Block"
  source                 = "init-container.json"
  count                  = length(var.accounts)
}

##################################################################################
# RESOURCES - Resources for Function App
##################################################################################
# App Service Plan for Function App
resource "azurerm_app_service_plan" "asp" {
  name                = local.asp_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  kind                = "FunctionApp"
  # Linux Consumption App Service Plan
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
  tags = local.tags
}

# Function App Archived
data "archive_file" "faa" {
  type        = "zip"
  source_dir  = "../../../func/publish"
  output_path = "./deploy/fad.zip"
}

resource "azurerm_application_insights" "application_insights" {
  name                = local.apins_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "other"
}

# Deploye Function App 
resource "azurerm_function_app" "fa" {
  name                = local.fa_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.asp.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "1",
    "FUNCTIONS_WORKER_RUNTIME"    = "dotnet",
    "AzureWebJobsDisableHomepage" = "true",
    "SA_NAME"                     = local.sa_name,
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.application_insights.instrumentation_key
  }
  storage_account_name       = data.azurerm_storage_account.sa.name
  storage_account_access_key = data.azurerm_storage_account.sa.primary_access_key
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
resource "azurerm_role_assignment" "functionToStorage1" {
  scope                = data.azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app.fa.identity[0].principal_id
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-queue-data-contributor
// Read, write, and delete Azure Storage queues and queue messages.
resource "azurerm_role_assignment" "functionToStorage2" {
  scope                = data.azurerm_storage_account.sa.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_function_app.fa.identity[0].principal_id
}

##################################################################################
# RESOURCES - Publish Function App
##################################################################################
locals {
  publish_code_command = "az functionapp deployment source config-zip --resource-group ${data.azurerm_resource_group.rg.name} --name ${azurerm_function_app.fa.name} --src ./deploy/fad.zip"
}

# Publish Function App
resource "null_resource" "fa_pub" {
  provisioner "local-exec" {
    command = local.publish_code_command
  }
  depends_on = [
    local.publish_code_command
  ]
  triggers = {
    input_json           = filemd5("./deploy/fad.zip")
    publish_code_command = local.publish_code_command
  }
}