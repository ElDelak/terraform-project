resource "aws_sqs_queue" "bascule_data_queue" {
  name                       = "BasculeDataQueue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600 # 4 days
  max_message_size           = 262144
  delay_seconds              = 0
  receive_wait_time_seconds  = 0
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.bascule_data_queue.arn
}