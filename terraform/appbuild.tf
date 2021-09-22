#data "aws_caller_identity" "current" {}
resource "null_resource" "petclinic_springboot" {
  provisioner "local-exec" {
    command = <<EOT

	cd ../petclinic/ && mvn clean package -Dmaven.test.skip=true
    	docker build -t petclinic . 
    	docker tag petclinic ${data.aws_ecr_repository.image_repo.repository_url}
#    	aws ecr get-login-password --region var.region | docker login --username AWS --password-stdin ${data.aws_ecr_repository.image_repo.repository_url}
    	aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
    	docker push ${data.aws_ecr_repository.image_repo.repository_url}
      EOT
    interpreter = ["/bin/bash", "-c"]
    working_dir = path.module
  }
depends_on = [aws_ecr_repository.petclinic]
}
