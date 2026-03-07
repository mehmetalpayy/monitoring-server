<h1 align="center"><strong>Monitoring Stack with Prometheus, Loki, Grafana, Alertmanager, Grafana Alloy, and Arize Phoenix</strong></h1>

## Overview

Welcome to the **monitoring-server** repository.  
This project provides a full monitoring setup for VM/container observability and agent tracing observability.

The repository is split into two main responsibilities:

- **`server/` + `alerts/`**: central monitoring stack (Prometheus, Loki, Grafana, Alertmanager, Teams proxy, Phoenix)
- **`agent/`**: Grafana Alloy configuration and installer to be deployed on monitored VMs (for example `dev` and `test`)

In short, Alloy agents collect metrics/logs on VMs and push them to this central monitoring stack.  
Additionally, **Arize Phoenix** provides LangSmith-like tracing for agent/LLM workloads, including input/output visibility, latency, and token usage.

## Task Description

The objective is to run a central monitoring server and connect remote machines (`dev`, `test`) via Grafana Alloy.

### Requirements

- Run the monitoring stack with Docker Compose.
- Load Prometheus alert rules from `alerts/`.
- Route alert notifications through Alertmanager -> Teams proxy -> Teams webhook.
- Install Grafana Alloy on each monitored VM and send:
  - metrics to Prometheus remote-write endpoint
  - logs to Loki push endpoint
- Track agent/LLM runs in Arize Phoenix (trace/span details, input/output, latency, token usage).
- Keep VM instance naming consistent (`dev`, `test`) with alert rules.

## Repository Structure

This repository contains the following key files and directories:

1. **`compose.yml`**: Main stack definition for Prometheus, Loki, Grafana, Alertmanager, Teams proxy, and Phoenix.
2. **`server/prometheus/prometheus.yml`**: Prometheus base config (rule loading + Alertmanager target).
3. **`alerts/`**: Prometheus alert rules (`node-health`, `vm-resource`, `disk`, `network`, `container`).
4. **`alerts/tests/rules.test.yml`**: Prometheus rule test scenarios.
5. **`server/alertmanager/alertmanager.yml`**: Alertmanager routing config to Teams proxy.
6. **`server/loki/loki-config.yml`**: Loki configuration.
7. **`server/grafana/provisioning/`**: Grafana datasources and dashboard provisioning.
8. **`server/teams-proxy/`**: FastAPI service that relays Alertmanager webhooks to Microsoft Teams.
9. **`server/phoenix/`**: Arize Phoenix configuration assets for agent/LLM observability.
10. **`agent/alloy-config.hcl`**: Grafana Alloy config to collect host/container metrics and file logs, then push centrally.
11. **`agent/install.sh`**: Ubuntu/Debian installer script for Grafana Alloy.

## System Flow

### 1) Metrics Flow

1. Grafana Alloy runs on each VM (`dev`, `test`).
2. Alloy collects:
   - host metrics (`prometheus.exporter.node`)
   - container metrics (`prometheus.exporter.cadvisor`)
3. Alloy pushes metrics with `prometheus.remote_write` to central Prometheus:
   - `http://<PROMETHEUS_HOST>:9090/api/v1/write`
4. Prometheus evaluates rules from `alerts/*.yml`.
5. Alertmanager receives fired alerts.
6. Alertmanager sends alerts to `teams-proxy`.
7. `teams-proxy` posts notifications to Microsoft Teams webhook.

### 2) Logs Flow

1. Grafana Alloy reads logs from `/var/log/*.log`.
2. Alloy pushes logs to central Loki:
   - `http://<LOKI_HOST>:3100/loki/api/v1/push`
3. Grafana queries Loki and Prometheus with pre-provisioned datasources.

### 3) Agent Tracing Flow (Arize Phoenix)

1. Applications/agents send traces to Phoenix (UI/API on `6006`, OTLP on `4317`).
2. Phoenix stores and visualizes end-to-end agent execution traces.
3. You can inspect:
   - input/output payloads
   - latency breakdowns
   - token usage
   - trace/span relationships

Phoenix is useful as a LangSmith-like observability layer, including non-LangChain/LangGraph agent implementations.

## Installation and Setup

### 1. Clone Repository

```bash
git clone https://github.com/mehmetalpayy/monitoring-server.git
cd monitoring-server
```

### 2. Configure Required Environment Variable

`TEAMS_WEBHOOK_URL` is mandatory in `compose.yml`.

Option A (inline):

```bash
TEAMS_WEBHOOK_URL="https://your-teams-webhook-url" docker compose up -d --build
```

Option B (`.env` file):

```env
TEAMS_WEBHOOK_URL=https://your-teams-webhook-url
```

Then:

```bash
docker compose up -d --build
```

### 3. Access Services

- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`
- Alertmanager: `http://localhost:9093`
- Loki: `http://localhost:3100`
- Phoenix: `http://localhost:6006`

## Agent Deployment (Monitored VMs)

Deploy `agent/` on each monitored VM (for example `dev` and `test`).

### 1. Install Alloy

```bash
cd agent
./install.sh
```

### 2. Update Alloy Endpoints

Edit `agent/alloy-config.hcl` and replace placeholders:

- `http://<REPLACE_WITH_PROMETHEUS>:9090/api/v1/write`
- `http://<REPLACE_WITH_LOKI>:3100/loki/api/v1/push`

Set them to your monitoring server IP or DNS.

Example:

```hcl
url = "http://10.10.10.20:9090/api/v1/write"
url = "http://10.10.10.20:3100/loki/api/v1/push"
```

### 3. VM Naming Consistency

Alert rules are designed for **`dev`** and **`test`** instances.  
Ensure incoming metric labels match these names, otherwise `ExporterDown` and related alerts may not behave as expected.

## Configuration Notes

- Prometheus is configured to accept remote-write (`--web.enable-remote-write-receiver` in Compose).
- Alert rules are mounted from `./alerts` into Prometheus.
- `TEAMS_WEBHOOK_URL` is enforced as required and non-empty.
- Phoenix is exposed on `6006` (UI/API) and `4317` (OTLP ingestion for tracing).
- `phoenix_data` uses a local Docker volume (no external volume dependency).

## Validation Checklist

Before production use, verify:

1. `docker compose config` passes with `TEAMS_WEBHOOK_URL` set.
2. Alloy endpoints in `agent/alloy-config.hcl` point to reachable central host.
3. Firewall/security groups allow:
   - VMs -> Prometheus `9090`
   - VMs -> Loki `3100`
4. Grafana datasources (Prometheus/Loki) are healthy.
5. Alerts are visible in Prometheus and routed in Alertmanager.

## Limitations and Future Work

- Alloy config is intentionally simplified; advanced parsing/enrichment stages can be reintroduced if needed.
- Current `ExporterDown` logic is static for `dev` and `test`; dynamic service discovery can improve scalability.
- Additional healthchecks in Compose could improve startup reliability.

## Contributing

If you want to contribute:

1. Create a branch.
2. Make your changes.
3. Validate with `docker compose config`.
4. Open a pull request with a clear summary.
