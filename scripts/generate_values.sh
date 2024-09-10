#!/bin/bash

# Set the environment variables
# ENVIRONMENT="ovh-test"
# PROJECT_NAME=${PROJECT_NAME:-"apimcanel"}
# ORGANIZATION_NAME=${ORGANIZATION_NAME:-"mi"}
# KEYCLOAK_ADMIN_USER=${KEYCLOAK_ADMIN_USER:-"admin"}
# KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD:-"admin"}
# CLIENTSECRET=${CLIENTSECRET:-"PouetPouet1!"}
# CLIENTID=${CLIENTID:-"krakend-client"}
# REALM=${REALM:-"krakend-realm"}
# CPIN_DNS=${CPIN_DNS:-"apps.app1.numerique-interieur.com"}
# REGISTRY_URI=${HARBOR_URL:-"harbor.apps.dso.numerique-interieur.com"}
# MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD:-"PouetPouet1!"}
# MINIO_ROOT_USERNAME=${MINIO_ROOT_USERNAME:-"admin"}

generateNamespaceHash() {
  local env="$1"
  local envHash=$(echo -n "$env" | openssl dgst -sha256 -hmac "" | sed 's/^.* //g' | cut -c1-4)
  echo "${envHash}"
}

# Call the function and print the namespace
namespace_hash=$(generateNamespaceHash "$ENVIRONMENT")

# Define the Helm charts and their directories
declare -A HELM_CHARTS
HELM_CHARTS["minio"]="..minio/values/$ENVIRONMENT"
HELM_CHARTS["postgres"]="..postgres/values/$ENVIRONMENT"
HELM_CHARTS["api"]="..api/values/$ENVIRONMENT"
HELM_CHARTS["keycloak"]="..keycloak/values/$ENVIRONMENT"
HELM_CHARTS["krakend"]="..krakend/values/$ENVIRONMENT"

# Define the Helm charts and their directories
declare -A HELM_SECRETS
HELM_SECRETS["minio"]="minio/environments/$ENVIRONMENT"
HELM_SECRETS["keycloak"]="keycloak/environments/$ENVIRONMENT"


# Create the directories if they don't exist
for CHART in "${!HELM_CHARTS[@]}"; do
  mkdir -p "${HELM_CHARTS[$CHART]}"
done

for SECRET in "${!HELM_SECRETS[@]}"; do
  mkdir -p "${HELM_SECRETS[$SECRET]}"
done

# Load the namespace generation script
source ./minio.sh
writeMinioSecrets
writeMinioValues
source ./postgres.sh
writePostgresValues keycloak
source ./api.sh
writeApiValues
source ./keycloak.sh
writeKeycloakSecrets
writeKeycloakValues
source ./krakend.sh
writeKrakendValues


