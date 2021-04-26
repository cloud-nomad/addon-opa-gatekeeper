output "helm_release_name" {
  value = helm_release.helm_chart.name
}

output "namespace" {
  value = helm_release.helm_chart.namespace
}

output "status" {
  value = helm_release.helm_chart.status
}

output "values" {
  value = helm_release.helm_chart.values
}
