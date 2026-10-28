# Self-hosted CV DevOps Lab

A personal CV hosted on a Windows PC using Ubuntu WSL2,
Kubernetes, Cloudflare Tunnel and a private Harbor registry.

Live website: [khimkum.xyz](https://khimkum.xyz)

## Architecture

```text
Visitor
  -> Cloudflare HTTPS
  -> Cloudflare Tunnel / cloudflared in WSL
  -> localhost:18082
  -> Traefik
  -> cv-production Service
  -> CV Pods

GitLab application repository
  -> Build and test
  -> Isolated Kubernetes runner checks
  -> Kaniko build and push to Harbor
  -> Trivy security gate by digest
  -> Vulnerability report, SPDX SBOM and approved image

GitOps repository
  -> Argo CD
  -> cv-staging
  -> Auto-sync and self-heal

Prometheus -> Blackbox Exporter -> CV health endpoint
Grafana -> Prometheus
Prometheus alerts -> Alertmanager
```

The public origin currently uses Kubernetes. Docker Compose is retained
for local services and the fallback deployment path.

## Implemented

- Static CV website and downloadable PDF.
- Non-root Nginx runtime, read-only root filesystem and resource limits.
- Cloudflare Tunnel with loopback-only origin access.
- Windows sign-in startup automation.
- Harbor TLS, separate push/pull robots and digest-based deployment.
- Kubernetes probes, Ingress, ConfigMap, RBAC and NetworkPolicy.
- ResourceQuota, LimitRange and PVC/PV practice.
- Failed-rollout recovery exercises.
- Seven-job GitLab pipeline with runtime/gateway image builds.
- Trivy gates blocking HIGH/CRITICAL findings.
- Vulnerability reports, SPDX SBOMs and approved digest artifacts.
- Argo CD AppProject restricting the Git source and staging destination.
- Staging manual sync, auto-sync, Git revert and self-heal verified.
- Prometheus, Grafana, Blackbox Exporter and Alertmanager.

## Verification

Smoke tests check page content, PDF download, health, release metadata,
security headers, missing routes and HTTP method restrictions.

The staging GitOps exercise verified:
- Git changes automatically update the Deployment.
- Git revert restores replica configuration.
- Live replica drift is corrected without changing Git.
- The approved image digest and application version remain consistent.

See [staging evidence](docs/gitops/STAGING.vi.md).

## Operational scope

- The PC must remain awake and connected to the Internet.
- Automatic startup begins after Windows sign-in.
- Runtime and CI use separate k3d clusters sharing one Docker host.
- This is a single-host, single-node lab.
- Monitoring and Argo CD management access remain local.
- Staging uses auto-sync/self-heal; prune remains disabled.
- Production GitOps promotion is the next implementation stage.
- Intermittent public TLS timeouts are recorded; smoke-test retries
  are bounded and do not bypass HTTP/content/security assertions.
- Secrets, kubeconfigs and local artifacts are excluded from Git.

## Roadmap

- Phase 1: Linux/WSL foundations — applied throughout the project.
- Phase 2: Containers, Harbor and monitoring — core work implemented.
- Phase 3: Kubernetes — core exercises verified.
- Phase 4: CI build/test/push/security gate — verified.
- Phase 5: Staging GitOps and self-heal — verified.
- Phase 6: Controlled staging updates, production promotion and
  release rollback — next.

## Documentation

- [Project guide](PROJECT_GUIDE.vi.md)
- [Kubernetes journal](docs/kubernetes/LAB.vi.md)
- [Staging GitOps evidence](docs/gitops/STAGING.vi.md)
- [Release exercises](docs/deployment/RELEASE.vi.md)

Some earlier journals describe previous deployment stages.
The architecture above represents the current public request path.
