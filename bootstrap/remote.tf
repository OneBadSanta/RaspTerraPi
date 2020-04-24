terraform {
  backend "remote" {
    organization = "santas"

    workspaces {
      name = "mypi4-bootstrap"
    }
  }
}