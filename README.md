# Self-hosted CV DevOps Lab

Personal CV hosted on a Windows PC using Ubuntu WSL2, Docker Compose
and Cloudflare Tunnel.

Live website: https://khimkum.xyz

## Architecture

Visitor --HTTPS--> Cloudflare --Tunnel--> cloudflared in WSL
    --> loopback gateway :8080 --> Nginx CV container

Prometheus --> Blackbox Exporter --> CV health endpoint
Grafana --> Prometheus
Prometheus alerts --> Alertmanager

Windows sign-in --> Scheduled Task --> start Docker Desktop
    --> start Ubuntu WSL --> wait for Docker Engine --> Compose

The tunnel runs as a systemd service under a dedicated Linux account.

## Implemented

- Static CV website with a downloadable PDF.
- Multi-stage image build and unprivileged Nginx runtime.
- Read-only container root filesystems and temporary writable storage.
- Loopback-only published ports for local access.
- Public HTTPS through Cloudflare Tunnel.
- Prometheus, Blackbox Exporter, Grafana and Alertmanager.
- Origin outage alert tested by stopping and recovering the CV service.
- Local and public HTTP smoke tests.
- Startup automation after Windows sign-in.
- Reboot and external mobile-network checks completed.
- Private Harbor registry with TLS and separate push/pull robot accounts.
- Trivy scanning and runtime package remediation.
- CV and gateway deployment by immutable artifact digest.

## Verification

- Smoke tests check page content, PDF download, health, release metadata,
  security headers, missing routes and HTTP method restrictions.
- The outage exercise verified Pending/Firing, Alertmanager delivery
  and recovery to probe_success = 1.
- Public access was checked over a mobile network.
- Startup logs are stored locally under .artifacts/ and excluded from Git.

## Operational scope

- The PC must remain awake and connected to the Internet.
- Automatic startup begins after Windows sign-in.
- Grafana, Prometheus and Alertmanager remain accessible locally.
- Blackbox currently probes the internal CV origin.
- Alertmanager notification channels are not configured yet.
- The startup script recreates this Compose stack to refresh Docker
  Desktop WSL bind mounts. Named volumes retain monitoring data.
- Credentials and local secrets are excluded from the repository.

## Roadmap status

- Phase 1: Linux and WSL foundations used throughout the lab.
- Phase 2: CV, Compose, monitoring, Harbor and digest-based deployment
  implemented; rollback rehearsal and Kaniko exercise remain.

- Phase 3: In progress — Kubernetes deployment, Ingress, ConfigMap,
  RBAC, NetworkPolicy and failed-rollout recovery verified.
- Phase 4: GitLab CI and runner — planned.
- Phase 5: Argo CD GitOps — planned.
- Phase 6: staging/production delivery and rollback — planned.

GitHub hosts this portfolio repository. GitLab CI remains part of the
original learning roadmap.

## Documentation

- [Project guide](PROJECT_GUIDE.vi.md)
- [Architecture](docs/architecture/FLOW.vi.md)
- [Local deployment](docs/deployment/LOCAL.vi.md)
- [Learning journal](notes/learning-log.md)
- [Release evidence and recovery](docs/deployment/RELEASE.vi.md)
