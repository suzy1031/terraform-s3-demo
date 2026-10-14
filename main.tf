# provider: どのクラウドの、どのリージョンに対して操作するかを指定する。
# ap-northeast-1 は東京リージョン。
provider "aws" {
  region = "ap-northeast-1"
}

# resource: AWS 上に実際に作るものの定義。
# aws_s3_bucket がオブジェクトストレージ（ファイル置き場）の入れ物。
# バケット名は全 AWS アカウントで世界一意。同じ名前は誰かが使っていると作れない。
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

# Block Public Access: インターネットから誰でも読める設定を、バケット側で禁止する。
# 今回の IP 制限は「拒否」なので、公開 Allow ではない。この設定と両立する。
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SSE-S3 (AES-256): 保存時に AWS が暗号化する。KMS キーは使わない標準の暗号化。
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# バケットポリシー: 許可 CIDR 以外からの s3:* を Deny する。
# Principal "*" でも Effect が Deny なので「誰でも読める」公開設定にはならない。
# 許可 IP からでも、AWS の IAM 認証（ユーザー / ロール）は別途必要。
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  # 公開ブロックの適用後にポリシーを付ける（作成順の競合を避ける）
  depends_on = [aws_s3_bucket_public_access_block.this]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyAccessNotFromAllowedIPs"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*",
        ]
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = var.allowed_cidrs
          }
        }
      }
    ]
  })
}
