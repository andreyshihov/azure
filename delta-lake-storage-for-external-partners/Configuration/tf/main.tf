##################################################################################
# Main Terraform file - Step 2. Configuration
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
  name                   = "${var.accounts[count.index]}-init-container"
  storage_account_name   = data.azurerm_storage_account.sa.name
  storage_container_name = "service"
  type                   = "Block"
  count                  = length(var.accounts)
}

##################################################################################
# RESOURCES - Resources for Function App
# NOTE - Free App Service Plan used below isn't suitable for production env.
##################################################################################
data "azurerm_app_service_plan" "asp" {
  name                = local.asp_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Application Insights
data "azurerm_application_insights" "app_insights" {
  name                = local.apins_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Function App
resource "azurerm_function_app" "conf_fa" {
  name                = local.conf_fa_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  app_service_plan_id = data.azurerm_app_service_plan.asp.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "1",
    "FUNCTIONS_WORKER_RUNTIME"    = "dotnet",
    "AzureWebJobsDisableHomepage" = "true",
    "SA_NAME"                     = local.sa_name,
    "APPINSIGHTS_INSTRUMENTATIONKEY" = data.azurerm_application_insights.app_insights.instrumentation_key,
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
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
  principal_id         = azurerm_function_app.conf_fa.identity[0].principal_id
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-queue-data-contributor
// Read, write, and delete Azure Storage queues and queue messages.
resource "azurerm_role_assignment" "functionToStorage2" {
  scope                = data.azurerm_storage_account.sa.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_function_app.conf_fa.identity[0].principal_id
}

##################################################################################
# RESOURCES - Publish, Compress and Deploy Function App
##################################################################################
resource "null_resource" "fa_pubanddep" {
  triggers = {
    trigger = var.conf_fa_version
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
      az functionapp deployment source config-zip --resource-group ${data.azurerm_resource_group.rg.name} --name ${azurerm_function_app.conf_fa.name} --src ${var.fa_arch_path}
    EOT
  }

  depends_on = [
    azurerm_function_app.conf_fa
  ]
}