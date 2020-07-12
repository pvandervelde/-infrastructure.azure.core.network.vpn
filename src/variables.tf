#
# ENVIRONMENT
#

variable "category" {
    default = "nwk-vpn"
    description = "The name of the category that all the resources are running in."
}

variable "environment" {
    default = "production"
    description = "The name of the environment that all the resources are running in."
}

#
# LOCAL NETWORK
#

variable "local_network_address_space" {
    description = "The address space of the local network that is connected to the VPN."
    type = string
}

variable "local_network_gateway_address" {
    description = "The IP address of the local network through which the VPN connects."
    type = string
}

variable "local_network_shared_key" {
    description = "The key that is shared between the two ends of the VPN for authorization."
    type = string
}


#
# LOCATION
#

variable "location" {
    default = "australiaeast"
    description = "The full name of the Azure region in which the resources should be created."
}

#
# META
#

variable "meta_source" {
    description = "The commit ID of the current commit from which the plan is being created."
    type = string
}

variable "meta_version" {
    description = "The version of the infrastructure as it is being generated."
    type = string
}

#
# SUBSCRIPTIONS
#

variable "subscription_production" {
    description = "The subscription ID of the production subscription. Used to find the log analytics resources."
    type = string
}

variable "subscription_test" {
    description = "The subscription ID of the test subscription."
    type = string
}

#
# TAGS
#

variable "tags" {
  description = "Tags to apply to all resources created."
  type = map(string)
  default = { }
}
