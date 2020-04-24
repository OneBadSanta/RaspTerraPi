data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

data "helm_repository" "mojo2600" {
  name = "mojo2600"
  url  = "https://mojo2600.github.io/pihole-kubernetes"
} 