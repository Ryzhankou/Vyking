KIND_CLUSTER ?= dev-global-cluster-0
TARGET_REVISION ?= $(shell git branch --show-current 2>/dev/null || echo main)
# Auto-generated: required by ArgoCD to recognize password changes on re-installs.
# Override only if ArgoCD is already running and the password needs to be updated.
ARGOCD_ADMIN_PASSWORD_MTIME ?= $(shell date -u -d '1 minute ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-1M +%Y-%m-%dT%H:%M:%SZ)
LOG_DIR ?= .logs

# MySQL backup/restore (must match infrastructure helm release)
MYSQL_NS ?= game-backend
MYSQL_RELEASE ?= infrastructure
MYSQL_BACKUP_PVC ?= $(MYSQL_RELEASE)-backup-pvc
RESTORE_JOB_TEMPLATE = infrastructure/mysql-chart/restore-job.yaml
RESTORE_LIST_TEMPLATE = infrastructure/mysql-chart/restore-job-list.yaml

.DEFAULT_GOAL := help

.PHONY: \
	help \
	k8s-create k8s-delete \
	argocd-install argocd-port-forward argocd-uninstall \
	kind-build-load \
	app-install app-wait app-port-forward app-uninstall \
	mysql-list-backups mysql-restore \
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
	@printf "  %-24s %s\n" "app-install" "Deploy both Argo CD Applications (infrastructure + frontend/backend)"
	@printf "  %-24s %s\n" "app-wait" "Wait for frontend and backend deployments to be ready"
	@printf "  %-24s %s\n" "app-port-forward" "Expose app on http://localhost:8081"
	@printf "  %-24s %s\n" "app-uninstall" "Remove application"
	@printf "  %-24s %s\n" "mysql-list-backups" "List available MySQL backups"
	@printf "  %-24s %s\n" "mysql-restore" "Restore MySQL from backup (use BACKUP_FILE= for specific)"
	@printf "  %-24s %s\n" "up" "Create full local environment"
	@printf "  %-24s %s\n" "down" "Destroy full local environment"
	@printf "\nVariables:\n\n"
	@printf "  %-24s %s\n" "KIND_CLUSTER" "Kind cluster name (default: $(KIND_CLUSTER))"
	@printf "  %-24s %s\n" "TARGET_REVISION" "Git branch/revision for ArgoCD apps (default: $(TARGET_REVISION))"
	@printf "  %-24s %s\n" "ARGOCD_ADMIN_PASSWORD" "Required: password for Argo CD admin user"
	@printf "  %-24s %s\n" "ARGOCD_ADMIN_PASSWORD_MTIME" "Auto-generated (override only when updating password on live ArgoCD)"
	@printf "  %-24s %s\n" "TARGET_REVISION" "Git branch for Argo CD to sync (default: current branch)"
	@printf "\nExamples:\n\n"
	@printf "  make up ARGOCD_ADMIN_PASSWORD=MyStrongPassword\n"
	@printf "  make down ARGOCD_ADMIN_PASSWORD=MyStrongPassword\n"
	@printf "  make k8s-create KIND_CLUSTER=my-test-cluster\n"
	@printf "  make mysql-restore\n"
	@printf "  make mysql-restore BACKUP_FILE=gamedb_20250321_120000.sql.gz\n\n"

TF_ARGOCD = TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
            TF_VAR_argocd_admin_password_mtime="$(ARGOCD_ADMIN_PASSWORD_MTIME)"

TF_APP = TF_VAR_argocd_admin_password="$(ARGOCD_ADMIN_PASSWORD)" \
         TF_VAR_target_revision="$(TARGET_REVISION)"

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
	$(call step,1/6,Creating Kind cluster '$(KIND_CLUSTER)')
	@if kind get clusters 2>/dev/null | grep -qx "$(KIND_CLUSTER)"; then \
		printf "   -> Cluster 'kind-$(KIND_CLUSTER)' already exists, skipping creation\n"; \
		kubectl config use-context kind-$(KIND_CLUSTER) > /dev/null 2>&1; \
	else \
		printf "   -> creating Kind cluster\n"; \
		kind create cluster --name $(KIND_CLUSTER) --config k8s/kind/kind-dev.yaml > $(LOG_DIR)/kind-create.log 2>&1 || { \
			printf "✗ Failed at: creating Kind cluster\n"; \
			printf "  See log: $(LOG_DIR)/kind-create.log\n"; \
			exit 1; \
		}; \
	fi
	$(call ok,Cluster ready: kind-$(KIND_CLUSTER))
	@printf "\n"
	@kubectl get nodes -o custom-columns="NAME:.metadata.name,STATUS:.status.conditions[-1].type,ROLES:.metadata.labels.kubernetes\.io/role,VERSION:.status.nodeInfo.kubeletVersion,IP:.status.addresses[0].address"

k8s-delete: | $(LOG_DIR)
	$(call step,3/3,Deleting Kind cluster '$(KIND_CLUSTER)')
	$(call run_step,deleting Kind cluster,kind delete cluster --name $(KIND_CLUSTER),$(LOG_DIR)/kind-delete.log)
	$(call ok,Cluster deleted: kind-$(KIND_CLUSTER))

argocd-install: | $(LOG_DIR)
	$(call step,2/6,Installing Argo CD)
	$(call run_step,initializing Terraform for Argo CD,$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD init,$(LOG_DIR)/argocd-init.log)
	$(call run_step,applying Argo CD resources,$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD apply -auto-approve,$(LOG_DIR)/argocd-apply.log)
	$(call ok,Argo CD installed)

argocd-port-forward:
	$(call step,3/6,Starting Argo CD port-forward)
	@kubectl config use-context kind-$(KIND_CLUSTER) > /dev/null 2>&1
	@kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s > /dev/null 2>&1
	@kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
	$(call ok,Argo CD available on http://localhost:8080)

argocd-uninstall: | $(LOG_DIR)
	$(call step,2/3,Removing Argo CD)
	$(call run_step,initializing Terraform for Argo CD removal,$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD init,$(LOG_DIR)/argocd-destroy-init.log)
	$(call run_step,destroying Argo CD resources,$(TF_ARGOCD) terraform -chdir=terraform/ArgoCD destroy -auto-approve,$(LOG_DIR)/argocd-destroy.log)
	$(call ok,Argo CD removed)

kind-build-load: | $(LOG_DIR)
	$(call step,4/6,Building and loading local images)
	$(call run_step,building Docker images,docker compose build frontend game-backend,$(LOG_DIR)/docker-build.log)
	@docker pull busybox:1.36 > /dev/null 2>&1 || true
	@docker pull mysql:8.0 > /dev/null 2>&1 || true
	$(call run_step,loading Docker images into Kind,kind load docker-image vyking-frontend:latest vyking-game-backend:latest busybox:1.36 mysql:8.0 --name $(KIND_CLUSTER),$(LOG_DIR)/kind-load.log)
	$(call ok,Images loaded into Kind)

app-install: | $(LOG_DIR)
	$(call step,5/6,Deploying Argo CD Applications (infrastructure + app))
	@kubectl create namespace game-frontend --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
	@kubectl create namespace game-backend --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
	$(call run_step,initializing Terraform for applications,$(TF_APP) terraform -chdir=terraform/App init,$(LOG_DIR)/app-init.log)
	$(call run_step,applying both Argo CD Applications,$(TF_APP) terraform -chdir=terraform/App apply -auto-approve,$(LOG_DIR)/app-apply.log)
	$(call ok,Infrastructure and application deployed)

app-wait:
	$(call step,6/7,Waiting for application resources)
	@kubectl config use-context kind-$(KIND_CLUSTER) > /dev/null 2>&1
	@printf "   -> Waiting for frontend deployment...\n"
	@until kubectl get deployment myapp-archer-game-frontend -n game-frontend > /dev/null 2>&1; do \
		sleep 2; \
	done
	@kubectl wait --for=condition=available deployment/myapp-archer-game-frontend -n game-frontend --timeout=300s > /dev/null 2>&1
	@printf "   -> Waiting for backend deployment...\n"
	@until kubectl get deployment myapp-archer-game-backend -n game-backend > /dev/null 2>&1; do \
		sleep 2; \
	done
	@kubectl wait --for=condition=available deployment/myapp-archer-game-backend -n game-backend --timeout=300s > /dev/null 2>&1
	$(call ok,Frontend and backend are ready)

app-port-forward:
	$(call step,7/7,Starting application port-forward)
	@kubectl config use-context kind-$(KIND_CLUSTER) > /dev/null 2>&1
	@kubectl port-forward svc/myapp-archer-game-frontend -n game-frontend 8081:80 > /dev/null 2>&1 &
	$(call ok,Application available on http://localhost:8081)

app-uninstall: | $(LOG_DIR)
	$(call step,1/3,Removing Argo CD Applications (infrastructure + app))
	$(call run_step,initializing Terraform for applications removal,$(TF_APP) terraform -chdir=terraform/App init,$(LOG_DIR)/app-destroy-init.log)
	$(call run_step,destroying both Argo CD Applications,$(TF_APP) terraform -chdir=terraform/App destroy -auto-approve,$(LOG_DIR)/app-destroy.log)
	$(call ok,Applications removed)

mysql-list-backups:
	$(call info,Listing MySQL backups)
	@kubectl config use-context kind-$(KIND_CLUSTER) > /dev/null 2>&1
	@JOB_NAME="mysql-backup-list-$$(date +%s)"; \
		sed -e 's|__MYSQL_NS__|$(MYSQL_NS)|g' \
		    -e 's|__BACKUP_PVC__|$(MYSQL_BACKUP_PVC)|g' \
		    -e "s|__JOB_NAME__|$$JOB_NAME|g" \
		    $(RESTORE_LIST_TEMPLATE) | kubectl apply -f -; \
		kubectl wait --for=condition=complete job/$$JOB_NAME -n $(MYSQL_NS) --timeout=60s 2>/dev/null || true; \
		kubectl logs job/$$JOB_NAME -n $(MYSQL_NS) 2>/dev/null || true; \
		kubectl delete job $$JOB_NAME -n $(MYSQL_NS) --ignore-not-found 2>/dev/null || true
	$(call ok,Done)

mysql-restore: | $(LOG_DIR)
	$(call info,Restoring MySQL from backup)
	@kubectl config use-context kind-$(KIND_CLUSTER) > /dev/null 2>&1
	@JOB_NAME="mysql-restore-$$(date +%s)"; \
		sed -e 's|__MYSQL_NS__|$(MYSQL_NS)|g' \
		    -e 's|__MYSQL_RELEASE__|$(MYSQL_RELEASE)|g' \
		    -e 's|__BACKUP_PVC__|$(MYSQL_BACKUP_PVC)|g' \
		    -e 's|__BACKUP_FILE__|$(BACKUP_FILE)|g' \
		    -e "s|__JOB_NAME__|$$JOB_NAME|g" \
		    $(RESTORE_JOB_TEMPLATE) | kubectl apply -f -; \
		printf "   -> Waiting for restore job $$JOB_NAME to complete...\n"; \
		kubectl wait --for=condition=complete job/$$JOB_NAME -n $(MYSQL_NS) --timeout=300s 2>/dev/null || { \
			kubectl logs job/$$JOB_NAME -n $(MYSQL_NS) 2>/dev/null; \
			exit 1; \
		}; \
		kubectl logs job/$$JOB_NAME -n $(MYSQL_NS)
	$(call ok,Restore completed)

up:
	$(call info,Starting full environment deployment)
	@$(MAKE) --no-print-directory k8s-create
	@$(MAKE) --no-print-directory argocd-install
	@$(MAKE) --no-print-directory argocd-port-forward
	@$(MAKE) --no-print-directory kind-build-load
	@$(MAKE) --no-print-directory app-install
	@$(MAKE) --no-print-directory app-wait
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
	@$(MAKE) --no-print-directory argocd-uninstall
	@$(MAKE) --no-print-directory k8s-delete
	@printf "\n"
	$(call ok,Environment removed)
	@printf "  Logs: %s/\n" "$(LOG_DIR)"
