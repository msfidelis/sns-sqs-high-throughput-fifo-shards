# IAM Role para feedback do SNS (se habilitado)
resource "aws_iam_role" "sns_feedback_role" {
  count = var.enable_monitoring ? 1 : 0

  name = "${var.project_name}-sns-feedback-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "sns_feedback_policy" {
  count = var.enable_monitoring ? 1 : 0

  name = "${var.project_name}-sns-feedback-policy"
  role = aws_iam_role.sns_feedback_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}
