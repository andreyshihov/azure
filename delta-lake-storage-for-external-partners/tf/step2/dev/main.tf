##################################################################################
# Main Terraform file 
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

data "azurerm_resource_group" "rg" {
  name = local.rg_name
}

data "azurerm_storage_account" "sa" {
  name                     = local.sa_name
  resource_group_name      = data.azurerm_resource_group.rg.name
}

##################################################################################
# RESOURCES - Security Group for Partner 1 (d7339ff0)
##################################################################################
# TODO make a module with below resources
resource "azuread_group" "partner1" {
  display_name     = "Partner 1 (d7339ff0)"
  prevent_duplicate_names = true
}

resource "azurerm_storage_container" "sac_d7339ff0" {
  name                  = "d7339ff0"
  storage_account_name  = data.azurerm_storage_account.sa.name
}

resource "azurerm_role_assignment" "ra_d7339ff0" {
  scope                = azurerm_storage_container.sac_d7339ff0.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_group.partner1.object_id
}

# Experimental Security Group on Subscription Level to demonstrate how it affects view in Azure Storage Explorer
resource "azurerm_role_assignment" "arasubs" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.partner1.object_id
}

##################################################################################
# RESOURCES - Security Group for Partner 2 (874e4c60)
##################################################################################
# TODO make a module with below resources
resource "azuread_group" "partner2" {
  display_name     = "Partner 2 (874e4c60)"
  prevent_duplicate_names = true
}

resource "azurerm_storage_container" "sac_874e4c60" {
  name                  = "874e4c60"
  storage_account_name  = data.azurerm_storage_account.sa.name
}

resource "azurerm_role_assignment" "ra_874e4c60" {
  scope                = azurerm_storage_container.sac_874e4c60.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_group.partner2.object_id
}

##################################################################################
# RESOURCES - Creates directories for Partners' containers
# taken from here: https://markgossa.blogspot.com/2019/04/run-powershell-from-terraform.html
##################################################################################
# TODO Partner directories should be a variable array
resource "null_resource" "ps_run_always" {
    triggers = {
        trigger = "${uuid()}-a"
    }

    provisioner "local-exec" { 
        command = ".'..\\helpers\\directory.add.ps1' -PartnerDirectories d7339ff0,874e4c60 -StorageAccountName ${local.sa_name}"
        interpreter = ["PowerShell", "-Command"]
    }

    depends_on = [
      azurerm_storage_container.sac_874e4c60,
      azurerm_storage_container.sac_d7339ff0
    ]
}

##################################################################################
# RESOURCES - Resources for Function App
##################################################################################
# App Service Plan for Function App
resource "azurerm_app_service_plan" "asp" {
    name = local.asp_name
    resource_group_name = data.azurerm_resource_group.rg.name
    location = data.azurerm_resource_group.rg.location
    kind = "FunctionApp"
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

# Deploye Function App 
resource "azurerm_function_app" "fa" {
  name                       = local.fa_name
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  app_service_plan_id        = azurerm_app_service_plan.asp.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "1",
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet",
    "AzureWebJobsDisableHomepage" = "true",
    "SA_NAME" = local.sa_name
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
 resource "null_resource" "fa_publish" {
  provisioner "local-exec" {
    command = local.publish_code_command
  }
  depends_on = [
    local.publish_code_command
  ]
  triggers = {
    input_json = filemd5("./deploy/fad.zip")
    publish_code_command = local.publish_code_command
  }
}