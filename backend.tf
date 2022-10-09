terraform {
  backend "s3" {
    bucket = "k8s-infra-tf-state"
    region = "us-east-1"
  }
}
