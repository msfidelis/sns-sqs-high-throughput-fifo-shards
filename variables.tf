variable "aws_region" {
  description = "AWS region para criar os recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto para prefixar recursos"
  type        = string
  default     = "sns-fifo-bypass"
}

variable "max_receives_per_second" {
  description = "Máximo de mensagens por segundo no SNS FIFO (até 300 com fifo_throughput_scope = Topic)"
  type        = number
  default     = 300
  validation {
    condition     = var.max_receives_per_second >= 10 && var.max_receives_per_second <= 300
    error_message = "O máximo de mensagens por segundo deve estar entre 10 e 300 para SNS FIFO."
  }
}

variable "num_consumer_queues" {
  description = "Número de filas SQS FIFO para distribuir a carga (estratégia fan-out)"
  type        = number
  default     = 3
  validation {
    condition     = var.num_consumer_queues >= 1 && var.num_consumer_queues <= 10
    error_message = "O número de filas consumidoras deve estar entre 1 e 10."
  }
}

variable "enable_encryption" {
  description = "Habilitar criptografia KMS nos tópicos SNS"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Habilitar monitoramento CloudWatch e feedback logging"
  type        = bool
  default     = true
}

variable "feedback_sample_rate" {
  description = "Taxa de amostragem para feedback de sucesso (0-100)"
  type        = number
  default     = 100
  validation {
    condition     = var.feedback_sample_rate >= 0 && var.feedback_sample_rate <= 100
    error_message = "A taxa de amostragem deve estar entre 0 e 100."
  }
}

variable "message_retention_days" {
  description = "Dias de retenção para archive policy (replay de mensagens)"
  type        = number
  default     = 7
  validation {
    condition     = var.message_retention_days >= 1 && var.message_retention_days <= 365
    error_message = "A retenção deve estar entre 1 e 365 dias."
  }
}

variable "failure_threshold" {
  description = "Threshold de falhas para alarme do CloudWatch"
  type        = number
  default     = 50
}

variable "common_tags" {
  description = "Tags comuns para todos os recursos"
  type        = map(string)
  default = {
    Project     = "SNS FIFO High Throughput"
    Purpose     = "SQS FIFO Throttling Bypass" 
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}