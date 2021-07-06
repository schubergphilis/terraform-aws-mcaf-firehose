output "arn" {
  value       = aws_kinesis_firehose_delivery_stream.default.arn
  description = "ARN of the firehose delivery stream"
}

output "glue_table_name" {
  description = "Name of the Glue Table"
  value       = replace(var.name, "-", "_")
}

output "name" {
  value       = aws_kinesis_firehose_delivery_stream.default.name
  description = "Name of the firehose delivery stream"
}
