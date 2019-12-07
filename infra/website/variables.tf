variable "region" {}

variable "deployment_identifier" {}

variable "bucket_name" {}
variable "bucket_secret" {}

variable "addresses" {
  type = list(string)
}

variable "certificate_domain_name" {}

variable "state_bucket" {}
variable "dns_zones_state_key" {}
variable "dns_zones_state_encrypted" {}
