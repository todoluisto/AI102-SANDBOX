variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "project" {
  description = "Project prefix used in resource naming"
  type        = string
  default     = "ai102"
}

variable "region_short" {
  description = "Short region code for naming convention"
  type        = string
  default     = "eus"
}
