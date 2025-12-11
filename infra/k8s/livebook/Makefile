.PHONY: install upgrade uninstall status logs port-forward help

RELEASE_NAME := livebook
NAMESPACE := livebook
CHART := oci://ghcr.io/mruoss/charts/livebook

help:
	@echo "Available targets:"
	@echo "  make install      - Install Livebook using Helm"
	@echo "  make upgrade      - Upgrade Livebook deployment"
	@echo "  make uninstall    - Uninstall Livebook"
	@echo "  make status       - Check Livebook deployment status"
	@echo "  make logs         - View Livebook logs"
	@echo "  make port-forward - Forward Livebook to localhost:9000"

# Install Livebook
install:
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm install $(RELEASE_NAME) $(CHART) \
		--namespace $(NAMESPACE) \
		--values values.yaml \
		--wait
	@echo ""
	@echo "Livebook installed successfully!"
	@echo "Check service with: make status"

# Upgrade Livebook
upgrade:
	helm upgrade $(RELEASE_NAME) $(CHART) \
		--namespace $(NAMESPACE) \
		--values values.yaml \
		--wait

# Uninstall Livebook
uninstall:
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)
	kubectl delete namespace $(NAMESPACE)

# Check status
status:
	@echo "=== Helm Release ==="
	helm status $(RELEASE_NAME) -n $(NAMESPACE)
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -n $(NAMESPACE)
	@echo ""
	@echo "=== Service ==="
	kubectl get svc -n $(NAMESPACE)

# View logs
logs:
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=livebook -f

# Port forward to localhost
port-forward:
	@echo "Forwarding Livebook to http://localhost:9000"
	kubectl port-forward -n $(NAMESPACE) svc/livebook 9000:9000
