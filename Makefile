# KIND_CLUSTER ?= dev-global-cluster-0

# k8s-create: # Create a Kubernetes cluster using kind with the configuration specified in k8s/kind/kind-dev.yaml
# 	@kind create cluster --name $(KIND_CLUSTER) --config k8s/kind/kind-dev.yaml
# # 	@$(MAKE) k8s-fix-inotify KIND_CLUSTER=$(KIND_CLUSTER)

# k8s-delete: # Delete the Kubernetes cluster named dev-global-cluster-0
# 	@kind delete cluster --name $(KIND_CLUSTER)

# # k8s-ingress: # Apply the ingress configuration specified in k8s/ingress/ingress.yaml to the cluster
# # 	@helm upgrade --install nginx-ingress oci://ghcr.io/nginx/charts/nginx-ingress --version 2.4.1 -n nginx-ingress --create-namespace -f k8s/ingress/nginx-ingress-kind-values.yaml


# argocd-install: # Install Argo CD in the cluster using the official Argo CD installation manifest
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
# 	terraform -chdir=terraform/ArgoCD init

# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
# 	terraform -chdir=terraform/ArgoCD plan

# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
# 	terraform -chdir=terraform/ArgoCD apply -auto-approve

# argocd-port-forward:
# 	@kubectl config use-context kind-dev-global-cluster-0
# 	@kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

# argocd-uninstall: # Uninstall Argo CD from the cluster by deleting the argocd namespace
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
# 	terraform -chdir=terraform/ArgoCD init
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
# 	terraform -chdir=terraform/ArgoCD destroy -auto-approve


# # Build images and load into Kind (run before helm-app-install-kind)
# kind-build-load:
# 	@docker compose build frontend game-backend
# 	@docker pull busybox:1.36 2>/dev/null || true
# 	@kind load docker-image vyking-frontend:latest vyking-game-backend:latest busybox:1.36 --name $(KIND_CLUSTER)

# # ArgoCD Applications: infrastructure (MySQL + backup) + applications (frontend/backend)
# # Use: make k8s-app-install ARGOCD_ADMIN_PASSWORD=<password>
# # For Kind with local images: make kind-build-load first
# # Uses current git branch by default (override with TARGET_REVISION=main)
# TARGET_REVISION ?= $(shell git branch --show-current 2>/dev/null || echo main)
# infrastructure-install: # Deploy ArgoCD Applications (infrastructure + app) from Git
# 	@kubectl create namespace game-backend --dry-run=client -o yaml | kubectl apply -f -
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_target_revision="$(TARGET_REVISION)" \
# 	terraform -chdir=terraform/Infrastructure init
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_target_revision="$(TARGET_REVISION)" \
# 	terraform -chdir=terraform/Infrastructure plan
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_target_revision="$(TARGET_REVISION)" \
# 	terraform -chdir=terraform/Infrastructure apply -auto-approve

# infrastructure-uninstall: # Remove ArgoCD Applications
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_target_revision="$(TARGET_REVISION)" \
# 	terraform -chdir=terraform/Infrastructure init
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_target_revision="$(TARGET_REVISION)" \
# 	terraform -chdir=terraform/Infrastructure destroy -auto-approve

# app-install: # Deploy ArgoCD Applications (infrastructure + app) from Git
# 	@kubectl create namespace game-frontend --dry-run=client -o yaml | kubectl apply -f -
# 	@kubectl create namespace game-backend --dry-run=client -o yaml | kubectl apply -f -
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_target_revision="$(TARGET_REVISION)" \
# 	terraform -chdir=terraform/App init
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_target_revision="$(TARGET_REVISION)" \
# 	terraform -chdir=terraform/App plan
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_target_revision="$(TARGET_REVISION)" \
# 	terraform -chdir=terraform/App apply -auto-approve

# app-port-forward:
# 	@kubectl config use-context kind-dev-global-cluster-0
# 	@kubectl port-forward svc/archer-game-frontend -n game-frontend 8081:80 > /dev/null 2>&1 &
# # 	@kubectl port-forward svc/game-backend -n game-backend 8082:80 > /dev/null 2>&1 &

# app-uninstall: # Remove ArgoCD Applications
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_target_revision="$(TARGET_REVISION)" \
# 	terraform -chdir=terraform/App init
# 	@TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
# 	TF_VAR_target_revision="$(TARGET_REVISION)" \
# 	terraform -chdir=terraform/App destroy -auto-approve

# up:
# 	@$(MAKE) k8s-create
# 	@$(MAKE) argocd-install
# 	@$(MAKE) argocd-port-forward
# 	@$(MAKE) kind-build-load
# 	@$(MAKE) infrastructure-install
# 	@$(MAKE) app-install
# 	@$(MAKE) app-port-forward

# down:
# 	@$(MAKE) app-uninstall
# 	@$(MAKE) infrastructure-uninstall
# 	@$(MAKE) argocd-uninstall
# 	@$(MAKE) k8s-delete


###############################################################################################3
# KIND_CLUSTER ?= dev-global-cluster-0
# TARGET_REVISION ?= $(shell git branch --show-current 2>/dev/null || echo main)
# LOG_DIR ?= .logs

# TF_ARGOCD = TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
#             TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)"

# TF_APP = TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
#          TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
#          TF_VAR_target_revision="$(TARGET_REVISION)"

# .PHONY: \
# 	k8s-create k8s-delete \
# 	argocd-install argocd-port-forward argocd-uninstall \
# 	kind-build-load \
# 	infrastructure-install infrastructure-uninstall \
# 	app-install app-port-forward app-uninstall \
# 	up down

# $(LOG_DIR):
# 	@mkdir -p $(LOG_DIR)

# define info
# 	@printf "\n==> %s\n" "$(1)"
# endef

# define ok
# 	@printf "✓ %s\n" "$(1)"
# endef

# define warn
# 	@printf "! %s\n" "$(1)"
# endef

# k8s-create: | $(LOG_DIR)
# 	$(call info,Creating Kind cluster '$(KIND_CLUSTER)')
# 	@kind create cluster --name $(KIND_CLUSTER) --config k8s/kind/kind-dev.yaml > $(LOG_DIR)/kind-create.log 2>&1
# 	$(call ok,Cluster created: kind-$(KIND_CLUSTER))

# k8s-delete: | $(LOG_DIR)
# 	$(call info,Deleting Kind cluster '$(KIND_CLUSTER)')
# 	@kind delete cluster --name $(KIND_CLUSTER) > $(LOG_DIR)/kind-delete.log 2>&1
# 	$(call ok,Cluster deleted: kind-$(KIND_CLUSTER))

# argocd-install: | $(LOG_DIR)
# 	$(call info,Installing Argo CD)
# 	@$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD init > $(LOG_DIR)/argocd-init.log 2>&1
# 	@$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD apply -auto-approve > $(LOG_DIR)/argocd-apply.log 2>&1
# 	$(call ok,Argo CD installed)

# argocd-port-forward:
# 	$(call info,Starting Argo CD port-forward)
# 	@kubectl config use-context kind-$(KIND_CLUSTER) > /dev/null 2>&1
# 	@kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
# 	$(call ok,Argo CD available on http://localhost:8080)

# argocd-uninstall: | $(LOG_DIR)
# 	$(call info,Removing Argo CD)
# 	@$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD init > $(LOG_DIR)/argocd-destroy-init.log 2>&1
# 	@$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD destroy -auto-approve > $(LOG_DIR)/argocd-destroy.log 2>&1
# 	$(call ok,Argo CD removed)

# kind-build-load: | $(LOG_DIR)
# 	$(call info,Building local images)
# 	@docker compose build frontend game-backend > $(LOG_DIR)/docker-build.log 2>&1
# 	@docker pull busybox:1.36 > /dev/null 2>&1 || true
# 	$(call info,Loading images into Kind)
# 	@kind load docker-image vyking-frontend:latest vyking-game-backend:latest busybox:1.36 --name $(KIND_CLUSTER) > $(LOG_DIR)/kind-load.log 2>&1
# 	$(call ok,Images loaded into Kind)

# infrastructure-install: | $(LOG_DIR)
# 	$(call info,Installing infrastructure application)
# 	@kubectl create namespace game-backend --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
# 	@$(TF_APP) terraform -chdir=terraform/Infrastructure init > $(LOG_DIR)/infra-init.log 2>&1
# 	@$(TF_APP) terraform -chdir=terraform/Infrastructure apply -auto-approve > $(LOG_DIR)/infra-apply.log 2>&1
# 	$(call ok,MySQL/infrastructure deployed)

# infrastructure-uninstall: | $(LOG_DIR)
# 	$(call info,Removing infrastructure application)
# 	@$(TF_APP) terraform -chdir=terraform/Infrastructure init > $(LOG_DIR)/infra-destroy-init.log 2>&1
# 	@$(TF_APP) terraform -chdir=terraform/Infrastructure destroy -auto-approve > $(LOG_DIR)/infra-destroy.log 2>&1
# 	$(call ok,Infrastructure removed)

# app-install: | $(LOG_DIR)
# 	$(call info,Installing application)
# 	@kubectl create namespace game-frontend --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
# 	@kubectl create namespace game-backend --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
# 	@$(TF_APP) terraform -chdir=terraform/App init > $(LOG_DIR)/app-init.log 2>&1
# 	@$(TF_APP) terraform -chdir=terraform/App apply -auto-approve > $(LOG_DIR)/app-apply.log 2>&1
# 	$(call ok,Application deployed)

# app-port-forward:
# 	$(call info,Starting application port-forward)
# 	@kubectl config use-context kind-$(KIND_CLUSTER) > /dev/null 2>&1
# 	@kubectl port-forward svc/archer-game-frontend -n game-frontend 8081:80 > /dev/null 2>&1 &
# 	$(call ok,Application available on http://localhost:8081)

# app-uninstall: | $(LOG_DIR)
# 	$(call info,Removing application)
# 	@$(TF_APP) terraform -chdir=terraform/App init > $(LOG_DIR)/app-destroy-init.log 2>&1
# 	@$(TF_APP) terraform -chdir=terraform/App destroy -auto-approve > $(LOG_DIR)/app-destroy.log 2>&1
# 	$(call ok,Application removed)

# up:
# 	$(call info,Starting full environment deployment)
# 	@$(MAKE) --no-print-directory k8s-create
# 	@$(MAKE) --no-print-directory argocd-install
# 	@$(MAKE) --no-print-directory argocd-port-forward
# 	@$(MAKE) --no-print-directory kind-build-load
# 	@$(MAKE) --no-print-directory infrastructure-install
# 	@$(MAKE) --no-print-directory app-install
# 	@$(MAKE) --no-print-directory app-port-forward
# 	@printf "\n"
# 	$(call ok,Environment is ready)
# 	@printf "  Cluster:      kind-%s\n" "$(KIND_CLUSTER)"
# 	@printf "  Argo CD:      http://localhost:8080\n"
# 	@printf "  Application:  http://localhost:8081\n"
# 	@printf "  Git branch:   %s\n" "$(TARGET_REVISION)"
# 	@printf "  Logs:         %s/\n" "$(LOG_DIR)"

# down:
# 	$(call info,Destroying environment)
# 	@$(MAKE) --no-print-directory app-uninstall
# 	@$(MAKE) --no-print-directory infrastructure-uninstall
# 	@$(MAKE) --no-print-directory argocd-uninstall
# 	@$(MAKE) --no-print-directory k8s-delete
# 	@printf "\n"
# 	$(call ok,Environment removed)
# 	@printf "  Logs: %s/\n" "$(LOG_DIR)"

##############################################################################################

KIND_CLUSTER ?= dev-global-cluster-0
TARGET_REVISION ?= $(shell git branch --show-current 2>/dev/null || echo main)
LOG_DIR ?= .logs

.DEFAULT_GOAL := help

.PHONY: \
	help \
	k8s-create k8s-delete \
	argocd-install argocd-port-forward argocd-uninstall \
	kind-build-load \
	infrastructure-install infrastructure-uninstall \
	app-install app-port-forward app-uninstall \
	up down

help:
	@printf "\nAvailable targets:\n\n"
	@printf "  %-24s %s\n" "help" "Show this help message"
	@printf "  %-24s %s\n" "k8s-create" "Create Kind cluster"
	@printf "  %-24s %s\n" "k8s-delete" "Delete Kind cluster"
	@printf "  %-24s %s\n" "argocd-install" "Install Argo CD via Terraform"
	@printf "  %-24s %s\n" "argocd-port-forward" "Expose Argo CD on http://localhost:8080"
	@printf "  %-24s %s\n" "argocd-uninstall" "Remove Argo CD via Terraform"
	@printf "  %-24s %s\n" "kind-build-load" "Build local images and load them into Kind"
	@printf "  %-24s %s\n" "infrastructure-install" "Deploy infrastructure app (MySQL)"
	@printf "  %-24s %s\n" "infrastructure-uninstall" "Remove infrastructure app"
	@printf "  %-24s %s\n" "app-install" "Deploy application"
	@printf "  %-24s %s\n" "app-port-forward" "Expose app on http://localhost:8081"
	@printf "  %-24s %s\n" "app-uninstall" "Remove application"
	@printf "  %-24s %s\n" "up" "Create full local environment"
	@printf "  %-24s %s\n" "down" "Destroy full local environment"
	@printf "\nVariables:\n\n"
	@printf "  %-24s %s\n" "KIND_CLUSTER" "Kind cluster name (default: $(KIND_CLUSTER))"
	@printf "  %-24s %s\n" "TARGET_REVISION" "Git branch/revision for ArgoCD apps (default: $(TARGET_REVISION))"
	@printf "  %-24s %s\n" "ARGOCD_ADMIN_PASSWORD" "Required for Terraform/Argo CD auth"
	@printf "  %-24s %s\n" "ARGOCD_ADMIN_PASSWORD_MTIME" "Required for Argo CD password secret sync"
	@printf "\nExamples:\n\n"
	@printf "  make up ARGOCD_ADMIN_PASSWORD=MyStrongPassword ARGOCD_ADMIN_PASSWORD_MTIME=\"\$$(date -u -d '1 minute ago' +%%Y-%%m-%%dT%%H:%%M:%%SZ)\"\n"
	@printf "  make down ARGOCD_ADMIN_PASSWORD=MyStrongPassword ARGOCD_ADMIN_PASSWORD_MTIME=\"\$$(date -u -d '1 minute ago' +%%Y-%%m-%%dT%%H:%%M:%%SZ)\"\n"
	@printf "  make k8s-create KIND_CLUSTER=my-test-cluster\n\n"

TF_ARGOCD = TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
            TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)"

TF_APP = TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
         TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)" \
         TF_VAR_target_revision="$(TARGET_REVISION)"

.PHONY: \
	k8s-create k8s-delete \
	argocd-install argocd-port-forward argocd-uninstall \
	kind-build-load \
	infrastructure-install infrastructure-uninstall \
	app-install app-port-forward app-uninstall \
	up down

$(LOG_DIR):
	@mkdir -p $(LOG_DIR)

define info
	@printf "\n==> %s\n" "$(1)"
endef

define ok
	@printf "✓ %s\n" "$(1)"
endef

define step
	@printf "\n[%s] %s\n" "$(1)" "$(2)"
endef

define run_step
	@printf "   -> %s\n" "$(1)"
	@bash -c '$(2)' > $(3) 2>&1 || { \
		printf "✗ Failed at: %s\n" "$(1)"; \
		printf "  See log: %s\n" "$(3)"; \
		exit 1; \
	}
endef

k8s-create: | $(LOG_DIR)
	$(call step,1/7,Creating Kind cluster '$(KIND_CLUSTER)')
	$(call run_step,creating Kind cluster,kind create cluster --name $(KIND_CLUSTER) --config k8s/kind/kind-dev.yaml,$(LOG_DIR)/kind-create.log)
	$(call ok,Cluster created: kind-$(KIND_CLUSTER))

k8s-delete: | $(LOG_DIR)
	$(call step,4/4,Deleting Kind cluster '$(KIND_CLUSTER)')
	$(call run_step,deleting Kind cluster,kind delete cluster --name $(KIND_CLUSTER),$(LOG_DIR)/kind-delete.log)
	$(call ok,Cluster deleted: kind-$(KIND_CLUSTER))

argocd-install: | $(LOG_DIR)
	$(call step,2/7,Installing Argo CD)
	$(call run_step,initializing Terraform for Argo CD,$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD init,$(LOG_DIR)/argocd-init.log)
	$(call run_step,applying Argo CD resources,$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD apply -auto-approve,$(LOG_DIR)/argocd-apply.log)
	$(call ok,Argo CD installed)

argocd-port-forward:
	$(call step,3/7,Starting Argo CD port-forward)
	@kubectl config use-context kind-$(KIND_CLUSTER) > /dev/null 2>&1
	@kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
	$(call ok,Argo CD available on http://localhost:8080)

argocd-uninstall: | $(LOG_DIR)
	$(call step,3/4,Removing Argo CD)
	$(call run_step,initializing Terraform for Argo CD removal,$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD init,$(LOG_DIR)/argocd-destroy-init.log)
	$(call run_step,destroying Argo CD resources,$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD destroy -auto-approve,$(LOG_DIR)/argocd-destroy.log)
	$(call ok,Argo CD removed)

kind-build-load: | $(LOG_DIR)
	$(call step,4/7,Building and loading local images)
	$(call run_step,building Docker images,docker compose build frontend game-backend,$(LOG_DIR)/docker-build.log)
	@docker pull busybox:1.36 > /dev/null 2>&1 || true
	$(call run_step,loading Docker images into Kind,kind load docker-image vyking-frontend:latest vyking-game-backend:latest busybox:1.36 --name $(KIND_CLUSTER),$(LOG_DIR)/kind-load.log)
	$(call ok,Images loaded into Kind)

infrastructure-install: | $(LOG_DIR)
	$(call step,5/7,Installing infrastructure application)
	@kubectl create namespace game-backend --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
	$(call run_step,initializing Terraform for infrastructure,$(TF_APP) terraform -chdir=terraform/Infrastructure init,$(LOG_DIR)/infra-init.log)
	$(call run_step,applying infrastructure resources,$(TF_APP) terraform -chdir=terraform/Infrastructure apply -auto-approve,$(LOG_DIR)/infra-apply.log)
	$(call ok,MySQL/infrastructure deployed)

infrastructure-uninstall: | $(LOG_DIR)
	$(call step,2/4,Removing infrastructure application)
	$(call run_step,initializing Terraform for infrastructure removal,$(TF_APP) terraform -chdir=terraform/Infrastructure init,$(LOG_DIR)/infra-destroy-init.log)
	$(call run_step,destroying infrastructure resources,$(TF_APP) terraform -chdir=terraform/Infrastructure destroy -auto-approve,$(LOG_DIR)/infra-destroy.log)
	$(call ok,Infrastructure removed)

app-install: | $(LOG_DIR)
	$(call step,6/7,Installing application)
	@kubectl create namespace game-frontend --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
	@kubectl create namespace game-backend --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
	$(call run_step,initializing Terraform for application,$(TF_APP) terraform -chdir=terraform/App init,$(LOG_DIR)/app-init.log)
	$(call run_step,applying application resources,$(TF_APP) terraform -chdir=terraform/App apply -auto-approve,$(LOG_DIR)/app-apply.log)
	$(call ok,Application deployed)

app-port-forward:
	$(call step,7/7,Starting application port-forward)
	@kubectl config use-context kind-$(KIND_CLUSTER) > /dev/null 2>&1
	@kubectl port-forward svc/archer-game-frontend -n game-frontend 8081:80 > /dev/null 2>&1 &
	$(call ok,Application available on http://localhost:8081)

app-uninstall: | $(LOG_DIR)
	$(call step,1/4,Removing application)
	$(call run_step,initializing Terraform for application removal,$(TF_APP) terraform -chdir=terraform/App init,$(LOG_DIR)/app-destroy-init.log)
	$(call run_step,destroying application resources,$(TF_APP) terraform -chdir=terraform/App destroy -auto-approve,$(LOG_DIR)/app-destroy.log)
	$(call ok,Application removed)

up:
	$(call info,Starting full environment deployment)
	@$(MAKE) --no-print-directory k8s-create
	@$(MAKE) --no-print-directory argocd-install
	@$(MAKE) --no-print-directory argocd-port-forward
	@$(MAKE) --no-print-directory kind-build-load
	@$(MAKE) --no-print-directory infrastructure-install
	@$(MAKE) --no-print-directory app-install
	@$(MAKE) --no-print-directory app-port-forward
	@printf "\n"
	$(call ok,Environment is ready)
	@printf "  Cluster:      kind-%s\n" "$(KIND_CLUSTER)"
	@printf "  Argo CD:      http://localhost:8080\n"
	@printf "  Application:  http://localhost:8081\n"
	@printf "  Git branch:   %s\n" "$(TARGET_REVISION)"
	@printf "  Logs:         %s/\n" "$(LOG_DIR)"

down:
	$(call info,Destroying environment)
	@$(MAKE) --no-print-directory app-uninstall
	@$(MAKE) --no-print-directory infrastructure-uninstall
	@$(MAKE) --no-print-directory argocd-uninstall
	@$(MAKE) --no-print-directory k8s-delete
	@printf "\n"
	$(call ok,Environment removed)
	@printf "  Logs: %s/\n" "$(LOG_DIR)"
