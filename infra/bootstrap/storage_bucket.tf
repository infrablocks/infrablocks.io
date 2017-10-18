module "storage_bucket" {
  source = "git@github.com:infrablocks/terraform-aws-encrypted-bucket.git?reg=0.1.4//src"

  region = "${var.region}"

  bucket_name = "${var.storage_bucket_name}"

  tags = {
    DeploymentIdentifier = "${var.deployment_identifier}"
  }
}