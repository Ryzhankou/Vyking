KIND_CLUSTER ?= dev-global-cluster-0

k8s-create: # Create a Kubernetes cluster using kind with the configuration specified in k8s/kind/kind-dev.yaml
	@kind create cluster --name $(KIND_CLUSTER) --config k8s/kind/kind-dev.yaml
	@$(MAKE) k8s-fix-inotify KIND_CLUSTER=$(KIND_CLUSTER)

k8s-fix-inotify: # Apply inotify limits workaround for "too many open files" (MySQL, fsnotify watchers)
	@echo "Applying inotify limits workaround for 'too many open files'..."
	@NODE=$$(kind get nodes --name $(KIND_CLUSTER) 2>/dev/null | head -1); \
	if [ -n "$$NODE" ]; then \
	  docker exec -t $$NODE sysctl -w fs.inotify.max_user_watches=1048576 2>/dev/null || true; \
	  docker exec -t $$NODE sysctl -w fs.inotify.max_user_instances=512 2>/dev/null || true; \
	  echo "Inotify limits applied."; \
	else \
	  echo "No Kind nodes found. Create cluster first: make k8s-create"; \
	fi

k8s-delete: # Delete the Kubernetes cluster named dev-global-cluster-0
	@kind delete cluster --name $(KIND_CLUSTER)

# k8s-ingress: # Apply the ingress configuration specified in k8s/ingress/ingress.yaml to the cluster
# 	@helm upgrade --install nginx-ingress oci://ghcr.io/nginx/charts/nginx-ingress --version 2.4.1 -n nginx-ingress --create-namespace -f k8s/ingress/nginx-ingress-kind-values.yaml


k8s-argocd-install: # Install Argo CD in the cluster using the official Argo CD installation manifest
# 	@kubectl config use-context kind-dev-global-cluster-0
# 	@helm repo add argo https://argoproj.github.io/argo-helm
# 	@helm repo update

# 	@helm upgrade --install argocd argo/argo-cd \
# 	  -n argocd --create-namespace \
# 	  -f k8s/argocd/argocd-values.yaml

# 	@terraform -chdir=terraform/ArgoCD init
# 	@terraform -chdir=terraform/ArgoCD plan
# 	@terraform -chdir=terraform/ArgoCD apply -auto-approve
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
	terraform -chdir=terraform/ArgoCD init

	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
	terraform -chdir=terraform/ArgoCD plan

	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
	terraform -chdir=terraform/ArgoCD apply -auto-approve

k8s-argocd-port-forward:
	@kubectl config use-context kind-dev-global-cluster-0
	@kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

k8s-argocd-password:
	@kubectl config use-context kind-dev-global-cluster-0
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Helm deployment (manual, without Argo CD). Deploy database first, then app.
helm-db-clean:
	@helm uninstall infrastructure -n game-backend --ignore-not-found 2>/dev/null || true
	@kubectl delete statefulset,service,secret,configmap,pvc,cronjob -n game-backend -l app.kubernetes.io/instance=infrastructure --ignore-not-found 2>/dev/null || true
	@kubectl delete statefulset archer-db-mysql -n game-backend --ignore-not-found 2>/dev/null || true
	@kubectl delete service archer-db-mysql archer-db-mysql-headless -n game-backend --ignore-not-found 2>/dev/null || true
	@kubectl delete secret archer-db -n game-backend --ignore-not-found 2>/dev/null || true
	@kubectl delete configmap archer-db-mysql-init -n game-backend --ignore-not-found 2>/dev/null || true
	@kubectl delete cronjob mysql-backup -n game-backend --ignore-not-found 2>/dev/null || true
	@kubectl delete pvc data-archer-db-mysql-0 data-infrastructure-archer-db-0 mysql-backup-pvc -n game-backend --ignore-not-found 2>/dev/null || true
	@sleep 2

# Reset MySQL data (fixes Error 1130 when PVC has old data). Run then sync infrastructure in Argo CD.
mysql-reset-pvc:
	@echo "Deleting MySQL PVC - data will be lost, init scripts will run on next start"
	@kubectl delete pvc data-infrastructure-archer-db-0 -n game-backend --ignore-not-found 2>/dev/null || true
	@kubectl delete pod -n game-backend -l app.kubernetes.io/name=archer-db --ignore-not-found 2>/dev/null || true
	@echo "Wait 3-5 min for MySQL to re-initialize, then: kubectl rollout restart deployment -n game-backend -l app.kubernetes.io/name=game-backend"

# Reinstall DB (clean + install). Use when migrating or fixing immutable StatefulSet errors.
helm-db-reinstall: helm-db-clean helm-db-install

helm-db-install: # Deploy MySQL + backup CronJob via Helm (same chart as Argo CD infrastructure app)
	@kubectl create namespace game-backend --dry-run=client -o yaml | kubectl apply -f -
	@helm dependency update infrastructure/mysql-chart
	@helm upgrade --install infrastructure infrastructure/mysql-chart -n game-backend --wait --timeout 5m

helm-app-install:
	@kubectl create namespace game-frontend --dry-run=client -o yaml | kubectl apply -f -
	@helm upgrade --install archer-game applications/helm_chart -n game-frontend --wait --timeout 5m

# Build images and load into Kind (run before helm-app-install-kind)
kind-build-load:
	@docker compose build frontend game-backend
	@docker pull busybox:1.36 2>/dev/null || true
	@kind load docker-image vyking-frontend:latest vyking-game-backend:latest busybox:1.36 --name $(KIND_CLUSTER)

# Install app with local images (run kind-build-load first)
helm-app-install-kind:
	@kubectl create namespace game-frontend --dry-run=client -o yaml | kubectl apply -f -
	@helm upgrade --install archer-game applications/helm_chart -n game-frontend \
		-f applications/helm_chart/values-kind.yaml --wait --timeout 5m

helm-install: helm-db-install helm-app-install

# ArgoCD Applications: infrastructure (MySQL + backup) + applications (frontend/backend)
# Use: make k8s-app-install ARGOCD_ADMIN_PASSWORD=<password>
# For Kind with local images: make kind-build-load first
# Uses current git branch by default (override with TARGET_REVISION=main)
TARGET_REVISION ?= $(shell git branch --show-current 2>/dev/null || echo main)
k8s-app-install: # Deploy ArgoCD Applications (infrastructure + app) from Git
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

k8s-app-uninstall: # Remove ArgoCD Applications
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_target_revision="$(TARGET_REVISION)" \
	terraform -chdir=terraform/App init
	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
	TF_VAR_target_revision="$(TARGET_REVISION)" \
	terraform -chdir=terraform/App destroy -auto-approve

k8s-argocd-uninstall: # Uninstall Argo CD from the cluster by deleting the argocd namespace
# 	@kubectl config use-context kind-dev-global-cluster-0
# 	@helm uninstall argocd -n argocd --ignore-not-found || true
# 	@kubectl delete namespace argocd --ignore-not-found
# 	@kubectl delete crd applications.argoproj.io --ignore-not-found
# 	@kubectl delete crd applicationsets.argoproj.io --ignore-not-found
# 	@kubectl delete crd appprojects.argoproj.io --ignore-not-found
	@terraform -chdir=terraform/ArgoCD init
	@terraform -chdir=terraform/ArgoCD destroy -auto-approve


# test: # Run tests (placeholder for actual test commands)
# 	@echo "Running tests...$(TEST_MESSAGE)"
