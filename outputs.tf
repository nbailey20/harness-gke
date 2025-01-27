output "harness_endpoint" {
  value = var.sleep_mode ? "No endpoint, sleep_mode enabled" : "${kubernetes_service_v1.default[0].status.0.load_balancer.0.ingress.0.ip}:3000"
}
