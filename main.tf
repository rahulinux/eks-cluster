locals {
  name = "eks-cluster-${var.environment}"
  tags = {
    Owner          = "user"
    Environment    = var.environment
    Project        = var.project
    ClusterName    = local.name
    ClusterVersion = var.cluster_version
  }
  cert_arn = var.cert_arn
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.29.0"

  cluster_name                    = local.name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Self managed node groups will not automatically create the aws-auth configmap so we need to
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  self_managed_node_groups = {

    # worker_group_1 node group
    worker_group_1 = {
      name          = "worker_group_1-self-mng"
      instance_type = "c5.large"
      desired_size  = 1
      subnet_ids    = module.vpc.public_subnets

      bootstrap_extra_args = "--kubelet-extra-args '--max-pods=110'"

      iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }
    }
  }
}

resource "helm_release" "external_dns" {
  name = "external-dns"

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "1.11.0"

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com\\/role-arn"
    value = module.external_dns_irsa.iam_role_arn
  }
}



resource "helm_release" "traefik_public" {
  name = "traefik-public"

  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  namespace  = "kube-system"
  version    = "10.24.0"

  values = [yamlencode({
    ports = {
      traefik = {
        expose = true,
        websecure = {
          port = "443"
        }
      }
    },
    securityContext = {
      capabilities = {
        drop = ["ALL"]
        add  = ["NET_BIND_SERVICE"]
      }
      runAsGroup   = 0
      runAsNonRoot = false
      runAsUser    = 0
    }
    providers = {
      kubernetesCRD = {
        enabled      = true
        ingressClass = "traefik"
      }
      kubernetesIngress = {
        enabled      = true
        ingressClass = "traefik"
        publishedService = {
          enabled = true
        }
      }
    },
    service = {
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-type"             = ""
        "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"        = "443"
        "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "http"
        "service.beta.kubernetes.io/aws-load-balancer-internal"         = "false"
        "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"         = local.cert_arn
      }
    },
    additionalArguments = [
      "--api.insecure=true",
      "--serversTransport.insecureSkipVerify=true",
      "--entrypoints.web.http.redirections.entrypoint.scheme=https",
      "--entrypoints.web.http.redirections.entryPoint.to=websecure",
      "--entryPoints.web.forwardedHeaders.insecure",
      "--entryPoints.websecure.forwardedHeaders.insecure",
      "--entryPoints.web.proxyProtocol.insecure",
      "--entryPoints.websecure.proxyProtocol.insecure"
    ]
  })]
}
