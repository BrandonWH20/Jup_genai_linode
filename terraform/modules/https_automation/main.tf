provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

resource "null_resource" "install_cert_manager_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml"
  }
}


# Install ingress-nginx
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = "4.10.0"

  create_namespace = true

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }
  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx"
  }
}

# Patch ingressclass nginx to be the default
resource "null_resource" "patch_ingressclass_nginx" {
  provisioner "local-exec" {
    command = "kubectl annotate ingressclass nginx ingressclass.kubernetes.io/is-default-class=true --overwrite"
  }
}


# Install cert-manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "v1.13.3"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_manifest" "jupyterhub_ingress" {

  manifest = yamldecode(templatefile("${path.module}/ingress.yaml.tmpl", {
    subdomain = var.subdomain,
    domain    = var.domain
    namespace = var.namespace
  }))
}


# ClusterIssuer for Let's Encrypt
resource "kubernetes_manifest" "cluster_issuer" {
  manifest = yamldecode(
    templatefile("${path.module}/cluster_issuer.yaml.tmpl", {
      email = var.email
    })
  )
}

# Get NGINX LoadBalancer IP (for DNS A record)
data "kubernetes_service" "nginx_lb" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

data "linode_domain" "selected" {
  domain = var.domain
}

# Create DNS A record for jupyter.<domain>
resource "linode_domain_record" "jupyterhub_a_record" {
  domain_id    = data.linode_domain.selected.id
  name         = var.subdomain
  record_type  = "A"
  target       = data.kubernetes_service.nginx_lb.status[0].load_balancer[0].ingress[0].ip
  ttl_sec      = 300
}

