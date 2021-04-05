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

variable "location" {
  description = "Location of the deployemnt."
  type        = string
  default     = "West Europe"
}

variable "accounts" {
  description = "The list of partner accounts."
  type        = list(string)
  default = [
    "d7339ff0",
    "874e4c60"
  ]
}

locals {

  required_tags = {
    project     = var.project_name,
    environment = var.environment
  }

  tags     = merge(var.resource_tags, local.required_tags)
  rg_name  = "${var.project_name}-${var.environment}-rg"
  sa_name  = "lrsbronze${var.environment}"
  asp_name = "${var.project_name}-${var.environment}-plan"
  fa_name  = "${var.project_name}-${var.environment}-fa"
  apins_name  = "${var.project_name}-${var.environment}-apins"
}