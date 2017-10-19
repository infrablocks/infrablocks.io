data "aws_acm_certificate" "website" {
  domain = "${var.certificate_domain_name}"
  statuses = ["ISSUED"]
}
