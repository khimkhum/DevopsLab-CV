# Self-hosted CV · DevOps Lab

An end-to-end DevOps project delivering a personal CV website from
source code to a public Kubernetes deployment, with automated security
gates, GitOps staging delivery and controlled production releases.

**[Live website](https://khimkum.xyz)** ·
**[GitLab CI](https://gitlab.com/levankhiem0000/devopslab-cv/-/pipelines)** ·
**[GitOps repository](https://gitlab.com/levankhiem0000/devopslab-cv-gitops)**

## Architecture

```text
Delivery
GitLab CI → Build & Test → Kaniko → Harbor → Trivy Gates
  → GitOps/staging → Argo CD Auto-sync → Staging Verification
  → Production MR → GitOps/main → Argo CD Manual Sync

Public traffic
Visitor → Cloudflare HTTPS → Tunnel → Traefik → Service → CV Pods

Observability
Prometheus → Blackbox Exporter → Production Health Endpoint
Grafana → Prometheus → Alertmanager
```

## What this project demonstrates

- **Automated delivery:** an eight-job GitLab pipeline builds and tests
  the website, publishes runtime/gateway images and updates GitOps staging
  after both security gates pass.
- **Container security:** non-root Nginx, read-only filesystems, dropped
  capabilities, resource limits and Trivy gates blocking HIGH/CRITICAL
  findings. Pipelines preserve vulnerability reports and SPDX SBOMs.
- **Kubernetes operations:** probes, rolling updates, Ingress, RBAC,
  NetworkPolicy, ResourceQuota, LimitRange and storage exercises.
- **Controlled GitOps:** staging auto-sync/self-heal; production promotion
  through protected-branch MRs and manual synchronization.
- **Release recovery:** production rollback and restoration through
  Git revert MRs, verified against image digests and public version metadata.
- **Host automation:** Windows sign-in starts Docker, the WSL runtime stack
  and readiness checks; cloudflared runs as a systemd service.

## Verified release exercise

| Operation | GitOps revision | Public application commit |
|---|---|---|
| Production promotion | `8275a3b` | `73e16e7d` |
| Rollback | `d350b09` | `6e2a6d17` |
| Restoration | `d4c95615` | `73e16e7d` |

Recorded on **2026-10-28**. Each release was checked for:

- Expected Argo CD revision and Synced/Healthy status.
- Correct Deployment image digest and two available replicas.
- Matching application commit from public `/version.json`.
- Passing local/public smoke tests, including PDF download,
  security headers, route handling and HTTP method restrictions.

[View the production verification record](docs/gitops/PRODUCTION.vi.md)

## Key design decisions

| Decision | Reason |
|---|---|
| Promote the same image digest | Production receives the artifact tested on staging |
| Separate CI and runtime clusters | Separate job execution and Kubernetes API access |
| Scope credentials by job environment | Limit where registry and GitOps credentials are available |
| Restrict Argo CD with AppProjects | Constrain repositories, namespaces and resource kinds |
| Roll back through Git | Preserve deployment history and MR review records |

## Stack

**Astro · Nginx · Docker · Harbor · Kaniko · Trivy · GitLab CI ·
K3s/k3d · Kustomize · Helm · Argo CD · Cloudflare Tunnel ·
Prometheus · Grafana · Alertmanager · Bash · Python · PowerShell**

## Scope

This is a single-PC lab running on Windows and Ubuntu WSL2.
CI and runtime clusters share the Docker host; two replicas do not provide
physical-host high availability.

Management endpoints remain local. Alert delivery to Alertmanager was
verified; external notifications are not configured.

## Documentation

- [Architecture](docs/architecture/FLOW.vi.md)
- [Kubernetes exercises](docs/kubernetes/LAB.vi.md)
- [CI and image release exercises](docs/deployment/RELEASE.vi.md)
- [Staging GitOps and self-heal](docs/gitops/STAGING.vi.md)
- [Production promotion and rollback](docs/gitops/PRODUCTION.vi.md)
- [Setup and project guide](PROJECT_GUIDE.vi.md)
