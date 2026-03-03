logging {
  level = "info"
}

prometheus.exporter.node "node" {}

prometheus.exporter.cadvisor "cadvisor" {
  docker_host = "unix:///var/run/docker.sock"
}

prometheus.scrape "node" {
  targets = prometheus.exporter.node.node.targets
  forward_to = [prometheus.remote_write.default.receiver]
}

prometheus.scrape "cadvisor" {
  targets = prometheus.exporter.cadvisor.cadvisor.targets
  forward_to = [prometheus.remote_write.default.receiver]
}

prometheus.remote_write "default" {
  endpoint {
    url = "http://<REPLACE_WITH_PROMETHEUS>:9090/api/v1/write"
  }
}

loki.source.file "file_logs" {
  targets = [
    { __path__ = "/var/log/*.log", job = "file", host = env("HOSTNAME") }
  ]
  forward_to = [loki.write.default.receiver]
}

loki.write "default" {
  endpoint {
    url = "http://<REPLACE_WITH_LOKI>:3100/loki/api/v1/push"
  }
}
