# Task 5: Istio Service Mesh — Knowledge Assessment

---

## Question 1: Role of Istio & Sidecar Proxy Model

### What is Istio?

Istio is an open-source service mesh that provides a transparent layer of
infrastructure for managing microservice communication in Kubernetes. It handles
traffic management, security, and observability without requiring changes to
application code.

### How the Sidecar Proxy Model Works

Istio injects a sidecar proxy (Envoy) into every pod automatically:

```
Without Istio:
[Service A] ──────────────► [Service B]

With Istio:
[Service A] → [Envoy Proxy] ──► [Envoy Proxy] → [Service B]
                  ↑                    ↑
             (sidecar)            (sidecar)
                  └──────────────────┘
                    Istio Control Plane
                    (Istiod manages all proxies)
```

The Envoy sidecar:
- Intercepts ALL inbound and outbound traffic
- Runs as a separate container in the same pod
- Reports metrics, logs, and traces to Istiod
- Enforces security policies (mTLS, authorization)

### Problems Istio Solves vs Application-Level Networking

| Problem | Without Istio | With Istio |
|---------|--------------|------------|
| Service-to-service encryption | Each app implements TLS | Automatic mTLS |
| Load balancing | Basic Kubernetes round-robin | Advanced (weighted, canary) |
| Circuit breaking | App must implement | Built-in via Envoy |
| Observability | Manual instrumentation | Automatic metrics/traces |
| Retries & timeouts | Hardcoded in app | Configured via YAML |
| Traffic control | Not possible | VirtualService/DestinationRule |

**Key Advantage:** Developers focus on business logic. Istio handles all
networking concerns at the infrastructure level.

---

## Question 2: PeerAuthentication vs AuthorizationPolicy

### PeerAuthentication

Controls **HOW** services communicate (transport layer security):

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: dodo-payments
spec:
  mtls:
    mode: STRICT  # Forces mTLS for all traffic
```

Modes:
- `STRICT` → Only mTLS traffic allowed
- `PERMISSIVE` → Both mTLS and plain text allowed
- `DISABLE` → mTLS disabled

### AuthorizationPolicy

Controls **WHO** can communicate with whom (application layer):

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: backend-policy
  namespace: dodo-payments
spec:
  selector:
    matchLabels:
      app: backend
  rules:
    - from:
        - source:
            principals:
              - "cluster.local/ns/dodo-payments/sa/frontend-sa"
      to:
        - operation:
            methods: ["GET", "POST"]
            paths: ["/api/*"]
```

### Enforcing Strict mTLS Across All Services

```yaml
# Step 1: Enable strict mTLS namespace-wide
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: dodo-payments
spec:
  mtls:
    mode: STRICT
---
# Step 2: Require valid certificates for all traffic
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-mtls
  namespace: dodo-payments
spec:
  rules:
    - from:
        - source:
            principals: ["*"]  # Any authenticated service
```

**Difference Summary:**
- `PeerAuthentication` = Authentication (who you ARE)
- `AuthorizationPolicy` = Authorization (what you can DO)

---

## Question 3: Traffic Management & Canary Deployment

### How Istio Traffic Management Works

Istio uses two key resources:

1. **VirtualService** → Defines routing rules (HOW traffic flows)
2. **DestinationRule** → Defines subsets/versions (WHERE traffic goes)

### Canary Deployment Example for Dodo Payments

```
Goal: Deploy backend v2 to 20% of users
      Keep backend v1 for 80% of users
```

**Step 1: Create DestinationRule (define versions)**

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: backend-destination
  namespace: dodo-payments
spec:
  host: backend-service
  subsets:
    - name: v1
      labels:
        version: v1
    - name: v2
      labels:
        version: v2
```

**Step 2: Create VirtualService (split traffic)**

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: backend-vs
  namespace: dodo-payments
spec:
  hosts:
    - backend-service
  http:
    - route:
        - destination:
            host: backend-service
            subset: v1
          weight: 80    # 80% to v1
        - destination:
            host: backend-service
            subset: v2
          weight: 20    # 20% to v2 (canary)
```

**Step 3: Gradually increase canary traffic**

```yaml
# After validation, increase to 50/50
- destination:
    subset: v1
  weight: 50
- destination:
    subset: v2
  weight: 50

# Finally 100% to v2
- destination:
    subset: v2
  weight: 100
```

**Step 4: Rollback if issues**

```bash
# Instantly route all traffic back to v1
kubectl patch virtualservice backend-vs \
  --type merge \
  -p '{"spec":{"http":[{"route":[{"destination":{"subset":"v1"},"weight":100}]}]}}'
```

---

## Question 4: Istio Ingress Gateway vs Kubernetes Ingress

### Kubernetes Ingress Controller

```
Internet → [Ingress Controller] → [Service] → [Pod]
           (nginx/traefik)
           Layer 7 HTTP only
```

**Limitations:**
- HTTP/HTTPS only
- Limited traffic control
- No mTLS support
- Basic routing only

### Istio Ingress Gateway

```
Internet → [Istio Gateway] → [VirtualService] → [Service] → [Pod+Sidecar]
           (Envoy proxy)      (routing rules)
           Layer 4-7
```

**Advantages:**

| Feature | K8s Ingress | Istio Gateway |
|---------|-------------|---------------|
| Protocols | HTTP/HTTPS | HTTP, HTTPS, TCP, gRPC, WebSocket |
| Traffic splitting | Limited | Full canary/weighted |
| mTLS | No | Yes |
| Circuit breaking | No | Yes |
| Observability | Basic | Full metrics/traces |
| Rate limiting | Plugin needed | Built-in |
| Header manipulation | Limited | Full control |

### Example Istio Gateway for Dodo Payments

```yaml
# Gateway - defines entry point
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: dodo-gateway
  namespace: dodo-payments
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 443
        name: https
        protocol: HTTPS
      tls:
        mode: SIMPLE
        credentialName: dodo-tls-secret
      hosts:
        - "dodo-payments.example.com"
---
# VirtualService - routes traffic from gateway
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: dodo-vs
  namespace: dodo-payments
spec:
  hosts:
    - "dodo-payments.example.com"
  gateways:
    - dodo-gateway
  http:
    - match:
        - uri:
            prefix: /api
      route:
        - destination:
            host: backend-service
            port:
              number: 3000
    - route:
        - destination:
            host: frontend-service
            port:
              number: 80
```

**Key Difference:**
- K8s Ingress = Simple HTTP router
- Istio Gateway = Full traffic management platform

---

## Question 5: Istio Observability

### How Istio Improves Observability

Istio provides **automatic** observability without code changes through its
sidecar proxies. Every request is tracked, measured, and logged automatically.

### Three Pillars of Observability with Istio

#### 1. Metrics → Prometheus + Grafana

Istio automatically generates metrics for every service:

```
Request rate (requests per second)
Error rate (4xx, 5xx responses)
Request duration (latency percentiles)
Request size
Response size
```

**Prometheus Integration:**

```yaml
# Istio exposes metrics on port 15090
# Prometheus scrapes automatically via ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istio-metrics
spec:
  selector:
    matchLabels:
      istio: pilot
  endpoints:
    - port: http-monitoring
      path: /metrics
```

**Grafana Dashboards:**
- Istio Service Dashboard → per-service metrics
- Istio Workload Dashboard → per-pod metrics
- Istio Control Plane Dashboard → Istiod health

#### 2. Distributed Tracing → Jaeger

Istio automatically propagates trace headers (x-b3-traceid) across services:

```
User Request
    │
    ▼
[Frontend] ──────────────────────────────────── TraceID: abc123
    │                                                │
    ▼                                                │
[Backend]  ──────────────────────────────────── SpanID: def456
    │                                                │
    ▼                                                │
[PostgreSQL] ───────────────────────────────── SpanID: ghi789
                                                     │
                                               Jaeger UI shows
                                               complete trace!
```

**Jaeger Integration:**

```yaml
# Enable tracing in Istio
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        zipkin:
          address: jaeger-collector:9411
        sampling: 100  # 100% sampling for dev
```

#### 3. Logs → Access Logs

Istio Envoy sidecars generate access logs for every request:

```
[2026-02-28T14:00:00Z] "GET /api/payments HTTP/1.1"
  200 - via_upstream - "-"
  0 145 12 11
  "-" "Mozilla/5.0"
  "x-forwarded-for: 10.0.1.1"
  outbound|3000||backend-service.dodo-payments.svc.cluster.local
```

### Integration Summary

```
Istio Sidecars
      │
      ├── Metrics ──────► Prometheus ──────► Grafana Dashboards
      │
      ├── Traces ───────► Jaeger ───────────► Distributed Trace UI
      │
      └── Logs ─────────► Loki/Fluentd ─────► Grafana Explore
```

**For Dodo Payments specifically:**

| Signal | Tool | What It Shows |
|--------|------|--------------|
| Metrics | Prometheus + Grafana | Payment API latency, error rate, throughput |
| Traces | Jaeger | Full request path from frontend to DB |
| Logs | Loki | Individual request details, errors |
| Service Map | Kiali | Visual topology of all services |

**Kiali** (Istio's dedicated UI) combines all three signals into a visual
service graph showing real-time health of the entire Dodo Payments mesh.