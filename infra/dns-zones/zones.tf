data "aws_vpc" "default" {
  default = true
}

module "dns_zones" {
  source = "infrablocks/dns-zones/aws"
  version = "0.5.0"

  domain_name = var.domain_name
  private_domain_name = var.domain_name

  private_zone_vpc_id = data.aws_vpc.default.id
  private_zone_vpc_region = var.region
}

resource "aws_route53_record" "gsuite_txt" {
  name = var.domain_name
  zone_id = module.dns_zones.public_zone_id
  type = "TXT"
  ttl = "60"

  records = [
    "google-site-verification=t3A9VSj05CawruipZrc7Q9hTi2CE3I7mUe8cGoDHssw",
    "v=spf1 include:_spf.google.com ~all"
  ]
}

resource "aws_route53_record" "gsuite_mx" {
  zone_id = module.dns_zones.public_zone_id
  name = var.domain_name
  type = "MX"
  ttl = "3600"

  records = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
    "10 alt4.aspmx.l.google.com."
  ]
}
