variable "application_name" {
  description = "Used for tagging and naming"
  type        = string
}

variable "resource_arn" {
  description = "Which AWS resource to attach this WAF to"
  type        = string
  default     = null
}

variable "scope" {
  description = "What kind of resources to use this WAF for"
  type        = string

  default = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Please choose between 'REGIONAL' or 'CLOUDFRONT'"
  }
}

variable "firewall_configuration" {
  description = "Enables WAF if any values are supplied"

  type = object({
    default_ruleset_count_mode = optional(bool, false),
    default_ruleset_block_mode = optional(bool, false),

    ip_rate_based_rule = optional(
      object({
        name          = string,
        priority      = number,
        limit         = number,
        action        = optional(string, "count"),
        response_code = optional(number, 403)
      }),

      null
    ),

    ip_rate_url_based_rules = optional(
      list(object({
        name          = string,
        priority      = number,
        limit         = number,
        action        = optional(string, "count"),
        response_code = optional(number, 403),
        search_string = string,
        # EXACTLY, STARTS_WITH, ENDS_WITH, CONTAINS, or CONTAINS_WORD
        positional_constraint = optional(string, "EXACTLY")
      })),
    [])

    whitelist   = optional(list(string), []),
    blocked_ips = optional(list(string), [])

    filtered_header_rule = optional(object({
      header_types  = list(string),
      priority      = number,
      header_value  = string,
      action        = optional(string, "count"),
      search_string = optional(string, "")
      }),

      { "action" : "block",
        "header_types" : [],
        "header_value" : "",
        "priority" : 100,
        "search_string" : ""
      }
    )

    managed_rules = optional(
      list(object({
        name                 = string,
        priority             = optional(number, null),
        override_action      = optional(string, "count"),
        excluded_rules       = optional(list(string), null),
        rule_action_override = optional(list(string), []),
        vendor_name          = string
      })),

      [
        {
          "excluded_rules" : [],
          "name" : "AWSManagedRulesCommonRuleSet",
          "override_action" : "count",
          "rule_action_override" : [],
          "priority" : 10,
          "vendor_name" : "AWS"
        },
        {
          "excluded_rules" : [],
          "name" : "AWSManagedRulesAmazonIpReputationList",
          "override_action" : "count",
          "rule_action_override" : [],
          "priority" : 20,
          "vendor_name" : "AWS"
        },
        {
          "excluded_rules" : [],
          "name" : "AWSManagedRulesKnownBadInputsRuleSet",
          "override_action" : "count",
          "rule_action_override" : [],
          "priority" : 30,
          "vendor_name" : "AWS"
        },
        {
          "excluded_rules" : [],
          "name" : "AWSManagedRulesSQLiRuleSet",
          "override_action" : "count",
          "rule_action_override" : [],
          "priority" : 40, "vendor_name" : "AWS"
        },
        {
          "excluded_rules" : [],
          "name" : "AWSManagedRulesLinuxRuleSet",
          "override_action" : "count",
          "rule_action_override" : [],
          "priority" : 50,
          "vendor_name" : "AWS"
        },
        {
          "excluded_rules" : [],
          "name" : "AWSManagedRulesUnixRuleSet",
          "override_action" : "count",
          "rule_action_override" : [],
          "priority" : 60, "vendor_name" : "AWS"
        }
    ])
  })

  default = null
}

locals {
  waf_rules = var.firewall_configuration == null ? [""] : concat([
    "whitelist",
    "blocked_ips",
    "AWSManagedRulesCommonRuleSet",
    "AWSManagedRulesAmazonIpReputationList",
    "AWSManagedRulesKnownBadInputsRuleSet",
    "AWSManagedRulesSQLiRuleSet",
    "AWSManagedRulesLinuxRuleSet",
    "AWSManagedRulesUnixRuleSet",
    var.firewall_configuration.ip_rate_based_rule != null ? var.firewall_configuration.ip_rate_based_rule.name : ""
    ],
    var.firewall_configuration.ip_rate_url_based_rules[*].name,
    var.firewall_configuration.filtered_header_rule.header_types
  )

  managed_rules = var.firewall_configuration == null ? null : var.firewall_configuration.default_ruleset_block_mode == true ? [
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesCommonRuleSet",
      "override_action" : "none",
      "rule_action_override" : [],
      "priority" : 10,
      "vendor_name" : "AWS"
    },
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesAmazonIpReputationList",
      "override_action" : "none",
      "rule_action_override" : [],
      "priority" : 20,
      "vendor_name" : "AWS"
    },
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesKnownBadInputsRuleSet",
      "override_action" : "none",
      "rule_action_override" : [],
      "priority" : 30,
      "vendor_name" : "AWS"
    },
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesSQLiRuleSet",
      "override_action" : "none",
      "rule_action_override" : [],
      "priority" : 40, "vendor_name" : "AWS"
    },
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesLinuxRuleSet",
      "override_action" : "none",
      "rule_action_override" : [],
      "priority" : 50,
      "vendor_name" : "AWS"
    },
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesUnixRuleSet",
      "override_action" : "none",
      "rule_action_override" : [],
      "priority" : 60, "vendor_name" : "AWS"
    }
    ] : [
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesCommonRuleSet",
      "override_action" : "count",
      "rule_action_override" : [],
      "priority" : 10,
      "vendor_name" : "AWS"
    },
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesAmazonIpReputationList",
      "override_action" : "count",
      "rule_action_override" : [],
      "priority" : 20,
      "vendor_name" : "AWS"
    },
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesKnownBadInputsRuleSet",
      "override_action" : "count",
      "rule_action_override" : [],
      "priority" : 30,
      "vendor_name" : "AWS"
    },
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesSQLiRuleSet",
      "override_action" : "count",
      "rule_action_override" : [],
      "priority" : 40, "vendor_name" : "AWS"
    },
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesLinuxRuleSet",
      "override_action" : "count",
      "rule_action_override" : [],
      "priority" : 50,
      "vendor_name" : "AWS"
    },
    {
      "excluded_rules" : [],
      "name" : "AWSManagedRulesUnixRuleSet",
      "override_action" : "count",
      "rule_action_override" : [],
      "priority" : 60, "vendor_name" : "AWS"
    }
  ]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)

  default = {}
}
