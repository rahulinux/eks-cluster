project         = "eks"
environment     = "dev"
cert_arn        = "arn:aws:acm:us-east-1:336243553406:certificate/b9c5ec7a-b52c-43f6-bc01-9a87d35dcba7"
vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
