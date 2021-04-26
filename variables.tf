variable "iam_idp_provider_arn" {
  description = "the iam idp provider arn - created with the eks cluster"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "the cluster oidc issuer url - created with the eks cluster"
  type        = string
}

variable "environment" {
  description = "the environment name"
  type        = string
}

variable "eks_cluster_id" {
  description = "name of the eks cluster"
  type        = string
}

variable "chart_name" {
  description = "name of the helm chart"
  type        = string
}

variable "helm_config" {
  type        = map(string)
  description = "extra helm config values"
  default     = {}
}
