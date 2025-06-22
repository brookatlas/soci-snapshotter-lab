terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
  }
  backend "s3" {
    bucket = "my-lab-soci-snapshotter-s3-state"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "my-lab-soci-snapshotter-s3-state-lock"
    encrypt = true
  }
}