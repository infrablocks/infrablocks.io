data "terraform_remote_state" "dns_zones" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key = var.dns_zones_state_key
    region = var.region

    encrypt = var.dns_zones_state_encrypted
  }
}