locals {
  iam_role_arn = data.terraform_remote_state.infra_local.outputs.iam_eks_role_arn
}

data "aws_ecr_repository" "this" {
  name = var.github_repo
}

data "aws_lb_target_group" "this" {
  name = "${var.app_name}-${local.cluster_name}"
}

resource "helm_release" "app" {
  name             = trim(substr(var.app_name, 0, 53), "-")
  repository       = "https://dnd-it.github.io/helm-charts"
  chart            = "webapp"
  version          = "1.10.0"
  namespace        = coalesce(var.namespace, data.terraform_remote_state.infra_local.outputs.k8s_namespace)
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  max_history      = 3

  values = [
    <<EOF
    # https://github.com/DND-IT/helm-charts/blob/main/charts/webapp/values.yaml

    aws_iam_role_arn: ${local.iam_role_arn}
    image_repo: ${data.aws_ecr_repository.this.repository_url}
    image_tag: ${var.helm_image_tag}

    service:
      targetPort: 8080 # Port on which the application is exposed to

    scale:
      enabled: ${var.helm_enable_scaling}
      minReplicas: 3 # Minimum number of replicas, applied only if scaling is enabled
      maxReplicas: 20
      minAvailable: 60%
      cpuThresholdPercentage: 80

    metadata:
      deploymentAnnotations:
        ${yamlencode(var.helm_deployment_annotations)}

    probe:
      liveness: /api/health
      readiness: /api/health

    env:
      ${yamlencode(var.helm_env_vars)}

    externalSecrets:
      secretNames:
        %{for secret in var.helm_external_secrets~}
        - ${secret}
        %{endfor~}

    targetGroupBinding:
      enabled: ${var.helm_enable_target_group_binding}
      targetGroupARN: ${data.aws_lb_target_group.this.arn}

    ingress:
      enabled: ${var.helm_enable_ingress}
      className: alb
      annotations:
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/group.name: ${var.app_name}
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80,"HTTPS":443}]'
        alb.ingress.kubernetes.io/ssl-redirect: '443'
        alb.ingress.kubernetes.io/healthcheck-path: /api/health
        alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS13-1-2-2021-06
      hosts:
        -
      paths:
        - /

    nodeSelector:
      kubernetes.io/arch: amd64
    EOF
  ]
  dynamic "set" {
    for_each = var.helm_set
    content {
      name  = set.key
      value = set.value
      type  = optional(string)
    }
  }

}
