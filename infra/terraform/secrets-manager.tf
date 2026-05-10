# AWS Secrets Manager Configuration for NepalTrust
# Stores production credentials for payment providers (eSewa, Khalti, connectIPS)

resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for NepalTrust Secrets Manager encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags = {
    Name        = "nepaltrust-secrets-key"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/nepaltrust-secrets-key"
  target_key_id = aws_kms_key.secrets_key.key_id
}

# eSewa Production Secret
resource "aws_secretsmanager_secret" "esewa_secret" {
  name                    = "nepaltrust/esewa/production"
  description             = "eSewa EPay-v2 production credentials"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 30

  tags = {
    Name        = "esewa-production-secret"
    Provider    = "esewa"
    Environment = "production"
  }
}

resource "aws_secretsmanager_secret_version" "esewa_secret_version" {
  secret_id = aws_secretsmanager_secret.esewa_secret.id
  secret_string = jsonencode({
    secret_key = "PLACEHOLDER_REPLACE_WITH_PRODUCTION_SECRET"
    product_code = "NEPALTRUST_PROD"
  })
}

# Khalti Production Secret
resource "aws_secretsmanager_secret" "khalti_secret" {
  name                    = "nepaltrust/khalti/production"
  description             = "Khalti KPG-2 production credentials"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 30

  tags = {
    Name        = "khalti-production-secret"
    Provider    = "khalti"
    Environment = "production"
  }
}

resource "aws_secretsmanager_secret_version" "khalti_secret_version" {
  secret_id = aws_secretsmanager_secret.khalti_secret.id
  secret_string = jsonencode({
    live_secret_key = "PLACEHOLDER_REPLACE_WITH_PRODUCTION_SECRET"
    public_key      = "PLACEHOLDER_REPLACE_WITH_PUBLIC_KEY"
  })
}

# connectIPS Production Secret
resource "aws_secretsmanager_secret" "connectips_secret" {
  name                    = "nepaltrust/connectips/production"
  description             = "connectIPS real-time API production credentials"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 30

  tags = {
    Name        = "connectips-production-secret"
    Provider    = "connectips"
    Environment = "production"
  }
}

resource "aws_secretsmanager_secret_version" "connectips_secret_version" {
  secret_id = aws_secretsmanager_secret.connectips_secret.id
  secret_string = jsonencode({
    credential_name = "PLACEHOLDER_REPLACE_WITH_CREDENTIAL_NAME"
    app_id         = "PLACEHOLDER_REPLACE_WITH_APP_ID"
    app_name       = "PLACEHOLDER_REPLACE_WITH_APP_NAME"
    username       = "PLACEHOLDER_REPLACE_WITH_USERNAME"
    password       = "PLACEHOLDER_REPLACE_WITH_PASSWORD"
    private_key    = "PLACEHOLDER_REPLACE_WITH_RSA_PRIVATE_KEY"
  })
}

# Secret Rotation Configuration (Quarterly as per requirements)
resource "aws_secretsmanager_secret_rotation" "esewa_rotation" {
  secret_id           = aws_secretsmanager_secret.esewa_secret.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn

  rotation_rules {
    automatically_after_days = 90
  }
}

resource "aws_secretsmanager_secret_rotation" "khalti_rotation" {
  secret_id           = aws_secretsmanager_secret.khalti_secret.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn

  rotation_rules {
    automatically_after_days = 90
  }
}

resource "aws_secretsmanager_secret_rotation" "connectips_rotation" {
  secret_id           = aws_secretsmanager_secret.connectips_secret.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn

  rotation_rules {
    automatically_after_days = 90
  }
}

# IAM Role for ECS Tasks to Access Secrets
resource "aws_iam_role" "ecs_task_role" {
  name = "nepaltrust-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "nepaltrust-ecs-task-role"
    Environment = "production"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_secrets_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_access_policy.arn
}

resource "aws_iam_policy" "secrets_access_policy" {
  name        = "nepaltrust-secrets-access-policy"
  description = "Policy for ECS tasks to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.esewa_secret.arn,
          aws_secretsmanager_secret.khalti_secret.arn,
          aws_secretsmanager_secret.connectips_secret.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.secrets_key.arn
      }
    ]
  })
}

# CloudTrail Logging for Secret Access
resource "aws_cloudtrail" "secrets_access_trail" {
  name                          = "nepaltrust-secrets-access-trail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail_logs.bucket
  include_global_service_events = false
  is_multi_region_trail        = false

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::SecretsManager::Secret"
      values = ["arn:aws:secretsmanager:*:*:secret:nepaltrust/*"]
    }
  }

  tags = {
    Name        = "nepaltrust-secrets-access-trail"
    Environment = "production"
  }
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "nepaltrust-cloudtrail-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "nepaltrust-cloudtrail-logs"
    Environment = "production"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lambda Function for Secret Rotation (Stub - requires implementation)
resource "aws_lambda_function" "secret_rotation" {
  function_name = "nepaltrust-secret-rotation"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs20.x"
  handler       = "index.handler"

  s3_bucket = aws_s3_bucket.lambda_code.bucket
  s3_key    = aws_s3_object.lambda_code.key

  tags = {
    Name        = "nepaltrust-secret-rotation"
    Environment = "production"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "nepaltrust-secret-rotation-role"

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

resource "aws_s3_bucket" "lambda_code" {
  bucket = "nepaltrust-lambda-code-${random_id.lambda_suffix.hex}"
}

resource "random_id" "lambda_suffix" {
  byte_length = 4
}

resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.bucket
  key    = "secret-rotation/index.zip"
  source = "./lambda/secret-rotation/index.zip" # Placeholder - needs implementation
}

# Outputs
output "esewa_secret_arn" {
  description = "ARN of eSewa production secret"
  value       = aws_secretsmanager_secret.esewa_secret.arn
}

output "khalti_secret_arn" {
  description = "ARN of Khalti production secret"
  value       = aws_secretsmanager_secret.khalti_secret.arn
}

output "connectips_secret_arn" {
  description = "ARN of connectIPS production secret"
  value       = aws_secretsmanager_secret.connectips_secret.arn
}

output "ecs_task_role_arn" {
  description = "ARN of ECS task role with secrets access"
  value       = aws_iam_role.ecs_task_role.arn
}

output "kms_key_arn" {
  description = "ARN of KMS key for secret encryption"
  value       = aws_kms_key.secrets_key.arn
}
