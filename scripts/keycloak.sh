#!/bin/bash

writeKeycloakSecrets() {
  cat <<EOF > "${HELM_SECRETS[keycloak]}/keycloak-secrets.dec.yaml"
apiVersion: isindir.github.com/v1alpha3
kind: SopsSecret
metadata:
    name: kc-secrets
spec:
    secretTemplates:
        - name: keycloak-api-client
          stringData:
            clientId: $KEYCLOAK_CLIEND_ID
            clientSecret: $KEYCLOAK_CLIEND_SECRET
        - name: keycloak-admin
          stringData:
            username: $KEYCLOAK_ADMIN_USER
            password: $KEYCLOAK_ADMIN_PASSWORD               
EOF
}

# Function to generate the Krakend values.yaml
writeKeycloakValues() {
  cat <<EOF > "${HELM_CHARTS[keycloak]}/values.yaml"
environment: $ENVIRONMENT
keycloak:
  enabled: true
  global:
    compatibility:
      openshift:
        adaptSecurityContext: auto
  auth:
    adminUser: admin
    existingSecret: "keycloak-admin"
    passwordSecretKey: "password"
    adminUser: $KEYCLOAK_ADMIN_USER
  cache:
    enabled: false
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1024Mi
  ingress:
    enabled: true
    hostname:  $ORGANIZATION_NAME-$PROJECT_NAME-keycloak.$CPIN_DNS
  livenessProbe:
    enabled: true
    failureThreshold: 3
    initialDelaySeconds: 900
    periodSeconds: 90
    successThreshold: 1
    timeoutSeconds: 90
  logging:
    level: INFO
  podSecurityContext:
    enabled: false
    fsGroup: null
  externalDatabase:
    existingSecret: "$ORGANIZATION_NAME-$PROJECT_NAME-$ENVIRONMENT-postgres-$namespace_hash-cluster-app"
    existingSecretHostKey: "host"
    existingSecretPortKey: "port"
    existingSecretUserKey: "username"
    existingSecretDatabaseKey: "dbname"
    existingSecretPasswordKey: "password"
  postgresql:
    enabled: false  
  production: false
  proxy: edge
  replicaCount: 1
  keycloakConfigCli:
    enabled: true
    command:
      - java
      - -jar
      - /opt/bitnami/keycloak-config-cli/keycloak-config-cli-23.0.7.jar
    image:
      registry: docker.io
      repository: bitnami/keycloak-config-cli
      tag: 5.11.1-debian-12-r0
      pullPolicy: IfNotPresent
    resources:
      requests:
        cpu: 250m
        memory: 206Mi
      limits:
        cpu: 1000m
        memory: 512Mi    
    extraEnvVars:
      - name: IMPORT_VARSUBSTITUTION_ENABLED
        value: "true"
      - name: CLIENTSECRET
        valueFrom:
          secretKeyRef:
            name: keycloak-api-client
            key: clientSecret
      - name: CLIENTID
        valueFrom:
          secretKeyRef:
            name: keycloak-api-client
            key: clientId
      - name: REALM
        value: "$REALM"
    existingConfigmap: "keycloak-realm-config"
    cleanupAfterFinished:
      enabled: false
      seconds: 600
  networkPolicy:
    enabled: false
EOF
}

