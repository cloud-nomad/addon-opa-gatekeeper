# Grab the cluster information
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id
}

# Grab the authentication information
data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_id
}

# Creates a kubernetes provider to connect to the cluster, so we can manipulate the authentication configmap during the cluster creation
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "1.12.0"
}

# Creates a helm provider to deploy the chart to the cluster
provider "helm" {
  version = "~> 1.2.4"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    load_config_file       = false
  }
}

# Creates a namespace for the chart, unless it is using the default kube-system
resource "kubernetes_namespace" "namespace" {
  metadata {
    labels = {
      "app"                            = "gatekeeper"
      "admission.gatekeeper.sh/ignore" = "no-self-managing"
      "control-plane"                  = "controller-manager"
      "gatekeeper.sh/system"           = "yes"
    }
    name = "gatekeeper-system"
  }
}

# Deploys the helm chart to the cluster
resource "helm_release" "helm_chart" {
  depends_on = [kubernetes_namespace.namespace]
  name       = "addon-${var.chart_name}"
  namespace  = "gatekeeper-system"
  chart      = "./chart"

  # use this to provide values from a values.yaml file, akin to -f in the cli
  # in the values file we configure settings that do not change between environments, to keep the terraform code manageable
  values = [
    file("values.yaml"),
  ]

  # Dynamically set helm properties
  dynamic "set" {
    for_each = var.helm_config
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "time_sleep" "wait_60_seconds" {
  depends_on      = [helm_release.helm_chart]
  create_duration = "60s"
}

resource "helm_release" "helm_chart_constraint_templates" {
  depends_on = [time_sleep.wait_60_seconds, helm_release.helm_chart]
  name       = "addon-${var.chart_name}-constraint-templates"
  namespace  = "gatekeeper-system"
  chart      = "./constraint-templates-chart"
}

resource "time_sleep" "wait_60_seconds_2" {
  depends_on      = [helm_release.helm_chart_constraint_templates]
  create_duration = "60s"
}

resource "helm_release" "helm_chart_rules" {
  depends_on = [time_sleep.wait_60_seconds_2, helm_release.helm_chart_constraint_templates]
  name       = "addon-${var.chart_name}-rules"
  namespace  = "gatekeeper-system"
  chart      = "./rules-chart"
}
