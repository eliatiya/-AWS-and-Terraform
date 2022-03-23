# S3 Bucket config#
resource "aws_iam_role" "allow_instance_s3" {
  name = "${var.bucket_name}_allow_instance_s3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.bucket_name}_instance_profile"
  role = aws_iam_role.allow_instance_s3.name
}

resource "aws_iam_role_policy" "allow_s3_all" {
  name = "${var.bucket_name}_allow_all"
  role = aws_iam_role.allow_instance_s3.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_s3_bucket" "web_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
}
#resource "aws_s3_bucket_acl" "web_bucket" {
#  bucket = aws_s3_bucket.web_bucket.id
#  #acl    = "private"
#}
#
#resource "aws_s3_bucket_versioning" "versioning_example" {
#  bucket = aws_s3_bucket.web_bucket.id
#  versioning_configuration {
#    status = "Enabled"
#  }
#}