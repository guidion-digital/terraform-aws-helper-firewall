module "firewall" {
  source = "../../"

  scope            = "REGIONAL"
  application_name = "app-x-frontend"
  resource_arn     = "arn:aws:apigateway:eu-central-1::/restapis/000000000000/stages/dev"

  firewall_configuration = {
    default_ruleset_block_mode = true

    blocked_ips = ["170.79.37.88/32"],

    ip_rate_based_rule = {
      name     = "100_per_500_seconds",
      priority = 80,
      limit    = 100,
      action   = "block"
    }

    ip_rate_url_based_rules = [
      {
        name          = "100_dings_per_500_seconds",
        priority      = 90,
        limit         = 100
        search_string = "/ding"
      }
    ]
  }
}
