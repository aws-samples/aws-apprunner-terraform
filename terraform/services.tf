# ---------------------------------------------------------------------------------------------------------------------
# APPRUNNER VPC CONNECTOR
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_apprunner_vpc_connector" "connector" {
  vpc_connector_name = "apprunner-petclinic-connector"
  subnets            = aws_subnet.private.*.id
  security_groups    = ["${aws_security_group.service-sg.id}"]
  depends_on = [aws_security_group.service-sg]

}


# ---------------------------------------------------------------------------------------------------------------------
# APPRUNNER SERVICE
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
          "AWS_REGION" : "${var.aws_region}",
          "spring.datasource.username" : "${var.db_user}",
          "spring.datasource.initialization-mode" : var.db_initialize_mode,
          "spring.profiles.active" : var.db_profile,
          "spring.datasource.url" : "jdbc:mysql://${aws_db_instance.db.address}/${var.db_name}"
        }
      }
      image_identifier      = "${data.aws_ecr_repository.image_repo.repository_url}:latest"
      image_repository_type = "ECR"
    }
  }

  instance_configuration {
    instance_role_arn = aws_iam_role.apprunner-instance-role.arn
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.connector.arn
    }
  }

  depends_on = [aws_iam_role.apprunner-service-role, aws_db_instance.db, aws_route_table.private-route-table, aws_apprunner_vpc_connector.connector, null_resource.petclinic_springboot]
}

output "apprunner_service_url" {
  value = "https://${aws_apprunner_service.service.service_url}"
}
