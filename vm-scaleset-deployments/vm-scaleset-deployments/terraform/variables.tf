# Scaleset settings
variable "numberOfWorkerNodes" {
  type        = number
  default     = 2
  description = "The default number of nodes to provision in the scaleset, after joining scaleset as an agent pool, ADO takes over and manages this number."
}

# Network settings
variable "network_resource_group_name" {
  default     = "aaa-rg"
  description = "Name of resource group where vnet and subnets are placed"
}

variable "vnet_name" {
  default     = "vnet-aa"
  description = "VNET to deploy scaleset in"
}

variable "subnet_name" {
  default     = "common-aa-bb"
  description = "Subnet inside of VNET to deploy scaleset in"
}


# Tags and resource defaults
variable "resource_group_name" {
  default     = "common-aa-rg"
  description = "The name of an existing Resource Group"
}

variable "deployment_prefix" {
  default     = "vnet-agents"
  description = "prefix for resource"
}
variable "environment_postfix" {
  default = "aa"
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    "Environment"       = "Development",
    "Technical Owner"   = "Rohan Sharma",
    "Application"       = "ADO Deployment Agents",
    "Created By"        = "Terraform Pipeline",
    "Creation Date"     = "08/10/2021"
  }
}
