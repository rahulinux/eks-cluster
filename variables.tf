variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.22"
}

variable "cert_arn" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "vpc_cidr" {
  type = string
}
