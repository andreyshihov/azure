##################################################################################
# MAIN VARIABLE - This file MUST BE the same in Infrastructure and Configuration
##################################################################################
variable "project_name" {
  description = "Name of the project."
  type        = string
  default     = "ext-gtw"
}

variable "tsp_account" {
  description = "Name of the Terraform service principal account name."
  type        = string
  default     = "TerraformPrincipal"
}

variable "environment" {
  description = "Name of the environment."
  type        = string
  default     = "dev"
}

variable "resource_tags" {
  description = "Tags to set for all resources."
  type        = map(string)
  default     = {}
}

variable "fa_arch_path" {
  description = "Path to the archive function app."
  type        = string
  default     = "./deploy/fa.zip"
}

variable "infr_fa_version" {
  description = "Version of the Infrastructure Function App."
  type        = string
  default     = "0.0.7"
}

variable "conf_fa_version" {
  description = "Version of the Infrastructure Function App."
  type        = string
  default     = "0.0.2"
}

variable "location" {
  description = "Location of the deployemnt."
  type        = string
  default     = "West Europe"
}

locals {

  required_tags = {
    project     = var.project_name,
    environment = var.environment
  }

  tags     = merge(var.resource_tags, local.required_tags)
  rg_name  = "${var.project_name}-${var.environment}-rg"
  sa_name  = replace("${var.project_name}${var.environment}dlg2", "-", "")
  asp_name = "${var.project_name}-${var.environment}-plan"
  infr_fa_name  = "${var.project_name}-${var.environment}-infr-fa"
  conf_fa_name  = "${var.project_name}-${var.environment}-conf-fa"
  apins_name  = "${var.project_name}-${var.environment}-apins"
}