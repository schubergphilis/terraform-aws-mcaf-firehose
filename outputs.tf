output "arn" {
  value       = aws_kinesis_firehose_delivery_stream.default.arn
  description = "ARN of the firehose delivery stream"
}

output "glue_table_name" {
  value       = aws_glue_catalog_table.default.name
  description = "Name of the Glue Table"
}

output "name" {
  value       = aws_kinesis_firehose_delivery_stream.default.name
  description = "Name of the firehose delivery stream"
}
