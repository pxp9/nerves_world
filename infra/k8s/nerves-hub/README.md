# NervesHub Kubernetes Deployment

This Helm chart deploys [NervesHub](https://github.com/nerves-hub/nerves_hub_web), a firmware update and device management server for Nerves devices, on Kubernetes.

## Features

- **NervesHub Application**: Phoenix/Elixir web application for firmware management
- **PostgreSQL**: Primary database (using Bitnami chart)
- **ClickHouse**: Analytics and telemetry database
- **Persistent Storage**: For firmware files and database data
- **Configurable Ingress**: HTTPS support with cert-manager integration
- **S3 Support**: Optional S3-compatible storage for firmware

## Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.x
- kubectl configured to access your cluster
- (Optional) Ingress controller for external access
- (Optional) cert-manager for SSL certificates

## Quick Start

### 1. Install Sealed-Secrets Controller

SealedSecrets allow you to safely commit encrypted secrets to git.

```bash
# Install sealed-secrets controller in your cluster
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system

# Verify installation
kubectl get pods -n kube-system | grep sealed-secrets
```

### 2. Configure Secrets

All secrets (NervesHub + PostgreSQL) are managed in a single unified sealed secret.

**Step 1: Generate secret values**

```bash
# Generate Phoenix secrets (if you have Elixir installed):
mix phx.gen.secret  # For SECRET_KEY_BASE (needs 64+ chars)
mix phx.gen.secret  # For LIVE_VIEW_SIGNING_SALT

# Or use OpenSSL:
openssl rand -base64 64  # For SECRET_KEY_BASE
openssl rand -base64 32  # For LIVE_VIEW_SIGNING_SALT

# Generate PostgreSQL password:
openssl rand -base64 32
```

**Step 2: Generate TLS certificates**

```bash
# Generate self-signed certificates for device communication
cd certs
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes \
  -subj "/CN=nerves-hub.local"
cd ..
```

**Step 3: Edit secrets.yaml**

Edit the `secrets.yaml` file and fill in all the values:

```bash
# Open in your editor
nano secrets.yaml  # or vim/code/etc
```

Replace all placeholder values:
- `YOUR_POSTGRES_PASSWORD` - Use the same password for both `password` and `postgres-password`
- `CHANGE_ME_*` - Replace with generated secrets from Step 1
- `DEVICE_SSL_CERT` and `DEVICE_SSL_KEY` - Paste the contents of `certs/cert.pem` and `certs/key.pem`

**Step 4: Seal the secrets**

```bash
# This will encrypt your secrets and create sealed-secrets/sealed-secret-unified.yaml
make seal-secrets

# If your controller is in a different namespace or has a different name:
make seal-secrets CONTROLLER_NAME=your-controller CONTROLLER_NAMESPACE=your-namespace
```

The sealed secret can now be safely committed to git. Only your cluster can decrypt it.

**Step 5: Apply the sealed secret**

```bash
kubectl create namespace nerves-hub
make apply-sealed-secret

# Or manually:
kubectl apply -f sealed-secrets/sealed-secret-unified.yaml
```

### 3. Install NervesHub

```bash
make install
```

This will:
- Create the namespace
- Install PostgreSQL with persistent storage
- Deploy ClickHouse with persistent storage
- Deploy NervesHub application
- Create all necessary services and configurations

### 5. Check Status

```bash
make status
```

### 6. Access NervesHub

**Local Access (Port Forward):**
```bash
make port-forward
```

Then visit: http://localhost:4000

**External Access:**
Enable ingress in `values.yaml`:
```yaml
nervesHub:
  ingress:
    enabled: true
    className: "nginx"  # or your ingress class
    hosts:
      - host: nerves-hub.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: nerves-hub-tls
        hosts:
          - nerves-hub.example.com
```

Then upgrade:
```bash
make upgrade
```

## Delete and Reinstall from Scratch

If you need to completely remove the existing deployment and start fresh:

### Step 1: Delete existing deployment

```bash
# Delete the Helm release
helm uninstall nerves-hub -n nerves-hub

# Delete all PVCs (this will delete all data!)
kubectl delete pvc -n nerves-hub --all

# Delete the sealed secrets
kubectl delete sealedsecret -n nerves-hub --all

# (Optional) Delete the namespace entirely
kubectl delete namespace nerves-hub
```

### Step 2: Clean up local files (optional)

```bash
# Remove old sealed secrets if you're starting completely fresh
rm -f sealed-secrets/sealed-secret-unified.yaml
```

### Step 3: Reinstall from scratch

Follow the Quick Start guide from the beginning:

1. **Install Sealed-Secrets Controller** (if not already installed)
2. **Configure Secrets** - Edit `secrets.yaml` with your new values
3. **Seal the secrets** - Run `make seal-secrets`
4. **Apply sealed secret** - Run `kubectl create namespace nerves-hub && make apply-sealed-secret`
5. **Install NervesHub** - Run `make install`

### Important Notes

- Deleting PVCs will permanently delete all data (databases, firmware files, etc.)
- Make sure you have backups before deleting if you have important data
- The sealed-secrets controller itself (in kube-system namespace) is not deleted
- After reinstallation, you'll have a completely fresh NervesHub instance

## Configuration

### Essential Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nervesHub.config.secretKeyBase` | Phoenix secret key base (required) | `CHANGE_ME` |
| `nervesHub.config.liveViewSigningSalt` | LiveView signing salt (required) | `CHANGE_ME` |
| `nervesHub.config.databaseUrl` | PostgreSQL connection URL | Auto-configured |

### PostgreSQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `postgresql.auth.username` | Database username | `postgres` |
| `postgresql.auth.password` | Database password | `postgres` |
| `postgresql.auth.database` | Database name | `nerves_hub` |
| `postgresql.primary.persistence.size` | Storage size | `10Gi` |

### ClickHouse Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `clickhouse.enabled` | Enable ClickHouse | `true` |
| `clickhouse.image.tag` | ClickHouse version | `25.4.2.31` |
| `clickhouse.persistence.size` | Storage size | `10Gi` |

### Storage Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nervesHub.persistence.enabled` | Enable persistent storage | `true` |
| `nervesHub.persistence.size` | Storage size for firmware | `20Gi` |
| `nervesHub.persistence.storageClass` | Storage class | `""` (default) |

### S3 Configuration (Optional)

```yaml
nervesHub:
  config:
    s3Enabled: true
    s3Bucket: "my-firmware-bucket"
    s3Region: "us-east-1"
    s3AccessKeyId: "your-access-key"
    s3SecretAccessKey: "your-secret-key"
```

## Makefile Commands

### Installation & Deployment

| Command | Description |
|---------|-------------|
| `make install` | Install NervesHub and all dependencies |
| `make upgrade` | Upgrade existing installation |
| `make uninstall` | Uninstall NervesHub (keeps data) |
| `make reinstall` | Uninstall and reinstall |
| `make clean` | Remove all resources except namespace |
| `make purge` | Complete cleanup including namespace |

### Monitoring & Debugging

| Command | Description |
|---------|-------------|
| `make status` | Show deployment status |
| `make pods` | List all pods |
| `make logs` | Show NervesHub logs (follow mode) |
| `make logs-postgres` | Show PostgreSQL logs |
| `make logs-clickhouse` | Show ClickHouse logs |
| `make events` | Show recent Kubernetes events |
| `make describe` | Describe all resources |

### Access & Connectivity

| Command | Description |
|---------|-------------|
| `make port-forward` | Access NervesHub at localhost:4000 |
| `make port-forward-postgres` | Access PostgreSQL at localhost:5432 |
| `make port-forward-clickhouse` | Access ClickHouse at localhost:8123 |
| `make shell` | Open shell in NervesHub pod |
| `make shell-postgres` | Open shell in PostgreSQL pod |

### Database Operations

| Command | Description |
|---------|-------------|
| `make db-migrate` | Run database migrations |
| `make db-console` | Connect to PostgreSQL console |
| `make db-reset` | Reset database (destructive!) |

### Maintenance

| Command | Description |
|---------|-------------|
| `make restart` | Restart NervesHub deployment |
| `make restart-postgres` | Restart PostgreSQL |
| `make restart-clickhouse` | Restart ClickHouse |
| `make scale REPLICAS=n` | Scale NervesHub to n replicas |

### Information

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make info` | Show connection information |
| `make values` | Show current Helm values |
| `make version` | Show chart version info |

## Common Operations

### View Logs

```bash
# NervesHub application logs
make logs

# PostgreSQL logs
make logs-postgres

# ClickHouse logs
make logs-clickhouse

# Specific pod logs
make logs POD=nerves-hub-abc123
```

### Database Migrations

```bash
# Run migrations after upgrade
make db-migrate

# Access database console
make db-console
```

### Scaling

```bash
# Scale to 3 replicas
make scale REPLICAS=3

# Scale back to 1
make scale REPLICAS=1
```

### Troubleshooting

```bash
# Check overall status
make status

# View recent events
make events

# Describe resources
make describe

# Open shell in pod
make shell

# Check specific pod logs
kubectl logs -n nerves-hub <pod-name>
```

## Architecture

```
┌─────────────────────────────────────────────┐
│              Ingress (Optional)              │
│         nerves-hub.example.com              │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
         ┌─────────────────┐
         │  NervesHub Svc  │
         │   (ClusterIP)   │
         └────────┬────────┘
                  │
                  ▼
       ┌──────────────────────┐
       │  NervesHub Deploy    │
       │  (Elixir/Phoenix)    │
       │  Port: 4000          │
       └──────────────────────┘
                  │
         ┌────────┴────────┐
         ▼                 ▼
┌─────────────────┐ ┌──────────────────┐
│   PostgreSQL    │ │   ClickHouse     │
│  StatefulSet    │ │   StatefulSet    │
│   Port: 5432    │ │  Ports: 8123/9000│
└─────────────────┘ └──────────────────┘
         │                  │
         ▼                  ▼
    ┌────────┐         ┌────────┐
    │  PVC   │         │  PVC   │
    │ 10Gi   │         │ 10Gi   │
    └────────┘         └────────┘
```

## Security Considerations

1. **Change Default Secrets**: Always change `secretKeyBase` and `liveViewSigningSalt` before production deployment
2. **Database Passwords**: Change PostgreSQL password in production
3. **SSL/TLS**: Enable ingress with proper SSL certificates for production
4. **Network Policies**: Consider implementing Kubernetes Network Policies
5. **RBAC**: Use proper Kubernetes RBAC for access control
6. **S3 Credentials**: Store S3 credentials securely, consider using external secrets operator

## Production Recommendations

1. **Resource Limits**: Adjust resource requests/limits based on your load
2. **Persistence**: Use high-performance storage classes for databases
3. **Backups**: Implement regular database backups
4. **Monitoring**: Add Prometheus/Grafana monitoring
5. **High Availability**: Consider running multiple replicas with proper session management
6. **External Database**: For production, consider using managed database services
7. **S3 Storage**: Use S3 for firmware storage instead of local PVC

## Upgrading

To upgrade NervesHub to a new version:

1. Update the image tag in `values.yaml`:
```yaml
nervesHub:
  image:
    tag: "v1.2.3"  # new version
```

2. Run the upgrade:
```bash
make upgrade
```

3. Run database migrations if needed:
```bash
make db-migrate
```

## Uninstalling

```bash
# Keep data
make uninstall

# Remove everything including data
make purge
```

## Support

- NervesHub Documentation: https://github.com/nerves-hub/nerves_hub_web
- Issues: https://github.com/nerves-hub/nerves_hub_web/issues
- Nerves Community: https://elixirforum.com/c/nerves-forum

## License

This Helm chart is provided as-is. NervesHub is licensed under Apache 2.0.
