locals {
  id = replace(var.name, " ", "-")
}

resource "aws_s3_bucket" "this" {
  bucket = lower(local.id)
  acl    = var.acl
  tags   = var.tags

  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = var.cors_expose_headers
    max_age_seconds = var.cors_max_age_seconds
  }

  versioning {
    enabled = var.versioning_enabled
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.kms_master_key_id
      }
    }
  }

  logging {
    target_bucket = var.s3_logging_bucket
    target_prefix = "${lower(local.id)}/"
  }

  /*dynamic "website" {
    for_each = [var.website]
    content {
      
      error_document           = lookup(website.value, "error_document", null)
      index_document           = lookup(website.value, "index_document", null)
      redirect_all_requests_to = lookup(website.value, "redirect_all_requests_to", null)
      routing_rules            = lookup(website.value, "routing_rules", null)
    }
  }*/
}

resource "aws_s3_bucket_policy" "access_identity" {
  count  = var.access_identity ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.template_file.access_identity[0].rendered
}

resource "aws_s3_bucket_policy" "public" {
  count  = var.acl == "public-read" ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.template_file.public[0].rendered
}

resource "aws_iam_policy" "read" {
  count       = length(var.read_roles) > 0 ? 1 : 0
  name        = "${local.id}-S3-Read"
  description = "${var.description} Read"
  policy      = data.aws_iam_policy_document.read.json
}

resource "aws_iam_role_policy_attachment" "read" {
  count      = length(var.read_roles)
  role       = element(var.read_roles, count.index)
  policy_arn = aws_iam_policy.read[0].arn
}

resource "aws_iam_policy" "write" {
  count       = length(var.write_roles) > 0 ? 1 : 0
  name        = "${local.id}-S3-Write"
  description = "${var.description} Write"
  policy      = data.aws_iam_policy_document.write.json
}

resource "aws_iam_role_policy_attachment" "write" {
  count      = length(var.write_roles)
  role       = element(var.write_roles, count.index)
  policy_arn = aws_iam_policy.write[0].arn
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.add_bucket_policy > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy
}

resource "aws_s3_bucket_public_access_block" "this" {
  count                   = var.grant_public_access ? 0 : 1
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}