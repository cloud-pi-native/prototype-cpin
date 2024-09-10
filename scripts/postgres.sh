#!/bin/bash

# Function to generate the Krakend values.yaml
writePostgresValues() {
  local tool="$1"
  cat <<EOF > "${HELM_CHARTS[postgres]}/values.yaml"
cluster:
  enabled: true
  type: postgresql
  mode: standalone
  cluster:
    instances: 1
    storage:
      size: 2Gi
    walStorage:
      size: 1Gi
    resources: 
      limits:
        cpu: 500m
        memory: 1Gi
      requests:
        cpu: 250m
        memory: 512Mi
    monitoring:
      enabled: true
      podMonitor:
        enabled: true
      prometheusRule:
        enabled: true
        excludeRules: []
    initdb: 
      database: $tool
      owner: $tool
      options: []
      encoding: UTF8
  backups:
    enabled: false
  pooler:
    enabled: false
EOF
}

