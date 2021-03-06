locals {
  kinesis        = var.kinesis_arn != null ? [var.kinesis_arn] : []
  kms_policy     = var.kms_key_arn != null ? data.aws_iam_policy_document.firehose_kms_role[0].json : null
  parquet_prefix = "year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
}

data "aws_s3_bucket" "default" {
  bucket = var.s3_bucket_name
}

data "aws_iam_policy_document" "firehose_kms_role" {
  count = var.kms_key_arn != null ? 1 : 0

  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "firehose_s3_role" {
  override_json = local.kms_policy

  statement {
    actions = [
      "glue:GetTableVersions",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:AbortMultipartUpload",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      data.aws_s3_bucket.default.arn,
      "${data.aws_s3_bucket.default.arn}/*"
    ]
  }
}

module "firehose_s3_role" {
  source                = "github.com/schubergphilis/terraform-aws-mcaf-role?ref=v0.3.0"
  name                  = "FirehoseS3Role-${var.name}"
  create_policy         = true
  principal_identifiers = ["firehose.amazonaws.com"]
  principal_type        = "Service"
  role_policy           = data.aws_iam_policy_document.firehose_s3_role.json
  tags                  = var.tags
}

data "aws_iam_policy_document" "firehose_kinesis_role" {
  count = var.kinesis_arn != null ? 1 : 0

  override_json = local.kms_policy

  statement {
    actions = [
      "kinesis:List*",
      "kinesis:Describe*",
      "kinesis:Get*"
    ]
    resources = [
      var.kinesis_arn
    ]
  }
}

module "firehose_kinesis_role" {
  count                 = var.kinesis_arn != null ? 1 : 0
  source                = "github.com/schubergphilis/terraform-aws-mcaf-role?ref=v0.3.0"
  create_policy         = true
  name                  = "FirehoseKinesisRole-${var.name}"
  principal_identifiers = ["firehose.amazonaws.com"]
  principal_type        = "Service"
  role_policy           = data.aws_iam_policy_document.firehose_kinesis_role[0].json
  tags                  = var.tags
}

resource "aws_kinesis_firehose_delivery_stream" "default" {
  name        = var.name
  destination = "extended_s3"
  tags        = var.tags

  dynamic "kinesis_source_configuration" {
    for_each = toset(local.kinesis)

    content {
      kinesis_stream_arn = each.value
      role_arn           = module.firehose_kinesis_role[0].arn
    }
  }

  extended_s3_configuration {
    bucket_arn          = data.aws_s3_bucket.default.arn
    buffer_interval     = var.buffer_interval
    buffer_size         = var.buffer_size
    error_output_prefix = "${var.prefix_error}/${local.parquet_prefix}!{firehose:error-output-type}"
    kms_key_arn         = var.kms_key_arn
    prefix              = "${var.prefix}/${local.parquet_prefix}"
    role_arn            = module.firehose_s3_role.arn

    data_format_conversion_configuration {
      enabled = true

      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = var.glue_catalog_database
        role_arn      = module.firehose_s3_role.arn
        table_name    = aws_glue_catalog_table.default.name
      }
    }
  }
}
