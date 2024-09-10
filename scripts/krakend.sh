#!/bin/bash

# Load environment variables from .env file
source ./.env



# Function to generate the Krakend values.yaml
writeKrakendValues() {
# Create krakend values.yaml
  cat <<EOF > "${HELM_CHARTS[krakend]}/values.yaml"
environnement: $ENVIRONMENT
replicaCount: 1

image:
  registry: docker.io
  repository: devopsfaith/krakend
  tag: "2.7.0"
  pullPolicy: IfNotPresent
deploymentType: deployment

krakend:
  allInOneImage: false
  config: |-
    {
      "version": 3,
      {{ template "telemetry.tmpl" . }},
      "endpoints": [
        {{ template "endpoints.tmpl" .urls }}
      ]
    }
  configFileSource: ""
  partialsDirSource: ""
  settingsDirSource: ""
  templatesDirSource: ""
  partials:
    input_header.txt: |-
      [
        "X-User",
        "Authorization"
      ]
  settings:
    urls.json: |-
      {
          "APIHost": "http://$ORGANIZATION_NAME-$PROJECT_NAME-$ENVIRONMENT-api-$namespace_hash-api",
          "JWKUrl": "http://$ORGANIZATION_NAME-$PROJECT_NAME-$ENVIRONMENT-keycloak-$namespace_hash/realms/$REALM/protocol/openid-connect/certs"
      }
  templates:
    telemetry.tmpl: |-
      "extra_config": {
        "telemetry/opentelemetry": {
          "service_name": "krakend_prometheus_service",
          "metric_reporting_period": 1,
          "exporters": {
            "prometheus": [
              {
                "name": "local_prometheus",
                "port": 9090,
                "process_metrics": true,
                "go_metrics": true
              }
            ]
          }
        }
      }
    endpoints.tmpl: |-
      {{ define "auth_validator" }}
      {
        "alg": "RS256",
        "jwk_url": "{{ .JWKUrl }}",
        "disable_jwk_security": true,
        "roles": {{ .Roles }},
        "roles_key": "realm_access.roles",
        "roles_key_is_nested": true,
          "propagate_claims": [
          ["preferred_username", "x-user"],
          ["realm_access.role", "x-role"]
        ]
      }
      {{ end }}
      {{ define "lua_prescript" }}
      {
        "pre": "local r = request.load();print('[GATEWAY] Request from username: ' .. r:headers('X-User') .. ' with path: ' .. r:path() .. ' and method: ' .. r:method())",
        "live": false,
        "allow_open_libs": true,
        "skip_next": false
      }
      {{ end }}
      {{$host := .APIHost}}
      {{$JWKUrl := .JWKUrl}}
        {
          "endpoint": "/api/user/{id}",
          "method": "GET",
          "backend": [
            {
              "host": ["{{ \$host }}"],,
              "url_pattern": "/user/{id}"
            }
          ],
          "input_headers": {{ include "input_header.txt"}},
          "extra_config": {
            "auth/validator": {{ template "auth_validator" (dict "JWKUrl" $JWKUrl "Roles" "[\"admin\", \"moderator\", \"user\"]") }},
            "modifier/lua-proxy": {{ template "lua_prescript" . }}
          }
        },
        {
          "endpoint": "/api/public",
          "method": "GET",
          "backend": [
            {
              "host": ["{{ \$host }}"],,
              "url_pattern": "/public"
            }
          ]
        },
        {
            "endpoint": "/api/modo/{id}",
            "method": "PUT",
            "backend": [
              {
                "host": ["{{ \$host }}"],,
                "url_pattern": "/modo/{id}"
              }
            ],
            "input_headers": {{ include "input_header.txt"}},
            "extra_config": {
              "auth/validator": {{ template "auth_validator" (dict "JWKUrl" $JWKUrl "Roles" "[\"admin\", \"moderator\"]") }},
              "modifier/lua-proxy": {{ template "lua_prescript" . }}
            }
          },
          {
            "endpoint": "/api/admin/{id}",
            "method": "POST",
            "backend": [
              {
                "host": ["{{ \$host }}"],,
                "url_pattern": "/admin/{id}"
              }
            ],
            "input_headers": {{ include "input_header.txt"}},
            "extra_config": {
              "auth/validator": {{ template "auth_validator" (dict "JWKUrl" $JWKUrl "Roles" "[\"admin\"]") }},
              "modifier/lua-proxy": {{ template "lua_prescript" . }}
            }
          }
serviceAccount:
  create: true
securityContext:
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  runAsUser: null
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
    add:
      - NET_BIND_SERVICE
service:
  type: ClusterIP
  port: 80
  targetPort: 8080
ingress:
  enabled: true
  hosts:
    - host: $ORGANIZATION_NAME-$PROJECT_NAME-krakend.$CPIN_DNS
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1024Mi
podDisruptionBudget:
  enabled: false
serviceMonitor:
  enabled: true
  annotations: {}
  interval: 10s
  scrapeTimeout: 10s
  targetPort: 9091
networkPolicies:
  enabled: false
autoscaling:
  enabled: false
keda:
  enabled: false
EOF
}