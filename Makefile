# Copyright 2022 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

BACKEND_BUCKET:=$$(grep 'bucket:' ./.config/.backend.lock.yml | cut -d ':' -f 2 | tr -d '"' | tr -d '[:space:]')
SERVICE_ACCOUNT:=$$(grep 'serviceAccount:' ./.config/.backend.lock.yml | cut -d ':' -f 2 | tr -d '"' | tr -d '[:space:]')
GOOGLE_ACCESS_TOKEN:=$$(gcloud auth application-default print-access-token)

all: tf-backend app
app: check-install init validate plan apply
update: check-install validate plan apply
update-dev: check-install validate plan-dev apply

# .EXPORT_ALL_VARIABLES:
# GOOGLE_OAUTH_ACCESS_TOKEN = "${GOOGLE_ACCESS_TOKEN}"
# TF_LOG=DEBUG

.PHONY: check-install
check-install:
	@command -v terraform >/dev/null || ( echo "Terraform is not installed!"; exit 1)
	@command -v gcloud >/dev/null || ( echo "gcloud CLI is not installed!"; exit 1)

.PHONY: check-local-dev
check-local-dev:
	@command -v terraform-docs >/dev/null || ( echo "terraform-docs is not installed!"; exit 1)
	@command -v python3 >/dev/null || ( echo "python 3.10 is not installed!"; exit 1)
	@command -v go >/dev/null || ( echo "go 1.16 is not installed!"; exit 1)

.PHONY: check-container-dev
check-container-dev:
	@command -v devcontainer >/dev/null || ( echo "devcontainer is not installed!"; exit 1)

.PHONY: dev
dev: check-container-dev
	devcontainer open

.PHONY: tf-backend
tf-backend: check-install
	@./scripts/create_tf_backend.sh

.PHONY: fmt
fmt:
	terraform fmt -recursive

.PHONY: init
init:
	terraform -chdir=terraform init \
		-backend-config="bucket=${BACKEND_BUCKET}" \
		-backend-config="impersonate_service_account=${SERVICE_ACCOUNT}"

.PHONY: validate
validate:
	terraform -chdir=terraform validate

.PHONY: console
console:
	terraform -chdir=terraform console -var-file=../config.tfvars

.PHONY: plan-dev
plan-dev:
	terraform -chdir=terraform plan -var-file=../.gcp-service-health.config.tfvars -out=tfplan

.PHONY: plan
plan:
	terraform -chdir=terraform plan -var-file=../config.tfvars -out=tfplan

.PHONY: apply
apply:
	terraform -chdir=terraform apply -auto-approve tfplan
	make clean

.PHONY: clean
clean:
	@rm *.zip terraform/tfplan || exit 0

.PHONY: new.subscriber
new.subscriber:
	@if [ "$(name)" == "" ]; then\
		echo "new.subscriber requires the 'name' arg to be set!";\
		exit 1;\
	fi
	@if [ -d "./src/subscribers/$(name)" ]; then\
		echo "$(name) is already an existing subscriber in ./src/subscribers/ ! ";\
		exit 1;\
	fi
	@cp -r ./src/subscribers/_example_subscriber ./src/subscribers/$(name)
	@echo "Created new subscriber scaffolding in ./src/subscribers/$(name)!"

.PHONY: docs
docs:
	@echo 'Generating documentation for the Terraform module...'
	@cd terraform; terraform-docs markdown --output-file README.md --output-mode inject .
