variable "region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "us-east-2"
}

variable "name_prefix" {
  description = "The prefix to use when naming all resources"
  type        = string
  default     = "example"
  validation {
    condition     = length(var.name_prefix) <= 20
    error_message = "The name prefix cannot be more than 20 characters"
  }
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.200.0.0/16"
}

variable "instance_type" {
  type        = string
  description = "Instance type to use for Bastion"
  default     = "m6i.4xlarge"
}

variable "use_unique_names" {
  type        = bool
  description = "Whether to use unique names for all resources"
  default     = true
}

variable "zarf_version" {
  type        = string
  description = "Which version of Zarf to install on the server"
  default     = "v0.31.3"
}
