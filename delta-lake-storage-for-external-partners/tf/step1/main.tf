terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {
}

resource "azurerm_resource_group" "rg" {
  name = local.rg_name
  location = "West Europe"
  tags = local.tags
}

# ----------------------------------
# Part 1. Storage Account and Back-End Containers Deployment
# ----------------------------------

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

resource "azurerm_storage_container" "sac1" {
  name                  = "log"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "sac2" {
  name                  = "archive"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "sac3" {
  name                  = "ingest"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}