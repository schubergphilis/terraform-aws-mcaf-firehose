output "arn" {
  value       = aws_kinesis_firehose_delivery_stream.default.arn
  description = "ARN of the firehose delivery stream"
}

output "name" {
  value       = aws_kinesis_firehose_delivery_stream.default.name
  description = "Name of the firehose delivery stream"
}
