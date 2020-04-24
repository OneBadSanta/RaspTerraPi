package { 'net-tools':
  name    => net-tools,
  ensure  => latest,
}

package { 'iftop':
  name    => iftop,
  ensure  => latest,
}

exec { 'microk8s_install':
  command  => "sudo snap install microk8s --channel=1.18 --classic",
  provider => shell,
}

exec { 'microk8s_configure':
  command  => "sudo microk8s enable helm3 metrics-server storage",
  provider => shell,
}
