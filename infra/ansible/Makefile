.PHONY: ping install-k3s uninstall-k3s status install-cert-manager help

help:
	@echo "Available targets:"
	@echo "  make ping              - Test connection to main_server"
	@echo "  make install-k3s       - Install K3s on main_server"
	@echo "  make install-cert-manager - Install cert-manager on K3s"
	@echo "  make status            - Check K3s status on main_server"
	@echo "  make uninstall-k3s     - Uninstall K3s from main_server"

# Test connection
ping:
	ansible all -m ping

# Install K3s
install-k3s:
	ansible-playbook install-k3s.yml

# Install cert-manager
install-cert-manager:
	ansible-playbook install-cert-manager.yml

# Check K3s status
status:
	ansible main_server -b -m shell -a "kubectl get nodes"

# Uninstall K3s
uninstall-k3s:
	ansible main_server -b -m shell -a "/usr/local/bin/k3s-uninstall.sh"
