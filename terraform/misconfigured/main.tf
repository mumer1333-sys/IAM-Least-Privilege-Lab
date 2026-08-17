resource "aws_iam_role" "lambda_wildcard_s3" {
  name = "lambda-wildcard-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "wildcard_s3_policy" {
  name = "wildcard-s3-policy"
  role = aws_iam_role.lambda_wildcard_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:*"
      Resource = "*"
    }]
  })
}
resource "aws_s3_bucket" "target_bucket" {
  bucket = "iam-lab-target-mumer-2026"
}

resource "aws_s3_bucket_public_access_block" "target_bucket_block" {
  bucket = aws_s3_bucket.target_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "other_bucket" {
  bucket = "iam-lab-other-mumer-2026"
}

resource "aws_s3_bucket_public_access_block" "other_bucket_block" {
  bucket = aws_s3_bucket.other_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_iam_role" "lambda_wildcard_resource" {
  name = "lambda-wildcard-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "wildcard_resource_policy" {
  name = "wildcard-dynamodb-resource"
  role = aws_iam_role.lambda_wildcard_resource.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:UpdateItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ]
      Resource = "*"
    }]
  })
}
resource "aws_dynamodb_table" "orders" {
  name         = "orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "user_credentials" {
  name         = "user_credentials"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }
}
resource "aws_iam_role" "broad_trust_role" {
  name = "broad-ec2-trust-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "broad_trust_profile" {
  name = "broad-ec2-trust-profile"
  role = aws_iam_role.broad_trust_role.name
}
resource "aws_instance" "broad_trust_instance" {
  ami                  = "ami-0c02fb55956c7d316"
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.broad_trust_profile.name

  tags = {
    Name = "broad-trust-demo-instance"
  }
}
resource "aws_iam_user" "old_admin_user" {
  name = "old-admin-user"
}

resource "aws_iam_user_policy_attachment" "admin_attach" {
  user       = aws_iam_user.old_admin_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "old_admin_key" {
  user = aws_iam_user.old_admin_user.name
}
resource "aws_iam_role" "developer_role" {
  name = "developer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.account_id}:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "developer_iam_policy" {
  name = "developer-iam-permissions"
  role = aws_iam_role.developer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:CreatePolicy",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy"
      ]
      Resource = "*"
    }]
  })
}

data "archive_file" "wildcard_s3_zip" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/wildcard_s3_demo.py"
  output_path = "${path.module}/wildcard_s3_demo.zip"
}

resource "aws_lambda_function" "wildcard_s3_demo" {
  function_name    = "wildcard-s3-blast-radius-demo"
  role             = aws_iam_role.lambda_wildcard_s3.arn
  handler          = "wildcard_s3_demo.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.wildcard_s3_zip.output_path
  source_code_hash = data.archive_file.wildcard_s3_zip.output_base64sha256
}

data "archive_file" "wildcard_dynamo_zip" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/wildcard_dynamo_demo.py"
  output_path = "${path.module}/wildcard_dynamo_demo.zip"
}

resource "aws_lambda_function" "wildcard_dynamo_demo" {
  function_name    = "wildcard-dynamo-blast-radius-demo"
  role             = aws_iam_role.lambda_wildcard_resource.arn
  handler          = "wildcard_dynamo_demo.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.wildcard_dynamo_zip.output_path
  source_code_hash = data.archive_file.wildcard_dynamo_zip.output_base64sha256
}