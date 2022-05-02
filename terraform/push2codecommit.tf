#data "aws_caller_identity" "current" {}
resource "null_resource" "push_petcliniccode" {
  provisioner "local-exec" {
    command = <<EOT
	cd ../petclinic/
	#git config --global --unset credential.helper
	#git config --system --unset credential.helper
	#git config --global user.name ${var.codecommit_username}
	#git config --global user.email ${var.codecommit_email}
	#git init
	#git add .
	#git commit -m "Baseline commit"
	#git config --global credential.helper '!aws codecommit credential-helper $@'
	#git config --global credential.UseHttpPath true
	#git remote add origin ${aws_codecommit_repository.source_repo.clone_url_http}
	git remote -v
	git push -u origin master
      EOT
    interpreter = ["/bin/bash", "-c"]
    working_dir = path.module
  }
depends_on = [aws_codecommit_repository.source_repo]
}
