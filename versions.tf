terraform {
  required_version = ">= 1.0.5"
  required_providers {
    aws = {
      version = ">= 4.19.0"
      source  = "hashicorp/aws"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
  }
}
