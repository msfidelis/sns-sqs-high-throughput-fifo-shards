# KMS Key para criptografia (se habilitado)
resource "aws_kms_key" "sns_encryption" {
  description             = "KMS key for SNS FIFO high throughput encryption"
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-sns-kms"
  })
}

resource "aws_kms_alias" "sns_encryption_alias" {
  name          = "alias/${var.project_name}-sns-fifo"
  target_key_id = aws_kms_key.sns_encryption.key_id
}
