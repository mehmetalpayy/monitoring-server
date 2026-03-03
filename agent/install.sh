#!/usr/bin/env bash
set -euo pipefail

# Install Grafana Alloy on Ubuntu using the official Grafana APT repository.

export DEBIAN_FRONTEND=noninteractive

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer supports Debian/Ubuntu systems with apt-get."
  exit 1
fi

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

$SUDO apt-get update
$SUDO apt-get install -y ca-certificates curl gnupg

$SUDO mkdir -p /etc/apt/keyrings

if [[ ! -f /etc/apt/keyrings/grafana.gpg ]]; then
  curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor | $SUDO tee /etc/apt/keyrings/grafana.gpg >/dev/null
  $SUDO chmod 0644 /etc/apt/keyrings/grafana.gpg
fi

GRAFANA_REPO_LINE="deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main"
if [[ ! -f /etc/apt/sources.list.d/grafana.list ]] || ! grep -qxF "$GRAFANA_REPO_LINE" /etc/apt/sources.list.d/grafana.list; then
  echo "$GRAFANA_REPO_LINE" | $SUDO tee /etc/apt/sources.list.d/grafana.list >/dev/null
  $SUDO apt-get update
fi

if dpkg -s alloy >/dev/null 2>&1; then
  echo "Alloy already installed; skipping package install."
else
  $SUDO apt-get install -y alloy
fi

$SUDO systemctl enable --now alloy
