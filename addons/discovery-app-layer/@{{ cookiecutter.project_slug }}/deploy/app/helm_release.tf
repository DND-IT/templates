locals {
  iam_role_arn       = data.terraform_remote_state.infra_local.outputs.iam_eks_role_arn
  ecr_repository_url = data.terraform_remote_state.infra_local.outputs.ecr_repository_url
  app_name           = lower(trim(substr(join("-", [var.app_name, replace(replace(var.branch, "/", "-"), ".", "-")]), 0, 53), "-")) # Sanitized app name
  namespace          = local.app_name
  app_url            = format("https://%s", data.aws_route53_zone.zone.name)
  hostname           = var.preview_branch ? join(".", [local.app_name, trimprefix(local.app_url, "https://")]) : trimprefix(local.app_url, "https://")
}

data "aws_lb_target_group" "this" {
  count = var.preview_branch ? "0" : "1"
  name  = "${var.app_name}-${local.cluster_name}"
}

resource "helm_release" "app" {
  name             = local.app_name
  repository       = "https://dnd-it.github.io/helm-charts"
  chart            = "webapp"
  version          = "1.10.0"
  namespace        = local.app_name
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  max_history      = 3

  values = [
    <<EOF
    # https://github.com/DND-IT/helm-charts/blob/main/charts/webapp/values.yaml

    aws_iam_role_arn: ${local.iam_role_arn}
    image_repo: ${local.ecr_repository_url}
    image_tag: ${var.image_tag}

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
      enabled:  ${var.preview_branch ? "false" : "true"}
      targetGroupARN: ${var.preview_branch ? " " : data.aws_lb_target_group.this[0].arn}

    ingress:
      enabled: ${var.preview_branch ? true : false}
      className: alb
      annotations:
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/group.name: "@{{ cookiecutter.app_name }}"-preview
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80,"HTTPS":443}]'
        alb.ingress.kubernetes.io/ssl-redirect: '443'
        alb.ingress.kubernetes.io/healthcheck-path: /api/health
        alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS13-1-2-2021-06
        alb.ingress.kubernetes.io/load-balancer-attributes: deletion_protection.enabled=false
      hosts:
        - ${local.hostname}
      paths:
        - /"@{{ cookiecutter.app_name }}"

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
