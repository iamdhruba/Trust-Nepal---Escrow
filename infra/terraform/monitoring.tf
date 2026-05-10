# CloudWatch for Metrics and Logs
resource "aws_cloudwatch_metric_alarm" "payment_failure_rate" {
  alarm_name          = "${var.project_name}-payment-failure-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "nepaltrust_payment_success_rate"
  namespace           = "NepalTrust"
  period              = "300"
  statistic           = "Average"
  threshold           = "0.98"
  alarm_description   = "Alert when payment success rate drops below 98% (2% failure rate)"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-payment-failure-rate-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.project_name}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "nepaltrust_api_request_duration_ms"
  namespace           = "NepalTrust"
  period              = "600"
  statistic           = "p95"
  threshold           = "500"
  alarm_description   = "Alert when API P95 latency exceeds 500ms"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-api-latency-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "job_dlq_depth" {
  alarm_name          = "${var.project_name}-job-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "nepaltrust_job_queue_depth"
  namespace           = "NepalTrust"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert when dead-letter queue has items"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    queue = "dlq"
  }

  tags = {
    Name = "${var.project_name}-job-dlq-alarm"
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name = "${var.project_name}-alerts-topic"
  }
}

resource "aws_sns_topic_subscription" "pagerduty" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = var.pagerduty_endpoint
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-main"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["NepalTrust", "nepaltrust_vault_state_total", { state = "INITIATED" }],
            [".", ".", { state = "FUNDED" }],
            [".", ".", { state = "SHIPPED" }],
            [".", ".", { state = "DELIVERED" }],
            [".", ".", { state = "COMPLETED" }],
            [".", ".", { state = "REFUNDED" }],
            [".", ".", { state = "DISPUTED" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Vault State Distribution"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["NepalTrust", "nepaltrust_payment_success_rate", { provider = "ESEWA" }],
            [".", ".", { provider = "KHALTI" }],
            [".", ".", { provider = "CONNECTIPS" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Payment Success Rate by Provider"
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["NepalTrust", "nepaltrust_api_request_duration_ms"]
          ]
          period = 300
          stat   = "p95"
          region = var.aws_region
          title  = "API Latency (P95)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["NepalTrust", "nepaltrust_job_queue_depth"]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "Job Queue Depth"
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 12
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["NepalTrust", "nepaltrust_dispute_open_total"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Open Disputes"
        }
      }
    ]
  })
}
