module "external_dns_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  create_role                = true
  attach_external_dns_policy = true

  role_name_prefix = "external-dns-${var.environment}"

  oidc_providers = {
    one = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }

  tags = merge(
    {
      Role = "external-dns-${var.environment}"
    },
    local.tags
  )
}
