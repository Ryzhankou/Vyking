KIND_CLUSTER ?= dev-global-cluster-0

k8s-create: # Create a Kubernetes cluster using kind with the configuration specified in k8s/kind/kind-dev.yaml
	@kind create cluster --name $(KIND_CLUSTER) --config k8s/kind/kind-dev.yaml
# 	@$(MAKE) k8s-fix-inotify KIND_CLUSTER=$(KIND_CLUSTER)

k8s-delete: # Delete the Kubernetes cluster named dev-global-cluster-0
	@kind delete cluster --name $(KIND_CLUSTER)

# k8s-ingress: # Apply the ingress configuration specified in k8s/ingress/ingress.yaml to the cluster
# 	@helm upgrade --install nginx-ingress oci://ghcr.io/nginx/charts/nginx-ingress --version 2.4.1 -n nginx-ingress --create-namespace -f k8s/ingress/nginx-ingress-kind-values.yaml


argocd-install: # Install Argo CD in the cluster using the official Argo CD installation manifest
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
	terraform -chdir=terraform/ArgoCD init

	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
	terraform -chdir=terraform/ArgoCD plan

	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
	terraform -chdir=terraform/ArgoCD apply -auto-approve

argocd-port-forward:
	@kubectl config use-context kind-dev-global-cluster-0
	@kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

argocd-uninstall: # Uninstall Argo CD from the cluster by deleting the argocd namespace
	@terraform -chdir=terraform/ArgoCD init
	@terraform -chdir=terraform/ArgoCD destroy -auto-approve


# Build images and load into Kind (run before helm-app-install-kind)
kind-build-load:
	@docker compose build frontend game-backend
	@docker pull busybox:1.36 2>/dev/null || true
	@kind load docker-image vyking-frontend:latest vyking-game-backend:latest busybox:1.36 --name $(KIND_CLUSTER)

# ArgoCD Applications: infrastructure (MySQL + backup) + applications (frontend/backend)
# Use: make k8s-app-install ARGOCD_ADMIN_PASSWORD=<password>
# For Kind with local images: make kind-build-load first
# Uses current git branch by default (override with TARGET_REVISION=main)
TARGET_REVISION ?= $(shell git branch --show-current 2>/dev/null || echo main)
infrastructure-install: # Deploy ArgoCD Applications (infrastructure + app) from Git
	@kubectl create namespace game-backend --dry-run=client -o yaml | kubectl apply -f -
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_target_revision="$(TARGET_REVISION)" \
	terraform -chdir=terraform/infrastructure init
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_target_revision="$(TARGET_REVISION)" \
	terraform -chdir=terraform/infrastructure plan
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_target_revision="$(TARGET_REVISION)" \
	terraform -chdir=terraform/infrastructure apply -auto-approve

app-install: # Deploy ArgoCD Applications (infrastructure + app) from Git
	@kubectl create namespace game-frontend --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create namespace game-backend --dry-run=client -o yaml | kubectl apply -f -
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_target_revision="$(TARGET_REVISION)" \
	terraform -chdir=terraform/App init
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_target_revision="$(TARGET_REVISION)" \
	terraform -chdir=terraform/App plan
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_target_revision="$(TARGET_REVISION)" \
	terraform -chdir=terraform/App apply -auto-approve

app-port-forward:
	@kubectl config use-context kind-dev-global-cluster-0
	@kubectl port-forward svc/archer-game-frontend -n game-frontend 8081:80 > /dev/null 2>&1 &
# 	@kubectl port-forward svc/game-backend -n game-backend 8082:80 > /dev/null 2>&1 &

app-uninstall: # Remove ArgoCD Applications
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_target_revision="$(TARGET_REVISION)" \
	terraform -chdir=terraform/App init
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_target_revision="$(TARGET_REVISION)" \
	terraform -chdir=terraform/App destroy -auto-approve

up:
	@$(MAKE) k8s-create
	@$(MAKE) argocd-install
	@$(MAKE) argocd-port-forward
	@$(MAKE) kind-build-load
	@$(MAKE) infrastructure-install
	@$(MAKE) app-install
	@$(MAKE) app-port-forward

down:
# 	@$(MAKE) app-uninstall
# 	@$(MAKE) argocd-uninstall
	@$(MAKE) k8s-delete




