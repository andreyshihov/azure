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

data "azurerm_function_app" "conf_fa" {
  name                = local.conf_fa_name
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
      az functionapp deployment source config-zip --resource-group ${data.azurerm_resource_group.rg.name} --name ${data.azurerm_function_app.conf_fa.name} --src ${var.fa_arch_path}
    EOT
  }

  depends_on = [
    data.azurerm_function_app.conf_fa
  ]
}