resource "aws_dynamodb_table" "data_base" {
  name           = "basculedata"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "idBascule"
  range_key      = "timestamp"
  read_capacity  = 0
  write_capacity = 0

  attribute {
    name = "idBascule"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }
}

output "dynamodb_arn" {
  value = aws_dynamodb_table.data_base.arn
}