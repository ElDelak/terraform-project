# Event source from SQS
resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.bascule_data_queue.arn
  enabled          = true
  function_name    = "importData"
  batch_size       = 1
}