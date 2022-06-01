# variable "whitelist" {
#   type = list(string)
# }         
# variable "web_image_id" {
#   type = string
# }
# variable "web_instance_type" {
#   type = string
# }

provider "aws" {
  # profile = "my_aws_creds"
  region = "us-east-1"
}

# data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "jdlab_terraform_state" {
  bucket = "jdlab-project001-tenable-cs-s3-terraform-state"

  lifecycle {
    prevent_destroy = false
  }

  versioning {
    enabled = true
  }

  tags = {
    "Name"      = "jdlab-project001-tenable-cs-s3-terraform-state"
    "Terraform" = "true"
  }

}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_sse" {
  bucket = aws_s3_bucket.jdlab_terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.prod_tf_course001_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }

}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    "Name"      = "terraform-state-locking"
    "Terraform" = "true"
  }

  server_side_encryption {
    enabled = true
  }
}


resource "aws_s3_bucket" "prod_tf_course001" {
  bucket = "tf-course001-20220412"

  tags = {
    "Name"      = "tf-course001-20220412"
    "Terraform" = "true"
  }
}

resource "aws_s3_bucket_acl" "prod_tf_course001_s3_acl" {
  bucket = aws_s3_bucket.prod_tf_course001.id
  acl    = "private"

}

resource "aws_s3_bucket_versioning" "prod_tf_course001_versioning" {
  bucket = aws_s3_bucket.prod_tf_course001.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "prod_tf_course001_bucket_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prod_tf_course001_encryption" {
  bucket = aws_s3_bucket.prod_tf_course001.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.prod_tf_course001_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}


resource "aws_default_vpc" "default" {}

resource "aws_security_group" "prod_web_sg" {
  name        = "prod_web"
  description = "Allow standard http and https ports inbound and everything outbound"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Terraform" = "true"
  }

}

resource "aws_instance" "prod_web" {
  ami           = "ami-065fb54436c0e2d57"
  instance_type = "t2.nano"

  vpc_security_group_ids = [
    aws_security_group.prod_web_sg.id
  ]

  tags = {
    "Terraform" = "true"
  }


  metadata_options {
    http_endpoint = "disabled"
    http_tokens   = "required"
  }
}

resource "aws_eip" "prod_web" {
  instance = aws_instance.prod_web.id

  tags = {
    "Terraform" = "true"
  }
}
