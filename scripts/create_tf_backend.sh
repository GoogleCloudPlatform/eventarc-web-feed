#!/usr/bin/env bash

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

ROOT_DIR="$( cd -- "$(dirname "$(dirname -- "${BASH_SOURCE[0]}" )")" &> /dev/null && pwd )"
CONFIG_DIR="${ROOT_DIR}/.config"
BACKEND_CONFIG_FILE="${CONFIG_DIR}/.backend.lock.yml"
PROJECT_ID=$(gcloud config get-value project)
CURRENT_USER=$(gcloud config get-value account)
CWD=$(pwd)
BILLING_ACCOUNT_ID=$(gcloud alpha billing accounts list --format="value(ACCOUNT_ID)")
ORGANIZATION_ID=$(gcloud organizations list --format="value(ID)")

RANDOM_INT=$((1000 + $RANDOM % 100000))
BUCKET_NAME="${PROJECT_ID}-tf-backend-${RANDOM_INT}"
BUCKET_NAME_WITH_PROTO="gs://${BUCKET_NAME}"

function validate_backend_exists() {
    if [[ -f ${BACKEND_CONFIG_FILE} ]]
    then
        echo "The backend has already been configured.."
        echo ""
        echo "$(cat $BACKEND_CONFIG_FILE)"
        echo ""
        echo "Exiting..."
        exit 0
    fi
}

function enable_apis() {
    while IFS= read -r API; do
        echo "Enabling $API..."
        gcloud services enable $API
    done <"${CONFIG_DIR}/apis.txt"

    echo "Allowing time to propagate..."
    sleep 30
}

function disable_policies() {
    while IFS= read -r POLICY; do
        echo "Disabling $POLICY in ${PROJECT_ID}..."
        gcloud alpha --quiet resource-manager org-policies disable-enforce ${POLICY} --project=${PROJECT_ID} > /dev/null 2>&1
    done <"${CONFIG_DIR}/disable_boolean_constraint_policies.txt"

    while IFS= read -r POLICY; do
        echo "Disabling $POLICY in ${PROJECT_ID}..."
        gcloud --quiet org-policies reset ${POLICY} --project=${PROJECT_ID} > /dev/null 2>&1
    done <"${CONFIG_DIR}/disable_list_constraint_policies.txt"

    echo "Allowing time to propagate..."
    sleep 180
}

function create_bucket() {
    echo "Creating bucket ${BUCKET_NAME_WITH_PROTO} in ${PROJECT_ID} within us-central1 ..."
    gsutil mb -c standard -b on -l us-central1 $BUCKET_NAME_WITH_PROTO  > /dev/null 2>&1 && \
        gsutil versioning set on $BUCKET_NAME_WITH_PROTO
}

function create_service_account() {
    echo "Creating Terraform service account in ${PROJECT_ID} ..."
    SERVICE_ACCOUNT="terraform@${PROJECT_ID}.iam.gserviceaccount.com"

    gcloud iam service-accounts create terraform --display-name="Terraform Service Account" || echo "${SERVICE_ACCOUNT} SA already exists!!"

    gcloud iam service-accounts add-iam-policy-binding ${SERVICE_ACCOUNT} \
        --member="user:${CURRENT_USER}" \
        --role='roles/iam.serviceAccountTokenCreator'

    while IFS= read -r ROLE; do
        echo "Assigning ${ROLE} to ${SERVICE_ACCOUNT}..."
        gcloud projects add-iam-policy-binding ${PROJECT_ID} \
            --member="serviceAccount:${SERVICE_ACCOUNT}" \
            --role=${ROLE}
    done <"${CONFIG_DIR}/roles.txt"

    echo "Allowing time to propagate..."
    sleep 30
}

function generate_config_file() {
    echo "Generating backend config file ..."
    touch "${BACKEND_CONFIG_FILE}"
    echo "project: \"${PROJECT_ID}\"" >> "${BACKEND_CONFIG_FILE}"
    echo "bucket: \"${BUCKET_NAME}\"" >> "${BACKEND_CONFIG_FILE}"
    echo "serviceAccount: \"${SERVICE_ACCOUNT}\"" >> "${BACKEND_CONFIG_FILE}"
    echo "billingAccount: \"${BILLING_ACCOUNT_ID}\"" >> "${BACKEND_CONFIG_FILE}"
}

function end() {
    echo "Done!"
}

set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command exited with exit code $?."' EXIT

enable_apis
# disable_policies
create_service_account
validate_backend_exists
create_bucket
generate_config_file
end