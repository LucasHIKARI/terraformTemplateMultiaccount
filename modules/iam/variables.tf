variable "iam_role" {
  description = "Create IAM role"
  type = list(object({
    create                         = bool
    assume_role_policy             = string
    name                           = optional(string)
    name_prefix                    = optional(string)
    description                    = optional(string)
    is_force_detach_policies       = optional(bool)
    max_session_duration_in_second = optional(number, 7200)
    path                           = optional(string)
    permissions_boundary           = optional(string)
    tags                           = optional(map(string), {})
  }))
  default = []
}

variable "iam_policy" {
  description = "Create IAM policy"
  type = list(object({
    create      = bool
    description = optional(string)
    name        = optional(string)
    name_prefix = optional(string)
    path        = optional(string)
    policy      = string
    tags        = optional(map(string), {})
  }))
  default = []
}

variable "iam_attach_policy_to_role" {
  description = "Attach policy to role"
  type = list(object({
    create     = bool
    role_idx   = number
    policy_idx = optional(number)
    policy_arn = optional(string)
  }))
  default = []
}

variable "specify_role_to_service" {
  description = "Specify role to service"
  type = list(object({
    create      = bool
    name        = optional(string)
    name_prefix = optional(string)
    path        = optional(string)
    role_idx    = number
    tags        = optional(map(string), {})
  }))
  default = []
}