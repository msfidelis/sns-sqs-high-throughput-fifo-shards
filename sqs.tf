# Cria múltiplas filas SQS FIFO para distribuir a carga
resource "aws_sqs_queue" "fifo_consumers" {
  count = var.num_consumer_queues

  name                        = "${var.project_name}-consumer-${count.index}.fifo"
  fifo_queue                  = true
  content_based_deduplication = true

  # Configurações otimizadas para alta performance
  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600  # 14 dias
  receive_wait_time_seconds  = 20       # Long polling
  
  # Configurações de throughput
  deduplication_scope   = "messageGroup"        # Permite maior paralelização
  fifo_throughput_limit = "perMessageGroupId"   # Permite 3000 msg/s por MessageGroupId

  tags = merge(var.common_tags, {
    Name     = "${var.project_name}-consumer-${count.index}"
    Type     = "SQS-FIFO-Consumer"
    Consumer = "Consumer-${count.index}"
  })
}


resource "aws_sqs_queue_policy" "fifo_consumers_policy" {
  count     = var.num_consumer_queues
  queue_url = aws_sqs_queue.fifo_consumers[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.fifo_consumers[count.index].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.high_throughput_fifo.arn
          }
        }
      }
    ]
  })
}