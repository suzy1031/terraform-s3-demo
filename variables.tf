# variable: コードに埋め込まず、実行時に渡す値。
# 実値は terraform.tfvars に書き、git には載せない（.gitignore 済み）。

# バケット名。S3 では DNS 名と同じく世界で一意である必要がある。
variable "bucket_name" {
  description = "作成する S3 バケット名（世界で一意）"
  type        = string
}

# アクセスを許可する CIDR のリスト。
# /32 は「その IPv4 アドレス 1 つだけ」。例: 203.0.113.10/32
# apply するマシンの公開 IP も必ず含める。含まれないと自分も Deny される。
variable "allowed_cidrs" {
  description = "S3 へのアクセスを許可する CIDR のリスト"
  type        = list(string)
}
