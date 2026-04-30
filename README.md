Part of the [Terrappy framework](https://github.com/guidion-digital/terrappy).

---

Re-usable helper module to create WAF resources for your application modules.

# Usage

See [examples folder](./examples).

Note the differences in Cloudfront and other (regional) usage being the way in which the Web ACLs are attached to the resource you're making them for. See the examples for details.

## Logging

You can optionally enable WAF logging to CloudWatch Logs by setting:

- `enable_logging = true`
- `grafana_promtail_lambda_arn` (optional) to attach a subscription filter for forwarding logs.

When enabled, this module creates a CloudWatch log group named:

`aws-waf-logs-$application_name`
