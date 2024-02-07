################################################################################
# Queue
################################################################################
resource "aws_sqs_queue" "this" {
  count = var.create ? 1 : 0

  content_based_deduplication       = var.content_based_deduplication
  deduplication_scope               = var.deduplication_scope
  delay_seconds                     = var.delay_seconds
  fifo_queue                        = var.fifo_queue
  fifo_throughput_limit             = var.fifo_throughput_limit
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds
  kms_master_key_id                 = var.kms_master_key_id
  max_message_size                  = var.max_message_size
  message_retention_seconds         = var.message_retention_seconds
  name                              = var.name
  receive_wait_time_seconds         = var.receive_wait_time_seconds
  sqs_managed_sse_enabled           = var.kms_master_key_id != null ? null : var.sqs_managed_sse_enabled
  visibility_timeout_seconds        = var.visibility_timeout_seconds

  tags = var.tags
}

resource "aws_sqs_queue_policy" "this" {
  count = var.create && var.aws_sqs_queue_policy != "" ? 1 : 0

  queue_url = aws_sqs_queue.this[0].url
  policy    = var.aws_sqs_queue_policy
}

################################################################################
# Re-drive Policy
################################################################################

resource "aws_sqs_queue_redrive_policy" "this" {
  count = var.create && length(var.redrive_policy) > 0 ? 1 : 0

  queue_url      = aws_sqs_queue.this[0].url
  redrive_policy = var.redrive_policy
}

################################################################################
# Dead Letter Queue
################################################################################

locals {

  dlq_kms_master_key_id       = try(coalesce(var.dlq_kms_master_key_id, var.kms_master_key_id), null)
  dlq_sqs_managed_sse_enabled = coalesce(var.dlq_sqs_managed_sse_enabled, var.sqs_managed_sse_enabled)
}

resource "aws_sqs_queue" "dlq" {
  count = var.create && var.dlq_name != null ? 1 : 0

  content_based_deduplication = try(coalesce(var.dlq_content_based_deduplication, var.content_based_deduplication), null)
  deduplication_scope         = try(coalesce(var.dlq_deduplication_scope, var.deduplication_scope), null)
  delay_seconds               = try(coalesce(var.dlq_delay_seconds, var.delay_seconds), null)
  # If source queue is FIFO, DLQ must also be FIFO and vice versa
  fifo_queue                        = var.fifo_queue
  fifo_throughput_limit             = var.fifo_throughput_limit
  kms_data_key_reuse_period_seconds = try(coalesce(var.dlq_kms_data_key_reuse_period_seconds, var.kms_data_key_reuse_period_seconds), null)
  kms_master_key_id                 = local.dlq_kms_master_key_id
  max_message_size                  = var.max_message_size
  message_retention_seconds         = try(coalesce(var.dlq_message_retention_seconds, var.message_retention_seconds), null)
  name                              = var.dlq_name
  receive_wait_time_seconds         = try(coalesce(var.dlq_receive_wait_time_seconds, var.receive_wait_time_seconds), null)
  sqs_managed_sse_enabled           = local.dlq_kms_master_key_id != null ? null : local.dlq_sqs_managed_sse_enabled
  visibility_timeout_seconds        = try(coalesce(var.dlq_visibility_timeout_seconds, var.visibility_timeout_seconds), null)

  tags = merge(var.tags, var.dlq_tags)
}

resource "aws_sqs_queue_policy" "dlq" {
  count = var.create && var.dlq_name != null && var.aws_sqs_queue_policy_dlq != "" ? 1 : 0

  queue_url = aws_sqs_queue.dlq[0].url
  policy    = var.aws_sqs_queue_policy_dlq
}

################################################################################
# Re-drive Allow Policy
################################################################################

resource "aws_sqs_queue_redrive_allow_policy" "this" {
  count = var.create && var.dlq_name == null && length(var.redrive_allow_policy) > 0 ? 1 : 0

  queue_url            = aws_sqs_queue.this[0].url
  redrive_allow_policy = var.redrive_allow_policy
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  count = var.create && var.dlq_name != null && length(var.dlq_redrive_allow_policy) > 0 ? 1 : 0

  queue_url            = aws_sqs_queue.dlq[0].url
  redrive_allow_policy = var.dlq_redrive_allow_policy
}
