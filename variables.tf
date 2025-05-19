variable "name" {
  description = "プロジェクトの名前"
  type        = string
  nullable    = false
}

variable "region" {
  description = "使用するAWSリージョン"
  type        = string
  # 参照先 https://docs.aws.amazon.com/ja_jp/global-infrastructure/latest/regions/aws-regions.html
  # 東京：ap-northeast-1
  # 大阪：ap-northeast-3
  # California：us-wet-1
  default = "ap-northeast-1"
}

variable "common_tags" {
  description = "すべてのサービスに付けるタグ"
  type        = map(string)
  default     = {}
}