resource "aws_api_gateway_rest_api" "api" {
  name = var.api_gateway_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.bot_name}.${var.cloudflare_infix}${var.cloudflare_zone_name}"
  validation_method = "DNS"
}

resource "cloudflare_record" "cert_validation_record" {
  zone_id = var.cloudflare_zone_id
  name    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  value   = aws_acm_certificate.cert.domain_validation_options.0.resource_record_value

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [cloudflare_record.cert_validation_record.hostname]
}

resource "aws_api_gateway_domain_name" "domain_name" {
  domain_name              = aws_acm_certificate.cert.domain_name
  regional_certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
  security_policy          = "TLS_1_2"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "cloudflare_record" "bot" {
  zone_id = var.cloudflare_zone_id
  name    = aws_api_gateway_domain_name.domain_name.domain_name
  type    = "CNAME"
  value   = aws_api_gateway_domain_name.domain_name.regional_domain_name
}
