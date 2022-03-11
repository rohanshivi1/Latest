variable "resource_group_name" {
  default     = "infra-common-aa-rg"
  description = "The name of an existing Resource Group"
}

variable "linuxvm_name"{
    default="build-agent-01"
}

# Environment Variable
variable "environment" {
  description = "Environment Variable used as a prefix"
  type = string
  default = "dev"
}
# Azure Resources Location
variable "resource_group_location" {
  description = "Region in which Azure Resources to be created"
  type = string
  default = "ne"  
}

variable "application" {
  description = "The applicatiuon for the tags"
  type = string
  default = "Build Server"  
}

variable "technical_owner" {
  description = "The technical Owner"
  type = string
  default = "Rohan Sharma"  
}

variable "subscription" {
  type        = string
  description = "Our Subscription ID"
  default = ""             
}

variable "tenant" {
  type        = string
  description = "Our Tenant ID"
  default = "" 
}


variable "numberOfWorkerNodes" {
  type        = number
  default     = 1
  description = "The default number of nodes to provision in the scaleset, after joining scaleset as an agent pool, ADO takes over and manages this number."
}

variable "packer_image_name" {
  default = "UbuntuBuildServerImage1.0.1"
}

variable "packer_resource_group_name" {
  default = "image-gallery-rg"
}

variable "deployment_prefix" {
  default     = "build-dev-agents"
  description = "prefix for resource"
}
