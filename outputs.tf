# output "sns_fifo_topic_arn" {
#   description = "ARN do tópico SNS FIFO com alta performance"
#   value       = aws_sns_topic.high_throughput_fifo.arn
# }

# output "sns_fifo_topic_name" {
#   description = "Nome do tópico SNS FIFO"
#   value       = aws_sns_topic.high_throughput_fifo.name
# }

# output "sns_fifo_topic_url" {
#   description = "URL do tópico SNS FIFO para publicação"
#   value       = "https://sns.${var.aws_region}.amazonaws.com/${data.aws_caller_identity.current.account_id}:${aws_sns_topic.high_throughput_fifo.name}"
# }

# output "max_throughput_configured" {
#   description = "Máximo throughput configurado (mensagens/segundo)"
#   value       = "${var.max_receives_per_second} msg/s"
# }

# output "fifo_throughput_scope" {
#   description = "Escopo de throughput FIFO configurado"
#   value       = "Topic (permite até 300 msg/s vs 10 msg/s padrão)"
# }

# output "consumer_queue_arns" {
#   description = "ARNs das filas SQS FIFO consumidoras"
#   value       = aws_sqs_queue.fifo_consumers[*].arn
# }

# output "consumer_queue_names" {
#   description = "Nomes das filas SQS FIFO consumidoras"
#   value       = aws_sqs_queue.fifo_consumers[*].name
# }

# output "consumer_queue_urls" {
#   description = "URLs das filas SQS FIFO consumidoras"
#   value       = aws_sqs_queue.fifo_consumers[*].url
# }

# output "kms_key_id" {
#   description = "ID da chave KMS para criptografia (se habilitada)"
#   value       = var.enable_encryption ? aws_kms_key.sns_encryption[0].key_id : null
# }

# output "cloudwatch_dashboard_url" {
#   description = "URL do dashboard CloudWatch para monitoramento"
#   value       = var.enable_monitoring ? "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.fifo_performance[0].dashboard_name}" : null
# }

# output "example_publish_command" {
#   description = "Exemplo de comando para publicar mensagem via AWS CLI"
#   value = <<-EOT
# aws sns publish \
#   --topic-arn "${aws_sns_topic.high_throughput_fifo.arn}" \
#   --message '{"data": "exemplo", "timestamp": "2025-09-17T10:00:00Z"}' \
#   --message-group-id "group-1" \
#   --message-deduplication-id "unique-id-$(date +%s%N)" \
#   --message-attributes '{"shard":{"DataType":"String","StringValue":"1"}}'
# EOT
# }

# output "architecture_summary" {
#   description = "Resumo da arquitetura implementada"
#   value = {
#     strategy         = "SNS FIFO Fan-Out para múltiplas SQS FIFO"
#     sns_throughput   = "${var.max_receives_per_second} msg/s"
#     num_consumers    = var.num_consumer_queues
#     total_sqs_capacity = "${var.num_consumer_queues * 3000} msg/s (3000 msg/s por fila SQS FIFO)"
#     throttling_bypass = "SNS distribui carga entre múltiplas filas SQS"
#   }
# }

# # Data sources necessários
# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}