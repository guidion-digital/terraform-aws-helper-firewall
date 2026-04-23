resource "aws_wafv2_ip_set" "blacklist" {
  count = var.firewall_configuration != null ? 1 : 0

  name               = "${var.application_name}-blocked"
  description        = "Set of blocked IPs for ${var.application_name}"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.firewall_configuration.blocked_ips
  tags               = var.tags
}

resource "aws_wafv2_ip_set" "whitelist" {
  count = var.firewall_configuration != null ? 1 : 0

  name               = "${var.application_name}-whitelist"
  description        = "Set of whitelisted IPs for ${var.application_name}"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.firewall_configuration.whitelist
  tags               = var.tags
}

resource "aws_cloudwatch_log_group" "waf" {
  count = var.firewall_configuration != null && var.enable_logging ? 1 : 0

  name = "aws-waf-logs-${var.application_name}"
  tags = var.tags
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_promtail_logfilter" {
  count = var.firewall_configuration != null && var.enable_logging && var.grafana_promtail_lambda_arn != null ? 1 : 0

  name            = "lambda_promtail_logfilter_${var.application_name}"
  log_group_name  = aws_cloudwatch_log_group.waf[0].name
  destination_arn = var.grafana_promtail_lambda_arn
  filter_pattern  = ""
}

module "web_acl" {
  count = var.firewall_configuration != null ? 1 : 0

  # https://registry.terraform.io/modules/trussworks/wafv2/aws/latest
  source  = "trussworks/wafv2/aws"
  version = "4.0.0"

  name                    = "${var.application_name}-web-acl"
  scope                   = var.scope
  managed_rules           = local.managed_rules
  ip_rate_based_rule      = var.firewall_configuration.ip_rate_based_rule
  ip_rate_url_based_rules = var.firewall_configuration.ip_rate_url_based_rules
  filtered_header_rule    = var.firewall_configuration.filtered_header_rule
  enable_logging          = var.enable_logging
  log_destination_arns    = var.enable_logging ? aws_cloudwatch_log_group.waf[*].arn : []

  ip_sets_rule = [
    {
      name       = "whitelist",
      priority   = 1,
      ip_set_arn = one(aws_wafv2_ip_set.whitelist).arn,
      action     = "allow"
    },
    {
      name          = "blocked_ips",
      priority      = 5,
      ip_set_arn    = one(aws_wafv2_ip_set.blacklist).arn,
      action        = "block",
      response_code = 403
    }
  ]

  tags = var.tags
}

resource "aws_wafv2_web_acl_association" "this" {
  count = var.scope != "CLOUDFRONT" ? 1 : 0

  resource_arn = var.resource_arn
  web_acl_arn  = one(module.web_acl).web_acl_id
}
