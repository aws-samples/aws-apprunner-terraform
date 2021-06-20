# ---------------------------------------------------------------------------------------------------------------------
# APPRUNNER Auto Scaling Config
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_apprunner_auto_scaling_configuration_version" "auto-scaling-config" {
  auto_scaling_configuration_name = "petclinic-config"
  max_concurrency                 = var.max_concurrency
  max_size                        = var.max_size
  min_size                        = var.min_size

  tags = {
    Name = "apprunner-auto-scaling-petclinic-config"
  }
}
