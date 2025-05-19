
variable "name_data_bucket" {
  description = "ユーザーデータを保存するバケットの名前"
  type        = string
  default     = ""
}

variable "name_logger_bucket" {
  description = "システムの運行に関するログやプロファイル等を保存するバケットの名前"
  type        = string
  default     = ""
}

variable "name_website_bucket" {
  description = "ウェブサイトのスタティックリソースを保存するバケットの名前"
  type        = string
  default     = ""
}

variable "s3_bucket_tags" {
  description = "バケットに付けるタブ"
  type        = map(string)
  default     = {}
}

variable "enable_bucket_object_lock" {
  description = "オブジェクトロックを有効化するフラグ"
  type = object({
    for_data    = bool
    for_logger  = bool
    for_website = bool
  })
}

variable "bucket_owner_id" {
  description = "バケットの所有者のIDを指定"
  type = object({
    for_data    = optional(string)
    for_logger  = optional(string)
    for_website = optional(string)
  })
  default = {}
}

variable "object_lock_rule" {
  description = "バケットのオブジェクトロックのルールを指定"
  type = map(object({
    days             = optional(number)
    years            = optional(number)
    object_lock_mode = string
  }))
}

variable "enable_block_public_access" {
  description = "バケットのパブリックアクセスを禁止"
  type = map(object({
    block_public_acls       = bool
    block_public_policy     = bool
    ignore_public_acls      = bool
    restrict_public_buckets = bool
  }))
}

variable "upload_website_to_s3" {
  description = "ウェブサイトのパスを指定"
  type = object({
    local_path = string
  })
}

variable "upload_server_to_s3" {
  description = "サーバのパスを指定"
  type = object({
    local_path = string
  })
}