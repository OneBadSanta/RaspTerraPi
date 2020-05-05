provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "pi"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "pi"
}
