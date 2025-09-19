resource "aws_cloudwatch_dashboard" "fifo_performance" {
  count = var.enable_monitoring ? 1 : 0

  dashboard_name = "${var.project_name}-fifo-performance"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/SNS", "NumberOfMessagesPublished", "TopicName", aws_sns_topic.high_throughput_fifo.name],
            [".", "NumberOfNotificationsDelivered", ".", "."],
            [".", "NumberOfNotificationsFailed", ".", "."]
          ]
          stat = "Sum"
          view   = "timeSeries"
          region = var.aws_region
          title  = "SNS FIFO - Messages Per Second"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = concat([
            for i in range(var.num_consumer_queues) : [
              "AWS/SQS", "NumberOfMessagesSent", "QueueName", aws_sqs_queue.fifo_consumers[i].name
            ]
          ])
          view   = "timeSeries"
          region = var.aws_region
          title  = "SQS Consumer Queues - Distribution"
          period = 60
          stat = "Sum"
          stacked              = true
        }
      }
    ]
  })
}

# Alarm para monitorar throttling
resource "aws_cloudwatch_metric_alarm" "high_failure_rate" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-high-failure-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfNotificationsFailed"
  namespace           = "AWS/SNS"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.failure_threshold
  alarm_description   = "High failure rate detected - possible throttling"

  dimensions = {
    TopicName = aws_sns_topic.high_throughput_fifo.name
  }

  tags = var.common_tags
}
