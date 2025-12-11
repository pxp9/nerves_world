terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.57.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# Upload your SSH public key to Hetzner Cloud
resource "hcloud_ssh_key" "default" {
  name       = "hetzner-key"
  public_key = file("/home/pxp9/.ssh/hetzner.pub")
}

# Create a cheap Hetzner Cloud server with SSH access
resource "hcloud_server" "main_server" {
  name        = "main-server"
  server_type = "cx33" # CX33 server type
  image       = "ubuntu-24.04"
  location    = "nbg1" # Nuremberg, Germany - you can also use "fsn1" (Falkenstein) or "hel1" (Helsinki)

  # Attach SSH key for access
  ssh_keys = [hcloud_ssh_key.default.id]

  # Cloud-init user data to create user and configure SSH
  user_data = <<-EOF
    #cloud-config
    users:
      - name: pxp9
        groups: sudo
        shell: /bin/bash
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh_authorized_keys:
          - ${trimspace(file("/home/pxp9/.ssh/hetzner.pub"))}

    # Disable root SSH login
    ssh_pwauth: false
    disable_root: false

    runcmd:
      - sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
      - systemctl restart sshd
      - hostnamectl set-hostname main-server
  EOF

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  labels = {
    environment = "development"
    managed_by  = "terraform"
  }
}

# Output the server details
output "server_id" {
  value       = hcloud_server.main_server.id
  description = "The unique ID of the server"
}

output "server_ipv4" {
  value       = hcloud_server.main_server.ipv4_address
  description = "The IPv4 address of the server"
}

output "server_ipv6" {
  value       = hcloud_server.main_server.ipv6_address
  description = "The IPv6 address of the server"
}

output "server_status" {
  value       = hcloud_server.main_server.status
  description = "The current status of the server"
}

output "ssh_command" {
  value       = "ssh -i /home/pxp9/.ssh/hetzner pxp9@${hcloud_server.main_server.ipv4_address}"
  description = "SSH command to connect to the server as pxp9 user"
}
