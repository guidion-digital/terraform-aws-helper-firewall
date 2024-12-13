output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = one(module.web_acl).web_acl_id
}
