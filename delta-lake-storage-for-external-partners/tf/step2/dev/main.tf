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

provider "azurerm" {
  features {}
}

provider "azuread" {
}

data "azurerm_subscription" "current" {
}

data "azurerm_resource_group" "rg" {
  name = local.rg_name
}

data "azurerm_storage_account" "sa" {
  name                     = local.sa_name
  resource_group_name      = data.azurerm_resource_group.rg.name
}

# Security Group for Partner 1
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

# Security Group for Partner 2
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

# Now creating directories for both Partners' catalogues
# taken from here: https://markgossa.blogspot.com/2019/04/run-powershell-from-terraform.html
# TODO Partner directories should be a variable array
resource "null_resource" "PowerShellScriptRunAlways" {
    triggers = {
        trigger = "${uuid()}-a"
    }

    # TODO SilentlyContinue is an undesirable workaround. Improve if possible. Managin non-terminating errors: https://devblogs.microsoft.com/powershell/managing-non-terminating-errors/
    provisioner "local-exec" { 
        command = ".'..\\helpers\\directory.add.ps1' -PartnerDirectories d7339ff0,874e4c60 -StorageAccountName ${local.sa_name} -ea SilentlyContinue"
        interpreter = ["PowerShell", "-Command"]
    }

    depends_on = [
      azurerm_storage_container.sac_874e4c60,
      azurerm_storage_container.sac_d7339ff0,
    ]
}