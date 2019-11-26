variable "bucket_name" {
  type        = "string"
  description = "Bucket Name To Be Created"
}

variable "policy_name" {
  type        = "string"
  description = "Policy Name To Be Created"
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "snilogs"
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket" "prod_bucket" {
  bucket = "${var.bucket_name}"
  acceleration_status = "Enabled"

  logging {
    target_bucket = "${aws_s3_bucket.log_bucket.id}"
    target_prefix = "${var.bucket_name}/logs/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                "arn:aws:iam::681100484102:user/ywang",
                "arn:aws:iam::681100484102:user/syavagal"
                ]
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.bucket_name}",
                "arn:aws:s3:::${var.bucket_name}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_s3_bucket_public_access_block" "block_access" {
  bucket = "${aws_s3_bucket.prod_bucket.id}"

  block_public_acls   = true
  block_public_policy = true
}

resource "aws_iam_policy" "policy" {
  name        = "${var.policy_name}"
  path        = "/"
  description = "Policy To Access sniops-ads-hdpmezz"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}",
        "arn:aws:s3:::${var.bucket_name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "sniops-ads-hdmezz-bucket-role" {
  name = "sniops-ads-hdmezz-bucket-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::681100484102:user/ywang"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = "${aws_iam_role.sniops-ads-hdmezz-bucket-role.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}

data "aws_s3_bucket" "hdpmezz-bucket" {
  bucket = "${var.bucket_name}"
}

resource "aws_cloudtrail" "s3_object_logging" {
  name           = "sniops-cloudtrail-events"
  s3_bucket_name = "snilogs"
  s3_key_prefix  = "CloudTrail/sniops-ads-hdmezz-bucket"

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${data.aws_s3_bucket.hdpmezz-bucket.arn}/"]
    }
  }
}
