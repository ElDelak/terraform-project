# IAM Policy for SQS Access
resource "aws_iam_policy" "sqs_access_policy" {
  name        = "sqs_access_policy"
  description = "IAM policy for SQS access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Effect   = "Allow",
        Resource = aws_sqs_queue.bascule_data_queue.arn
      }
    ]
  })
}

# IAM Policy for DynamoDB Access
resource "aws_iam_policy" "dynamodb_access_policy" {
  name        = "dynamodb_access_policy"
  description = "IAM policy for DynamoDB access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Query"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.data_base.arn
      }
    ]
  })
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


# Attach SQS access policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "sqs_access_attachment" {
  policy_arn = aws_iam_policy.sqs_access_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

# Attach DynamoDB access policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "dynamodb_access_attachment" {
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

# Attach the AWSLambdaBasicExecutionRole managed policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_exec_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

# Lambda Function
resource "aws_lambda_function" "importData" {
  function_name    = "importData"
  handler          = "importData.lambda_handler"
  runtime          = "python3.8"
  timeout          = 10
  memory_size      = 128
  role             = aws_iam_role.lambda_exec.arn
  filename         = "./tools/lambda_function.zip"
  source_code_hash = filebase64sha256("./tools/lambda_function.zip")

  environment {
    variables = {
      table_name = "basculedata",
      b2         = "5",
      b3         = "5",
      b4         = "7",
      b5         = "7",
      b6         = "7",
      b7         = "5",
      b8         = "5",
      b9         = "5",
      b10        = "5",
      b11        = "5",
      b12        = "6",
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_exec_attachment
  ]
}

/*
data "archive_file" "lambda_function" {
  type        = "zip"
  output_path = "./tools/lambda_function.zip"
  source_dir  = "./tools"
}
*/

output "lambdaImportData" {
  value = aws_lambda_function.importData.arn

}