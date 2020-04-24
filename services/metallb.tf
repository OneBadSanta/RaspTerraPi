resource "kubernetes_namespace" "metallb_system" {
  metadata {
    name = "metallb-system"
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  namespace  = kubernetes_namespace.metallb_system.metadata.0.name
  repository = data.helm_repository.stable.metadata.0.name
  chart      = "metallb"

  values = [
    data.template_file.metallb.rendered
  ]
}

data "template_file" "metallb" {
  template = file("./helm/metallb.values.yaml")

  vars = {
    ip_range = var.metallb_ip_range
  }
}