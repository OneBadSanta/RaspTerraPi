# RaspTerraPi 
This repo was put together as a way to manage my Raspberry Pi with Terraform and Helm charts. There are a few manual steps, but for the most part Terraform manages everything. PR's welcome

## Tested on:
* [Raspberry Pi 4 Model B](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/) (2GB version)
* Ubuntu: (64bit for Raspberry Pi 4) [20.04 LTS](https://ubuntu.com/download/raspberry-pi) and  [18.04.4](http://cdimage.ubuntu.com/releases/18.04.4/release/ubuntu-18.04.4-preinstalled-server-arm64+raspi4.img.xz)

## Software
* [Terraform](https://www.terraform.io/) v12 - Terraform Cloud is used for remote state storage
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) - For managing the cluster remotely
* [Microk8s](https://microk8s.io/) - The Kubernetes install via Ubuntu snap package
* [Helm](https://helm.sh/) 3 - Installs Helm charts with the Terraform Helm provider
* [Pi-hole](https://pi-hole.net/) - Ad Blocking: There is no official helm chart, so I use this one [mojo2600/pihole](https://hub.helm.sh/charts/mojo2600/pihole) with DNS over HTTPs via cloudflared enabled
* [Metallb](https://metallb.universe.tf/) - Bare-metal load balancer for kubernetes. Helm Chart located here [stable/metallb](https://github.com/helm/charts/tree/master/stable/metallb)
* [Puppet](https://puppet.com/) (Package installation)
* [Raspberry Pi Imager](https://www.raspberrypi.org/blog/raspberry-pi-imager-imaging-utility/)

## Installation Steps

### Prep SD Card
Use [Raspberry Pi Imager](https://www.raspberrypi.org/blog/raspberry-pi-imager-imaging-utility/) to download and copy the OS to the SD card.
Once installed, remount card and do the following in the root of the volume:

1. Enable SSH by creating an empty file named **ssh**
1. Add the following the beginning of the **cmdline.txt** file.
    ```
    cgroup_enable=memory cgroup_memory=1
    ```
1. **OPTIONAL:** If you want to add WIFI and/or disable LAN, edit **network-config**. Sometimes if both LAN and WIFI are enabled in this config, on boot it only brings up eth0. If you plan to connect only with WIFI you can comment out the _ethernets_ section or once the server is up and you're connected to the LAN IP, run `sudo netplan apply`. For more complex configuration, check out [netplan](https://ubuntu.com/blog/ubuntu-bionic-netplan)

    ```
    version: 2
    ethernets:
      eth0:
        dhcp4: true
        optional: true
    wifis:
      wlan0:
        dhcp4: true
        optional: true
        access-points:
          <WIFI_SSID>:
            password: <WIFI_PASSWORD>
    ```
1. Unmount card, place in Raspberry Pi and boot

### Configure server access
Once the server is booted and you have the IP, connect with the following defaults
```
HOST:   <SERVER_IP>
USER:     ubuntu
PASSWORD: ubuntu
```
It will immediately ask you to change the default password. Once changed it will log you out immediately. Log back in and add your SSH public key to `~/.ssh/authorized_keys`

### Bootstrap
The bootstrap directory holds Terraform code to connect to the server and install [Microk8s](https://microk8s.io/) via masterless [Puppet](https://puppet.com/)

1. Configure backend by updating `bootstrap/remote.tf`
    ##### OPTIONAL: If you are going to use [Terraform Cloud](https://www.hashicorp.com/products/terraform/pricing/) (free for up to 5 users), change organization and workspaces name
1. Update the values in `bootstrap/bootstrap.auto.tfvars` or create your own to override the them
1. Initialize Terraform
    ```
    terraform init
    ```
    ##### NOTE: If you used [Terraform Cloud](https://www.hashicorp.com/products/terraform/pricing/) go to the console and change Execution Mode to from **Remote** to **Local** `https://app.terraform.io/app/<ORGANIZATION_NAME>/workspaces/<WORKSPACE_NAME>/settings/general`
1. Apply the configuration
    ```
    terraform apply
    ```
1. Once the run is complete, log in and grab the kubeconfig
    ```
    sudo microk8s kubectl config view --flatten --minify
    ```
1. Copy the kubeconfig to somewhere on your local machine like `~/.kube/config`and change the server from `127.0.0.1` to your host IP. You can also change the contexts name and current-context from `microk8s` to `default` as well, if you'd like
1. Verify you can access the cluster from your local machine with [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
    ```
    kubectl get node
    ```

### Services
The services directory holds Terraform code to install and configure [Metallb](https://metallb.universe.tf/) and [Pi-hole](https://pi-hole.net/) via Helm charts. [Metallb](https://metallb.universe.tf/) is used to create a `loadBalancerIP` for [Pi-hole](https://pi-hole.net/) to enable connecting on a home network IP

1. Configure backend by updating `services/remote.tf`
    ##### OPTIONAL: If you used [Terraform Cloud](https://www.hashicorp.com/products/terraform/pricing/) change the organization and workspaces name
1. Update the values in `services/services.auto.tfvars` or create your own to override the them
1. Initialize Terraform
    ```
    terraform init
    ```
    ##### NOTE: If you used [Terraform Cloud](https://www.hashicorp.com/products/terraform/pricing/) go to the console and change Execution Mode to from **Remote** to **Local** 
    ##### ```https://app.terraform.io/app/<ORGANIZATION_NAME>/workspaces/<WORKSPACE_NAME>/settings/general```
1. Apply the configuration
    ```
    terraform apply
    ```
**NOTE: I have the `pihole_adminPassword` set as a variable that gets passed in when I run an apply. I personally dont care that my password is getting saved in state since it's in Terraform Cloud, but you might. Something to keep in mind.**

## Pi-hole
At this point you should now be able to access your Pi-hole web interface witn the `pihole_ip` or `pihole_hostname` you set in `services.auto.tfvars`

```
http://pi.hole/admin/
http://192.168.X.X/admin/
```


## Resource Usage
This set up uses a pretty small amount of CPU and RAM. My guess is that it would run Pi-hole and a few other small services fine on the 1GB model.

```
ubuntu@ubuntu:~$ w
 19:42:03 up 8 min,  1 user,  load average: 0.42, 0.83, 0.59
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
ubuntu   pts/0    192.168.86.90    19:41    0.00s  0.12s  0.01s w
```
```
ubuntu@ubuntu:~$ free -m
              total        used        free      shared  buff/cache   available
Mem:           1848         840          23          13         984        1029
Swap:             0           0           0
```