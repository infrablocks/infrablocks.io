provider "aws" {
  region = var.region
}

provider "aws" {
  alias = "cdn_region"
  region = "us-east-1"
}
