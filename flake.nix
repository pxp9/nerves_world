{
  description = "Infrastructure tools environment with Claude CLI, Terraform, and Ansible";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Claude CLI
            claude-code

            # Terraform
            terraform
            terraform-ls

            # Ansible
            ansible
            ansible-lint

            # Kubernetes
            kubectl
            kubernetes-helm
          ];

          shellHook = ''
            echo "Infrastructure Tools Environment"
            echo "================================"
            echo "Claude CLI: $(claude --version 2>/dev/null || echo 'installed')"
            echo "Terraform: $(terraform version | head -n1)"
            echo "Ansible: $(ansible --version | head -n1)"
            echo "Kubectl: $(kubectl version --client 2>/dev/null | grep 'Client Version' || echo 'installed')"
            echo "Helm: $(helm version --short 2>/dev/null || echo 'installed')"
            echo ""

            # Set KUBECONFIG if k3s-kubeconfig.yaml exists
            if [ -f "infra/ansible/k3s-kubeconfig.yaml" ]; then
              export KUBECONFIG="$(pwd)/infra/ansible/k3s-kubeconfig.yaml"
              echo "KUBECONFIG set to: $KUBECONFIG"
            else
              echo "Note: K3s kubeconfig not found. Run 'make install-k3s' in infra/ansible/"
            fi

            echo ""
            echo "Ready to use!"
          '';
        };
      }
    );
}
