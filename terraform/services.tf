# ---------------------------------------------------------------------------------------------------------------------
# APPRUNNER Service
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_apprunner_service" "service" {
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.auto-scaling-config.arn
  service_name                   = "apprunner-petclinic"
  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner-service-role.arn
    }
    image_repository {
      image_configuration {
        port = var.container_port
        runtime_environment_variables = {
          "spring.datasource.username" : "${var.db_user}",
          "spring.datasource.password" : "${data.aws_ssm_parameter.dbpassword.value}",
          "spring.datasource.initialization-mode" : var.db_initialize_mode,
          "spring.profiles.active" : var.db_profile,
          "spring.datasource.url" : "jdbc:mysql://${aws_db_instance.db.address}/${var.db_name}"
        }
      }
      image_identifier      = "${data.aws_ecr_repository.image_repo.repository_url}:latest"
      image_repository_type = "ECR"
    }
  }
  depends_on = [aws_iam_role.apprunner-service-role, aws_db_instance.db, aws_route_table.private-route-table]
}

output "apprunner_service_url" {
  value = aws_apprunner_service.service.service_url
}
