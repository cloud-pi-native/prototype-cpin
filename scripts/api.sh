#!/bin/bash

# Function to generate the Krakend values.yaml
writeApiValues() {
  # Create api values.yaml
  cat <<EOF > "${HELM_CHARTS[api]}/values.yaml"
replicaCount: 1
image:
  repository: $REGISTRY_URI/$ORGANIZATION_NAME-$PROJECT_NAME/api-node
  tag: latest
  imagePullSecrets: registry-pull-secret
nodeEnv: production
service:
  type: ClusterIP
  port: 80
resources:
  limits:
    memory: "256Mi"
    cpu: "250m"
  requests:
    memory: "128Mi"
    cpu: "125m"

EOF
}

