# NervesHub Kubernetes Deployment Makefile
# This Makefile provides common operations for deploying and managing NervesHub

.PHONY: help
.DEFAULT_GOAL := help

# Variables
NAMESPACE ?= nerves-hub
RELEASE_NAME ?= nerves-hub
CHART_PATH ?= .
VALUES_FILE ?= values.yaml
SECRETS_FILE ?= sealed-secrets/sealed-secret-unified.yaml

# Build values file arguments
VALUES_ARGS := -f $(VALUES_FILE)

# Colors for output using printf
GREEN  = \033[0;32m
YELLOW = \033[0;33m
BLUE   = \033[0;34m
RESET  = \033[0m

help: ## Show this help message
	@printf "$(BLUE)NervesHub Kubernetes Deployment$(RESET)\n\n"
	@printf "$(YELLOW)Available targets:$(RESET)\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}'

## Setup and Installation

namespace: ## Create the namespace
	@echo -e "$(BLUE)Creating namespace $(NAMESPACE)...$(RESET)"
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

deps: ## Update Helm chart dependencies
	@echo -e "$(BLUE)Updating Helm dependencies...$(RESET)"
	helm dependency update $(CHART_PATH)

validate: ## Validate the Helm chart
	@echo -e "$(BLUE)Validating Helm chart...$(RESET)"
	helm lint $(CHART_PATH)

template: ## Generate Kubernetes manifests without installing
	@echo -e "$(BLUE)Generating Kubernetes manifests...$(RESET)"
	helm template $(RELEASE_NAME) $(CHART_PATH) -n $(NAMESPACE) $(VALUES_ARGS)

dry-run: namespace deps ## Perform a dry-run installation
	@echo -e "$(BLUE)Performing dry-run installation...$(RESET)"
	helm install $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		--dry-run \
		--debug \
		$(VALUES_ARGS)

install: namespace deps ## Install NervesHub
	@echo -e "$(BLUE)Installing NervesHub...$(RESET)"
	helm install $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		$(VALUES_ARGS)
	@echo -e "$(GREEN)NervesHub installed successfully!$(RESET)"
	@echo -e ""
	@$(MAKE) status

upgrade: deps ## Upgrade NervesHub
	@echo -e "$(BLUE)Upgrading NervesHub...$(RESET)"
	helm upgrade $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		$(VALUES_ARGS)
	@echo -e "$(GREEN)NervesHub upgraded successfully!$(RESET)"

reinstall: uninstall install ## Uninstall and reinstall NervesHub

uninstall: ## Uninstall NervesHub
	@echo -e "$(YELLOW)Uninstalling NervesHub...$(RESET)"
	helm uninstall $(RELEASE_NAME) -n $(NAMESPACE) || true
	@echo -e "$(GREEN)NervesHub uninstalled!$(RESET)"

## Monitoring and Debugging

status: ## Show deployment status
	@echo -e "$(BLUE)Helm Release Status:$(RESET)"
	@helm status $(RELEASE_NAME) -n $(NAMESPACE) 2>/dev/null || echo "Release not found"
	@echo -e ""
	@echo -e "$(BLUE)Pods:$(RESET)"
	@kubectl get pods -n $(NAMESPACE)
	@echo -e ""
	@echo -e "$(BLUE)Services:$(RESET)"
	@kubectl get svc -n $(NAMESPACE)
	@echo -e ""
	@echo -e "$(BLUE)PVCs:$(RESET)"
	@kubectl get pvc -n $(NAMESPACE)

pods: ## List all pods
	@kubectl get pods -n $(NAMESPACE) -o wide

logs: ## Show logs from NervesHub pod (use POD=<name> to specify)
	@if [ -z "$(POD)" ]; then \
		POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/name=nerves-hub -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
		if [ -z "$$POD" ]; then \
			echo -e "$(YELLOW)No NervesHub pods found$(RESET)"; \
			exit 1; \
		fi; \
		echo -e "$(BLUE)Showing logs for $$POD$(RESET)"; \
		kubectl logs -n $(NAMESPACE) $$POD -f; \
	else \
		echo -e "$(BLUE)Showing logs for $(POD)$(RESET)"; \
		kubectl logs -n $(NAMESPACE) $(POD) -f; \
	fi

logs-postgres: ## Show logs from PostgreSQL pod
	@POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$POD" ]; then \
		echo -e "$(YELLOW)No PostgreSQL pods found$(RESET)"; \
		exit 1; \
	fi; \
	echo -e "$(BLUE)Showing logs for $$POD$(RESET)"; \
	kubectl logs -n $(NAMESPACE) $$POD -f

logs-clickhouse: ## Show logs from ClickHouse pod
	@POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/component=clickhouse -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$POD" ]; then \
		echo -e "$(YELLOW)No ClickHouse pods found$(RESET)"; \
		exit 1; \
	fi; \
	echo -e "$(BLUE)Showing logs for $$POD$(RESET)"; \
	kubectl logs -n $(NAMESPACE) $$POD -f

describe: ## Describe all resources
	@echo -e "$(BLUE)Deployments:$(RESET)"
	@kubectl describe deployment -n $(NAMESPACE)
	@echo -e ""
	@echo -e "$(BLUE)StatefulSets:$(RESET)"
	@kubectl describe statefulset -n $(NAMESPACE)
	@echo -e ""
	@echo -e "$(BLUE)Services:$(RESET)"
	@kubectl describe svc -n $(NAMESPACE)

events: ## Show recent events
	@kubectl get events -n $(NAMESPACE) --sort-by='.lastTimestamp'

## Access and Connectivity

port-forward: ## Port-forward to access NervesHub locally (http://localhost:4000)
	@echo -e "$(BLUE)Port-forwarding to NervesHub...$(RESET)"
	@echo -e "$(GREEN)Access NervesHub at: http://localhost:4000$(RESET)"
	@POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/name=nerves-hub -o jsonpath='{.items[0].metadata.name}'); \
	kubectl port-forward -n $(NAMESPACE) $$POD 4000:4000

port-forward-postgres: ## Port-forward to PostgreSQL (localhost:5432)
	@echo -e "$(BLUE)Port-forwarding to PostgreSQL...$(RESET)"
	@echo -e "$(GREEN)Connect to: localhost:5432$(RESET)"
	@POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}'); \
	kubectl port-forward -n $(NAMESPACE) $$POD 5432:5432

port-forward-clickhouse: ## Port-forward to ClickHouse (localhost:8123)
	@echo -e "$(BLUE)Port-forwarding to ClickHouse...$(RESET)"
	@echo -e "$(GREEN)Access ClickHouse at: http://localhost:8123$(RESET)"
	@POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/component=clickhouse -o jsonpath='{.items[0].metadata.name}'); \
	kubectl port-forward -n $(NAMESPACE) $$POD 8123:8123 9000:9000

shell: ## Open a shell in NervesHub pod
	@POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/name=nerves-hub -o jsonpath='{.items[0].metadata.name}'); \
	echo -e "$(BLUE)Opening shell in $$POD$(RESET)"; \
	kubectl exec -it -n $(NAMESPACE) $$POD -- /bin/sh

shell-postgres: ## Open a shell in PostgreSQL pod
	@POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}'); \
	echo -e "$(BLUE)Opening shell in $$POD$(RESET)"; \
	kubectl exec -it -n $(NAMESPACE) $$POD -- /bin/bash

## Database Operations

db-migrate: ## Run database migrations
	@echo -e "$(BLUE)Running database migrations...$(RESET)"
	@POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/name=nerves-hub -o jsonpath='{.items[0].metadata.name}'); \
	kubectl exec -n $(NAMESPACE) $$POD -- mix ecto.migrate

db-reset: ## Reset the database (WARNING: destructive!)
	@echo -e "$(YELLOW)WARNING: This will delete all data!$(RESET)"
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/name=nerves-hub -o jsonpath='{.items[0].metadata.name}'); \
		kubectl exec -n $(NAMESPACE) $$POD -- mix ecto.reset; \
	else \
		echo -e "$(GREEN)Cancelled$(RESET)"; \
	fi

db-console: ## Connect to PostgreSQL console
	@POD=$$(kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}'); \
	echo -e "$(BLUE)Connecting to PostgreSQL console...$(RESET)"; \
	kubectl exec -it -n $(NAMESPACE) $$POD -- psql -U postgres -d nerves_hub

## Maintenance

restart: ## Restart NervesHub deployment
	@echo -e "$(BLUE)Restarting NervesHub...$(RESET)"
	kubectl rollout restart deployment/$(RELEASE_NAME) -n $(NAMESPACE)
	kubectl rollout status deployment/$(RELEASE_NAME) -n $(NAMESPACE)

restart-postgres: ## Restart PostgreSQL
	@echo -e "$(BLUE)Restarting PostgreSQL...$(RESET)"
	kubectl rollout restart statefulset/$(RELEASE_NAME)-postgresql -n $(NAMESPACE)

restart-clickhouse: ## Restart ClickHouse
	@echo -e "$(BLUE)Restarting ClickHouse...$(RESET)"
	kubectl rollout restart statefulset/$(RELEASE_NAME)-clickhouse -n $(NAMESPACE)

scale: ## Scale NervesHub (use REPLICAS=n)
	@if [ -z "$(REPLICAS)" ]; then \
		echo -e "$(YELLOW)Usage: make scale REPLICAS=n$(RESET)"; \
		exit 1; \
	fi
	@echo -e "$(BLUE)Scaling NervesHub to $(REPLICAS) replicas...$(RESET)"
	kubectl scale deployment/$(RELEASE_NAME) -n $(NAMESPACE) --replicas=$(REPLICAS)

## Cleanup

clean: ## Clean up all resources (keeps namespace)
	@echo -e "$(YELLOW)Cleaning up resources...$(RESET)"
	@$(MAKE) uninstall
	@kubectl delete pvc --all -n $(NAMESPACE) || true
	@echo -e "$(GREEN)Cleanup complete!$(RESET)"

purge: clean ## Complete cleanup including namespace
	@echo -e "$(YELLOW)Deleting namespace $(NAMESPACE)...$(RESET)"
	kubectl delete namespace $(NAMESPACE) || true
	@echo -e "$(GREEN)Purge complete!$(RESET)"

## Configuration

values: ## Show current values
	@helm get values $(RELEASE_NAME) -n $(NAMESPACE)

config: ## Show ConfigMap
	@kubectl get configmap $(RELEASE_NAME)-config -n $(NAMESPACE) -o yaml

secrets: ## Show Secrets (names only)
	@kubectl get secrets -n $(NAMESPACE)

## SealedSecrets Management

CONTROLLER_NAME ?= sealed-secrets
CONTROLLER_NAMESPACE ?= kube-system
UNSEALED_SECRET ?= secrets.yaml

.PHONY: apply-sealed-secret install-sealed-secrets-controller

seal-secrets: $(SECRETS_FILE) ## Seal secrets (runs when secrets.yaml is updated)

$(SECRETS_FILE): $(UNSEALED_SECRET) certs/key.pem certs/cert.pem
	@echo -e "$(BLUE)Sealing secrets...$(RESET)"
	@mkdir -p sealed-secrets
	@echo -e "$(YELLOW)Injecting SSL certificates into secret...$(RESET)"
	@kubectl create secret generic nerves-hub-unified \
		--from-literal=DEVICE_SSL_KEY="$$(base64 -w 0 certs/key.pem)" \
		--from-literal=DEVICE_SSL_CERT="$$(base64 -w 0 certs/cert.pem)" \
		--from-literal=DATABASE_URL="$$(grep 'DATABASE_URL:' $(UNSEALED_SECRET) | cut -d'"' -f2)" \
		--from-literal=CLICKHOUSE_URL="$$(grep 'CLICKHOUSE_URL:' $(UNSEALED_SECRET) | cut -d'"' -f2)" \
		--from-literal=SECRET_KEY_BASE="$$(grep 'SECRET_KEY_BASE:' $(UNSEALED_SECRET) | cut -d'"' -f2)" \
		--from-literal=LIVE_VIEW_SIGNING_SALT="$$(grep 'LIVE_VIEW_SIGNING_SALT:' $(UNSEALED_SECRET) | cut -d'"' -f2)" \
		--from-literal=password="$$(grep '^  password:' $(UNSEALED_SECRET) | cut -d'"' -f2)" \
		--from-literal=postgres-password="$$(grep 'postgres-password:' $(UNSEALED_SECRET) | cut -d'"' -f2)" \
		--namespace $(NAMESPACE) \
		--dry-run=client -o yaml | \
	kubeseal \
		--controller-name $(CONTROLLER_NAME) \
		--controller-namespace $(CONTROLLER_NAMESPACE) \
		--format yaml \
		--namespace $(NAMESPACE) \
		> $(SECRETS_FILE)
	@echo -e "$(GREEN)✓ Secrets sealed successfully with certificates!$(RESET)"

apply-sealed-secret: ## Apply the sealed secret to the cluster
	@echo -e "$(BLUE)Applying sealed secret...$(RESET)"
	@if [ ! -f "$(SECRETS_FILE)" ]; then \
		echo -e "$(YELLOW)Error: $(SECRETS_FILE) not found$(RESET)"; \
		echo -e "$(YELLOW)Run 'make seal-secrets' first$(RESET)"; \
		exit 1; \
	fi
	kubectl apply -f $(SECRETS_FILE)
	@echo -e "$(GREEN)Sealed secret applied!$(RESET)"

show-sealed-secrets: ## Show all SealedSecrets
	@kubectl get sealedsecrets -n $(NAMESPACE) 2>/dev/null || echo "No SealedSecrets found or sealed-secrets controller not installed"

install-sealed-secrets-controller: ## Install sealed-secrets controller
	@echo -e "$(BLUE)Installing sealed-secrets controller...$(RESET)"
	@helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
	@helm repo update
	@helm install sealed-secrets sealed-secrets/sealed-secrets -n kube-system --create-namespace
	@echo -e "$(GREEN)Sealed-secrets controller installed!$(RESET)"
	@echo -e "$(YELLOW)Wait for the controller to be ready before sealing secrets$(RESET)"

## Information

info: ## Show connection information
	@echo -e "$(BLUE)NervesHub Connection Information:$(RESET)"
	@echo -e ""
	@echo -e "$(GREEN)Namespace:$(RESET) $(NAMESPACE)"
	@echo -e "$(GREEN)Release:$(RESET) $(RELEASE_NAME)"
	@echo -e ""
	@echo -e "$(BLUE)To access NervesHub locally:$(RESET)"
	@echo -e "  make port-forward"
	@echo -e "  then visit: http://localhost:4000"
	@echo -e ""
	@echo -e "$(BLUE)To view logs:$(RESET)"
	@echo -e "  make logs"
	@echo -e ""
	@echo -e "$(BLUE)To check status:$(RESET)"
	@echo -e "  make status"

version: ## Show Helm chart version
	@helm list -n $(NAMESPACE) -o json | jq -r '.[] | select(.name == "$(RELEASE_NAME)") | "Chart: \(.chart)\nApp Version: \(.app_version)\nStatus: \(.status)"'
