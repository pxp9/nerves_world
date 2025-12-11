# Infrastructure Tools

Infrastructure as Code setup for deploying and managing cloud infrastructure and Kubernetes applications.

## Project Structure

```
.
├── infra/
│   ├── terraform/       # Hetzner Cloud infrastructure
│   ├── ansible/         # Server provisioning and K3s installation
│   └── k8s/             # Kubernetes application deployments
├── apps/            # Where Apps are gonna be located
├── flake.nix            # Nix development environment
└── docker-compose.yml   # Local development services
```

## Prerequisites

- Nix with flakes enabled
- direnv (optional, for automatic environment loading)

## Quick Start

1. **Enter development environment:**
   ```bash
   direnv allow
   ```

2. **Configure Hetzner API token:**
   ```bash
   cd infra/terraform
   # Edit secrets.tfvars and add your Hetzner API token
   ```

3. **Deploy infrastructure:**
   ```bash
   make apply
   ```

4. **Install K3s on the server:**
   ```bash
   cd ../ansible
   make install-k3s
   ```

5. **Deploy applications:**
   ```bash
   cd ../k8s/livebook
   make install
   ```

## Port Mappings

### Local Development Ports

| Service | Port | Purpose |
|---------|------|---------|
| Terraform MCP Server | 8080 | Model Context Protocol for Terraform |

### Kubernetes Services (NodePort)

| Service | Internal Port | NodePort | Access URL |
|---------|--------------|----------|------------|
| Livebook | 9000 | 30080 | http://SERVER_IP:30080 |

### Port Forwarding

When using `kubectl port-forward`, services are mapped to localhost:

| Service | Local Port | Command |
|---------|-----------|---------|
| Livebook | 9000 | `make port-forward` (in k8s/livebook/) |

## Available Commands

### Terraform (infra/terraform/)
```bash
make init      # Initialize Terraform
make plan      # Show execution plan
make apply     # Apply infrastructure changes
make destroy   # Destroy infrastructure
make format    # Format Terraform files
make unlock id=LOCK_ID  # Unlock state
```

### Ansible (infra/ansible/)
```bash
make ping         # Test connection to server
make install-k3s  # Install K3s on server
make status       # Check K3s status
make uninstall-k3s  # Remove K3s
```

### Kubernetes - Livebook (infra/k8s/livebook/)
```bash
make install      # Deploy Livebook
make upgrade      # Upgrade Livebook
make status       # Check deployment status
make logs         # View logs
make port-forward # Forward to localhost:9000
make uninstall    # Remove Livebook
```

## Technologies

- **Infrastructure**: Terraform, Hetzner Cloud
- **Provisioning**: Ansible
- **Kubernetes**: K3s
- **Package Management**: Nix, Helm
- **Applications**: Livebook
