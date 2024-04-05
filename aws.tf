provider "aws" {
  region = "us-west-2"  # Replace with your desired AWS region
}

# Create an S3 bucket to store the uploaded images
resource "aws_s3_bucket" "image_bucket" {
  bucket = "your-image-bucket-name"  # Replace with your desired bucket name
  acl    = "private"
}

# Create a DynamoDB table to store the extracted information
resource "aws_dynamodb_table" "campaign_info_table" {
  name           = "campaign_info"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "campaign_id"

  attribute {
    name = "campaign_id"
    type = "S"
  }
}

# Create an AWS Lambda function to process the images
resource "aws_lambda_function" "image_processor_lambda" {
  filename         = "lambda_function.zip"  # Replace with your Lambda function package
  function_name    = "process-campaign-retrieval-image"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      S3_BUCKET_NAME    = aws_s3_bucket.image_bucket.id
      DYNAMODB_TABLE    = aws_dynamodb_table.campaign_info_table.name
      # Add any other necessary environment variables
    }
  }
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda-image-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary permissions to the Lambda function role
resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_textract_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonTextractFullAccess"
  role       = aws_iam_role.lambda_role.name
}

# Add more resources as needed (e.g., API Gateway, CloudWatch Events)