# ---------------------------------------------------------------------------------------------------------------------
# Code Build
# ---------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# Codebuild role

resource "aws_iam_role" "codebuild_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  path = "/"
}

resource "aws_iam_policy" "codebuild_policy" {
  description = "Policy to allow codebuild to execute build spec"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents",
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.artifact_bucket.arn}/*",
        "${aws_s3_bucket.cache.arn}/*"
      ]
    },
    {
      "Action": [
        "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability", "ecr:PutImage",
        "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Effect": "Allow",
      "Resource": "${data.aws_ecr_repository.image_repo.arn}"
    },
    {
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Effect": "Allow",
      "Resource": "${data.aws_ecr_repository.image_repo.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codebuild-attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}


# Codebuild project

resource "aws_s3_bucket" "cache" {
  bucket = var.codebuild_cache_bucket_name # workaround from https://github.com/hashicorp/terraform-provider-aws/issues/10195
  acl    = "private"
  force_destroy = true
}

resource "aws_codebuild_project" "codebuild" {
  depends_on = [
    aws_codecommit_repository.source_repo,
    aws_ecr_repository.petclinic,
    aws_iam_policy.codebuild_policy
  ]
  name         = "codebuild-${var.source_repo_name}-${var.source_repo_branch}"
  service_role = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  cache {
    type     = "S3"
    location = var.codebuild_cache_bucket_name
  }
  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "REPOSITORY_URI"
      value = data.aws_ecr_repository.image_repo.repository_url
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.family
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = <<BUILDSPEC
version: 0.2
runtime-versions:
  java: openjdk8
phases:
  install:
    runtime-versions:
      docker: 18
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - $(aws ecr get-login --region $AWS_DEFAULT_REGION --no-include-email)
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=$${COMMIT_HASH:=latest}         
  build:
    commands:
      - echo Build started on `date`
      - echo Building the jar
      - mvn clean package -Dmaven.test.skip=true
      - echo Building the Docker image...
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - printf '[{"name":"%s","imageUri":"%s"}]' $CONTAINER_NAME $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json
cache:
  paths:
    - '/root/.m2/**/*'
artifacts:
    files: imagedefinitions.json
BUILDSPEC
  }
}
