# Runbook: Dodo Payments Alert Response

## Alert: PodCrashLooping

**Severity:** Critical
**Condition:** Pod restarting more than once in 5 minutes

**Steps:**
```bash
kubectl get pods -n dodo-payments

kubectl logs -l app=backend -n dodo-payments --previous

kubectl describe pod -l app=backend -n dodo-payments

kubectl rollout restart deployment/backend -n dodo-payments

kubectl rollout undo deployment/backend -n dodo-payments
```

---

## Alert: HighCPUUsage

**Severity:** Warning
**Condition:** CPU usage > 80% for 5 minutes

**Steps:**
```bash
kubectl top pods -n dodo-payments

kubectl get hpa -n dodo-payments

kubectl scale deployment/backend --replicas=5 -n dodo-payments

kubectl logs -l app=backend -n dodo-payments | grep -i "slow"
```

---

## Alert: HighMemoryUsage

**Severity:** Warning
**Condition:** Memory usage > 85% for 5 minutes

**Steps:**
```bash
kubectl top pods -n dodo-payments

kubectl logs -l app=backend -n dodo-payments | grep -i "memory\|heap"

kubectl rollout restart deployment/backend -n dodo-payments
```

---

## Alert: HighErrorRate

**Severity:** Critical
**Condition:** 5xx error rate > 5% - SLO breach!

**Steps:**
```bash
kubectl logs -l app=backend -n dodo-payments | grep -i "error\|500"

kubectl logs -l app=postgres -n dodo-payments | tail -20

kubectl exec -it deploy/backend -n dodo-payments -- \
  wget -qO- localhost:3000/health

kubectl exec -it deploy/backend -n dodo-payments -- \
  wget -qO- localhost:3000/ready

kubectl rollout undo deployment/backend -n dodo-payments
```

---

## Alert: DeploymentReplicasMismatch

**Severity:** Critical
**Condition:** Available replicas != Desired replicas for 5 minutes

**Steps:**
```bash
kubectl get deployments -n dodo-payments

kubectl get events -n dodo-payments --sort-by=.lastTimestamp

kubectl describe nodes | grep -A5 "Allocated resources"

kubectl get nodes

aws eks update-nodegroup-config \
  --cluster-name infra-eks \
  --nodegroup-name infra-eks-node-group \
  --scaling-config desiredSize=4 \
  --region us-east-1
```

---

## Alert: HighLatency

**Severity:** Warning
**Condition:** P99 latency > 1 second


```bash
kubectl logs -l app=backend -n dodo-payments | grep -i "slow\|timeout"

kubectl exec -it deploy/postgres -n dodo-payments -- \
  psql -U dodoadmin -d dododb -c \
  "SELECT query, mean_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 5"

kubectl scale deployment/backend --replicas=5 -n dodo-payments
```