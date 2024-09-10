#!/bin/bash

writeMinioSecrets() {
  cat <<EOF > "${HELM_SECRETS[minio]}/minio-secrets.dec.yaml"
apiVersion: isindir.github.com/v1alpha3
kind: SopsSecret
metadata:
    name: minio-secrets
spec:
  secretTemplates:
      - name: minio-admin
        stringData:
          root-user: $MINIO_ROOT_USERNAME
          root-password: $MINIO_ROOT_PASSWORD
EOF
}

# Function to generate the Krakend values.yaml
writeMinioValues() {
# Create minio values.yaml
  cat <<EOF > "${HELM_CHARTS[minio]}/values.yaml"
environment: $ENVIRONMENT
minio:
  enabled: true
  global:
    compatibility:
      openshift:
        adaptSecurityContext: auto
  auth:
    existingSecret: "minio-admin"
    useSecret: false
    forceNewKeys: false
  networkPolicy:
    enabled: false
  ingress:
    enabled: true
    hostname: $ORGANIZATION_NAME-$PROJECT_NAME-minio.$CPIN_DNS
  apiIngress:
    enabled: true
    hostname: $ORGANIZATION_NAME-$PROJECT_NAME-minio-api.$CPIN_DNS
  defaultBuckets: "prototype-minio"
  resources:
    requests:
      cpu: 250m
      memory: 1Gi
    limits:
      cpu: 1
      memory: 2Gi
  provisioning:
    enabled: true
    podSecurityContext:
      enabled: false
    containerSecurityContext:
      enabled: false
    resources:
      requests:
        cpu: 250m
        memory: 100Mi
      limits:
        cpu: 500m
        memory: 500Mi
    cleanupAfterFinished:
      enabled: false
      seconds: 600
    networkPolicy:
      enabled: false
      allowExternalEgress: false
    metrics:
      serviceMonitor:
        enabled: true

EOF
}

