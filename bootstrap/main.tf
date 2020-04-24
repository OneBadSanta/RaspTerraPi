resource "null_resource" "puppet_pi" {
  connection {
    type        = var.connection_type
    host        = var.connection_host
    user        = var.connection_user
    timeout     = var.connection_timeout
  }

  provisioner "file" {
    source      = "${path.module}/puppet"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install puppet -y",
      "sudo puppet apply /tmp/puppet/init.pp",
    ]
  }
  
  triggers = {
    top_change = sha1(file("${path.module}/puppet/init.pp"))
  }
}