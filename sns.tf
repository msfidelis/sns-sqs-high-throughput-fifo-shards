resource "aws_sns_topic" "high_throughput_fifo" {
  name         = "${var.project_name}-high-throughput.fifo"
  display_name = "SNS FIFO High Throughput Topic"

  fifo_topic                  = true
  content_based_deduplication = true
  
  fifo_throughput_scope = "MessageGroup"

  # Delivery policy otimizada para máxima performance
#   delivery_policy = jsonencode({
#     sqs = {
#       defaultHealthyRetryPolicy = {
#         minDelayTarget     = 1    # Delay mínimo reduzido
#         maxDelayTarget     = 2    # Delay máximo reduzido  
#         numRetries         = 2    # Menos retries = mais throughput
#         numMaxDelayRetries = 0
#         numNoDelayRetries  = 0
#         numMinDelayRetries = 0
#       }
#       disableSubscriptionOverrides = false
#     ## Delivery Rate 
#     #   defaultThrottlePolicy = {
#     #     maxReceivesPerSecond = var.max_receives_per_second 
#     #   }
#     }
#   })

  # Configurações de criptografia (opcional mas recomendado)
  kms_master_key_id = aws_kms_key.sns_encryption.key_id

  # Configurações de feedback para monitoramento de performance
  sqs_success_feedback_role_arn    = aws_iam_role.sns_feedback_role[0].arn 
  sqs_success_feedback_sample_rate = var.feedback_sample_rate 
  sqs_failure_feedback_role_arn    = aws_iam_role.sns_feedback_role[0].arn 

  # Archive policy para replay de mensagens (útil para debugging)
  # Removido temporariamente pois requer configuração específica da AWS
  # archive_policy = jsonencode({
  #   messageRetentionPeriod = var.message_retention_days
  # })

  # Rastreamento para observabilidade
  tracing_config = "Active"

  signature_version = 2

  tags = merge(var.common_tags, {
    Name            = "${var.project_name}-high-throughput-fifo"
    Type            = "SNS-FIFO"
    ThroughputScope = "Topic"
    MaxThroughput   = "${var.max_receives_per_second}/sec"
    Purpose         = "SQS-FIFO-Throttling-Bypass"
  })
}

# Subscrições do SNS para as filas SQS (distribuição de carga)
resource "aws_sns_topic_subscription" "sqs_subscriptions" {
  count     = var.num_consumer_queues
  topic_arn = aws_sns_topic.high_throughput_fifo.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.fifo_consumers[count.index].arn

  # Filtro para distribuir mensagens baseado em hash do MessageGroupId
  filter_policy = jsonencode({
    shard = [tostring(count.index)]
  })

  depends_on = [aws_sqs_queue_policy.fifo_consumers_policy]
}
