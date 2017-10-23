data "aws_vpc" "default" {
  default = true
}

module "dns_zones" {
  source = "git@github.com:infrablocks/terraform-aws-dns-zones.git?ref=0.1.3//src"

  region = "${var.region}"

  domain_name = "${var.domain_name}"
  private_domain_name = "${var.domain_name}"

  private_zone_vpc_id = "${data.aws_vpc.default.id}"
  private_zone_vpc_region = "${var.region}"
}

resource "aws_route53_record" "zoho_verify_cname" {
  name = "zb15086739.${var.domain_name}"
  zone_id = "${module.dns_zones.public_zone_id}"
  type = "CNAME"
  ttl = "60"

  records = ["zmverify.zoho.eu"]
}

resource "aws_route53_record" "zoho_verify_txt" {
  name = "${var.domain_name}"
  zone_id = "${module.dns_zones.public_zone_id}"
  type = "TXT"
  ttl = "60"

  records = ["zoho-verification=zb15086739.zmverify.zoho.eu"]
}

resource "aws_route53_record" "zoho_mail_mx" {
  zone_id = "${module.dns_zones.public_zone_id}"
  name = "${var.domain_name}"
  type = "MX"
  ttl = "3600"

  records = [
    "10 mx.zoho.eu.",
    "20 mx2.zoho.eu.",
    "50 mx3.zoho.eu."
  ]
}
