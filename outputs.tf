# output: apply 後にターミナルへ出す値。コンソールで探すときの手がかりになる。

output "bucket_name" {
  description = "作成した S3 バケット名"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "作成した S3 バケットの ARN（Amazon Resource Name）"
  value       = aws_s3_bucket.this.arn
}
