resource "kubernetes_namespace" "pihole_system" {
  metadata {
    name = "pihole-system"
  }
}

resource "helm_release" "pihole" {
  name       = "pihole"
  namespace  = kubernetes_namespace.pihole_system.metadata.0.name
  repository = data.helm_repository.mojo2600.metadata.0.name
  chart      = "pihole"

  values = [
    data.template_file.pihole.rendered
  ]
}

data "template_file" "pihole" {
  template = file("./helm/pihole.values.yaml")

  vars = {
    adminPassword   = var.pihole_adminPassword
    loadbalancerip  = var.pihole_ip
    pihole_hostname = var.pihole_hostname
  }
}