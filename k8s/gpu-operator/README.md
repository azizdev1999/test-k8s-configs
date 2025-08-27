# GPU Operator Test Configuration

This directory contains test Kubernetes configurations for the NVIDIA GPU Operator and related components.

## Components

### 1. GPU Operator Deployment (`deployment.yaml`)
- Main GPU operator controller deployment
- Manages GPU resources in the cluster
- Runs in `gpu-operator-system` namespace
- Includes RBAC configurations (ServiceAccount, ClusterRole, ClusterRoleBinding)

### 2. Device Plugin & Monitoring DaemonSets (`daemonset.yaml`)
- **nvidia-device-plugin-daemonset**: Manages GPU device allocation
- **nvidia-dcgm-exporter**: Exports GPU metrics for monitoring
- Both run on nodes with GPUs (`nvidia.com/gpu.present: "true"`)

### 3. Test Workloads (`test-gpu-workload.yaml`)
- **gpu-test-pod**: Simple test pod to verify GPU access (runs nvidia-smi)
- **gpu-stress-test**: Job that runs GPU burn test for 60 seconds
- **gpu-workload-sample**: Sample TensorFlow deployment with GPU

## Deployment Instructions

1. **Deploy the GPU Operator:**
```bash
kubectl apply -f deployment.yaml
```

2. **Deploy DaemonSets for GPU management:**
```bash
kubectl apply -f daemonset.yaml
```

3. **Verify GPU nodes are detected:**
```bash
kubectl get nodes -L nvidia.com/gpu.present
```

4. **Test GPU functionality:**
```bash
# Simple test
kubectl apply -f test-gpu-workload.yaml
kubectl logs gpu-test-pod -n gpu-operator-system

# Check GPU allocation
kubectl describe node | grep -A5 "nvidia.com/gpu"
```

## Resource Configurations

### GPU Operator Controller
- Requests: 100m CPU, 256Mi Memory
- Limits: 500m CPU, 512Mi Memory

### Device Plugin
- Requests: 50m CPU, 50Mi Memory  
- Limits: 100m CPU, 128Mi Memory

### DCGM Exporter
- Requests: 100m CPU, 128Mi Memory
- Limits: 200m CPU, 256Mi Memory

### Test Workloads
- GPU Test Pod: 1 GPU
- GPU Stress Test: 1 GPU, 1 CPU, 2Gi Memory
- GPU Workload Sample: 1 GPU, 2-4 CPU, 4-8Gi Memory

## Monitoring

Access GPU metrics via the DCGM exporter:
```bash
kubectl port-forward -n gpu-operator-system svc/nvidia-dcgm-exporter 9400:9400
curl http://localhost:9400/metrics
```

## Cleanup

Remove all GPU operator components:
```bash
kubectl delete -f test-gpu-workload.yaml
kubectl delete -f daemonset.yaml
kubectl delete -f deployment.yaml
```

## Notes

- Ensure your cluster has GPU nodes before deploying
- The operator requires privileged access for GPU management
- Metrics are exposed on port 9400 for Prometheus scraping
- All components use the `gpu-operator-system` namespace