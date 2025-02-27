#!/bin/bash

export STORAGE_PASSWORD=""
export STORAGE_USER=""
export GITHUB_TOKEN=""
export JIRA_TOKEN=""
export WORKSPACE=$(dirname $(dirname $(readlink -f "$0")))
export SECRET_DASHBOARD_TMP=${WORKSPACE}/backend/deploy/overlays/local/secrets.txt
export FRONTEND_DEPLOYMENT_TMP=$(mktemp)

while [[ $# -gt 0 ]]
do
    case "$1" in
        -p|--storage-password)
            STORAGE_PASSWORD=$2
            ;;
        -u|--storage-user)
            STORAGE_USER=$2
            ;;
        -g|--github-token)
            GITHUB_TOKEN=$2
            ;;
        -jt|--jira-token)
            JIRA_TOKEN=$2
            ;;
        *)
            ;;
    esac
    shift  # Shift each argument out after processing them
done

if [[ "${STORAGE_PASSWORD}" == "" ]]; then
  echo "[ERROR] Storage password flag is missing. Use '--storage-password <value>' or '-p <value>' to create a storage password for the quality dashboard"
  exit 1
fi

if [[ "${STORAGE_USER}" == "" ]]; then
  echo "[ERROR] Storage database flag is missing. Use '--storage-user <value>' or '-u <value>' to create a storage database for the quality dashboard"
  exit 1
fi

if [[ "${GITHUB_TOKEN}" == "" ]]; then
  echo "[ERROR] Github Token flag is missing. Use '--github-token <value>' or '-g <value>' to allow quality dashboard to make request to github"
  exit 1
fi

echo "[INFO] Starting Quality dashboard..."
echo "   Storage Password   : "${STORAGE_PASSWORD}""
echo "   Storage Database   : "${STORAGE_USER}""
echo "   Github Token       : "${GITHUB_TOKEN}""
echo ""

cat << EOF > ${SECRET_DASHBOARD_TMP}
storage-database=quality
storage-user=${STORAGE_USER}
storage-password=${STORAGE_PASSWORD}
github-token=${GITHUB_TOKEN}
rds-endpoint=postgres-service
jira-token=${JIRA_TOKEN}
EOF

# Namespace
oc create namespace appstudio-qe || true

# BACKEND
echo -e "[INFO] Deploying Quality dashboard backend"

oc apply -k ${WORKSPACE}/backend/deploy/overlays/local

# oc apply -k ${WORKSPACE}/frontend/deploy/openshift

# export BACKEND_ROUTE=$(oc get route quality-backend-route -n appstudio-qe -o json | jq -r '.spec.host')
echo "BACKEND_ROUTE=$(oc get route quality-backend-route -n appstudio-qe -o json | jq -r '.spec.host')" > ${WORKSPACE}/frontend/deploy/overlays/local/configmap.txt

# FRONTEND
echo -e "[INFO] Deploying Quality dashboard frontend"

oc apply -k ${WORKSPACE}/frontend/deploy/overlays/local

echo ""
echo "Frontend is accessible from: http://"$(oc get route/quality-frontend-route -n appstudio-qe -o go-template='{{.spec.host}}{{"\n"}}')""
