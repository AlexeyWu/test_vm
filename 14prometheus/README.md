# Docker

- _Vagranfile_ - файл конфигурации для создания VM для тестов с Prometheus+Grafana+AlertManager
- - _DashboardGrafanaScreenshot from 2023-05-22 23-00-54.png_ - файл со скриншетом Dashboard Grafana


_CONFIGURATION PROMETHEUS_
```
global:
  scrape_interval: 10s
  scrape_timeout: 10s
  evaluation_interval: 1m
alerting:
  alertmanagers:
  - follow_redirects: true
    enable_http2: true
    scheme: http
    timeout: 10s
    api_version: v2
    static_configs:
    - targets:
      - localhost:9093
rule_files:
- /etc/prometheus/rules.yml
scrape_configs:
- job_name: prometheus_master
  honor_timestamps: true
  scrape_interval: 5s
  scrape_timeout: 5s
  metrics_path: /metrics
  scheme: http
  follow_redirects: true
  enable_http2: true
  static_configs:
  - targets:
    - localhost:9090
- job_name: node_exporter_centos
  honor_timestamps: true
  scrape_interval: 5s
  scrape_timeout: 5s
  metrics_path: /metrics
  scheme: http
  follow_redirects: true
  enable_http2: true
  static_configs:
  - targets:
    - localhost:9100
 ```
