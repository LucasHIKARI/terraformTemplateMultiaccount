variable "web_acl" {
  description = "Creates a WAFv2 Web ACL resource"
  type = object({
    create = bool
    name   = optional(string)
    tags   = optional(map(string), {})
  })
  default = {
    create = false
  }
}

variable "block_ip_set" {
  description = "To block a group of IP addresses"
  type = object({
    create    = bool
    name      = optional(string)
    addresses = optional(set(string))
    tags      = optional(map(string), {})
  })
  default = {
    create = false
  }
}
