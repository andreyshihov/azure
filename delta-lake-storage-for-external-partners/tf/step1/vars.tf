variable "project_name" {
  description = "Name of the project."
  type        = string
  default     = "ext-data-files-gtw"
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
  default     = { }
}

locals {
  required_tags = {
    project     = var.project_name,
    environment = var.environment
  }
  tags = merge(var.resource_tags, local.required_tags)
  rg_name = "rg-storage-${var.environment}"
  sa_name = "lrsbronze${var.environment}"
}