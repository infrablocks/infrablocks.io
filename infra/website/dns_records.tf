resource "aws_route53_record" "public_website_cdn_alias" {
  count = length(var.addresses)

  zone_id = data.terraform_remote_state.dns_zones.outputs.public_zone_id
  name = var.addresses[count.index]
  type = "A"

  alias {
    name = aws_cloudfront_distribution.website_cdn.domain_name
    zone_id = aws_cloudfront_distribution.website_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "private_website_cdn_alias" {
  count = length(var.addresses)

  zone_id = data.terraform_remote_state.dns_zones.outputs.private_zone_id
  name = var.addresses[count.index]
  type = "A"

  alias {
    name = aws_cloudfront_distribution.website_cdn.domain_name
    zone_id = aws_cloudfront_distribution.website_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
