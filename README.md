# Build and Deploy Spring Petclinic Application to AWS App Runner using AWS CodePipeline, Amazon RDS and Terraform

![Build Status](https://codebuild.us-east-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiSy9rWmVENzRDbXBoVlhYaHBsNks4OGJDRXFtV1IySmhCVjJoaytDU2dtVWhhVys3NS9Odk5DbC9lR2JUTkRvSWlHSXZrNVhYQ3ZsaUJFY3o4OERQY1pnPSIsIml2UGFyYW1ldGVyU3BlYyI6IlB3ODEyRW9KdU0yaEp6NDkiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)
[![Gitpod Ready-to-Code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/aws/aws-cdk)
[![NPM version](https://badge.fury.io/js/aws-cdk.svg)](https://badge.fury.io/js/aws-cdk)
[![PyPI version](https://badge.fury.io/py/aws-cdk.core.svg)](https://badge.fury.io/py/aws-cdk.core)
[![NuGet version](https://badge.fury.io/nu/Amazon.CDK.svg)](https://badge.fury.io/nu/Amazon.CDK)

## Introduction

This workshop is designed to enable engineers to get some hands-on experience using AWS CI/CD tools to build pipelines for Serverless Container workloads. The workshop consists of a number of lab modules, each designed to demonstrate a CI/CD pattern. You will be using AWS services like AWS App Runner, Amazon RDS, AWS CodePipeline, AWS CodeCommit and AWS CodeBuild.

[AWS App Runner](https://aws.amazon.com/apprunner/) leverages AWS best practices and technologies for deploying and running containerized web applications at scale. This leads to a drastic reduction in your time to market for new applications and features. App Runner runs on top of AWS ECS and Fargate. App Runner is a lot easier to get into, cost estimation for App Runner is far simpler — AWS charges a fixed CPU and Memory fee per second.

## Background

The Spring PetClinic sample application is designed to show how the Spring application framework can be used to build simple, but powerful database-oriented applications. It uses AWS RDS (MySQL) at the backend and it will demonstrate the use of Spring's core functionality. The Spring Framework is a collection of small, well-focused, loosely coupled Java frameworks that can be used independently or collectively to build industrial strength applications of many different types.

## Contributor

1. Irshad A Buchh, Amazon Web Services
1. Rylie Knox, Amazon Web Services

## Architecture
![Architecture](images/Architecture.png)

## Prerequisites

Before you build the whole infrastructure, including your CI/CD pipeline, you will need to meet the following pre-requisites.

<details>
  <summary>Self-paced in your own AWS account</summary>

### AWS account

Ensure you have access to an AWS account, and a set of credentials with *Administrator* permissions. **Note:** In a production environment we would recommend locking permissions down to the bare minimum needed to operate the pipeline.

### Create an AWS Cloud9 environment

Log into the AWS Management Console and search for Cloud9 services in the search bar. Click Cloud9 and create an AWS Cloud9 environment in the `us-east-1` region based on Amazon Linux 2. You can select the instance type as t2.micro.

### Configure the AWS Cloud9 environment

Launch the AWS Cloud9 IDE. Close the `Welcome` tab and open a new `Terminal` tab.

![Cloud9](images/Cloud9.png)

#### Create and attach an IAM role for your Cloud9 instance

By default, Cloud9 manages temporary IAM credentials for you.  Unfortunately these are incomaptible with Terraform. To get around this you need to disable Cloud9 temporary credentials, and create and attach an IAM role for your Cloud9 instance.

1. Follow [this deep link to create an IAM role with Administrator access.](https://console.aws.amazon.com/iam/home#/roles$new?step=review&commonUseCase=EC2%2BEC2&selectedUseCase=EC2&policies=arn:aws:iam::aws:policy%2FAdministratorAccess)
1. Confirm that **AWS service** and **EC2** are selected, then click **Next** to view permissions.
1. Confirm that **AdministratorAccess** is checked, then click **Next: Tags** to assign tags.
1. Take the defaults, and click **Next: Review** to review.
1. Enter **workshop-admin** for the Name, and click **Create role**.
![createrole](images/createrole.png)
1. Follow [this deep link to find your Cloud9 EC2 instance](https://console.aws.amazon.com/ec2/v2/home?#Instances:tag:Name=aws-cloud9-;sort=desc:launchTime)
1. Select the instance, then choose **Actions / Security / Modify IAM Role**. Note: If you cannot find this menu option, then look under **Actions / Instance Settings / Modify IAM Role** instead.
![c9instancerole](images/c9instancerole.png)
1. Choose **workshop-admin** from the **IAM Role** drop down, and select **Save**
![c9attachrole](images/c9attachrole.png)
1. Return to your Cloud9 workspace and click the gear icon (in top right corner), or click to open a new tab and choose "Open Preferences"
1. Select **AWS SETTINGS**
1. Turn off **AWS managed temporary credentials**
1. Close the Preferences tab
![c9disableiam](images/c9disableiam.png)
1. In the Cloud9 terminal pane, execute the command:
    ```bash
    rm -vf ${HOME}/.aws/credentials
    ```
1. As a final check, use the [GetCallerIdentity](https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html) CLI command to validate that the Cloud9 IDE is using the correct IAM role.
    ```bash
    aws sts get-caller-identity --query Arn | grep workshop-admin -q && echo "IAM role valid" || echo "IAM role NOT valid"
    ```

#### Upgrade awscli
To ensure you are running the latest version of AWS CLI, run the following command:

```bash
aws --version
pip install awscli --upgrade --user
```

Run `aws configure` to configure your region. Leave all the other fields blank. You should have something like:

```
admin:~/environment $ aws configure
AWS Access Key ID [None]:
AWS Secret Access Key [None]:
Default region name [None]: us-east-1
Default output format [None]:
```
</details>

<details>
  <summary>Participating at an AWS event using a provided AWS account</summary>

  You will be provided a URL and a code to provide you access to an AWS account that is already provisioned with resources that have been configured. This allows you to skip the manual steps to get right to exploring App Runner.

  Once you are logged into the console, in the [Cloud9 Console](https://console.aws.amazon.com/cloud) you should see a pre-provisioned environment. Click the "Open IDE" button and within a couple minutes. Close the `Welcome` tab and open a new `Terminal` tab.

  ![Cloud9](images/Cloud9.png)
</details>

#### Install Apache Maven

First, we need to install Apache Maven. Run the following commands in the terminal window to fetch and install Maven.

```bash
cd /tmp
sudo wget https://www-eu.apache.org/dist/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz
sudo tar xf /tmp/apache-maven-*.tar.gz -C /opt
sudo ln -s /opt/apache-maven-3.8.1 /opt/maven
```

#### Setup Apache Maven

Now that Maven is installed, we need to set some environment variables. The following commands will add a few lines to our .bashrc and source it to bring the changes into our current shell.

```bash
cat << 'EOF' >> ~/.bashrc
export M2_HOME=/opt/maven
export MAVEN_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}
EOF
source ~/.bashrc
```

Verify the Apache Maven installation:

```bash
mvn --version
```

#### Clone workshop repository

Clone the source code repository:

```bash
cd ~/environment
git clone https://github.com/aws-samples/aws-apprunner-terraform.git
```


## Build the infrastructure and pipeline

We shall use Terraform to build the above architecture including the AWS CodePipeline.

**Note:** This workshop will create chargeable resources in your account. When finished, please make sure you clean up resources as instructed at the end.

### Edit terraform variables

```bash
cd ~/environment/aws-apprunner-terraform/terraform
```

Edit `terraform.tfvars` to make these changes:
* leave the `aws_profile` as `"default"`
* ensure `aws_region` matches your environment
* update `codebuild_cache_bucket_name` to replace the placeholder `yyyymmdd` with today's date, and the identifier `identifier` with something unique to you to create globally unique S3 bucket name. S3 bucket names can include numbers, lowercase letters and hyphens.
* update `codecommit_username` and `codecommit_email` with your own name and email address so that your commits are attributed to you.

### Set up SSM parameter for DB password

```bash
aws ssm put-parameter --name /database/password  --value mysqlpassword --type SecureString
```

This will use AWS Systems Manager Parameter Store to create a parameter for securely handling sensitive values like passwords. The name value `/database/password` is passed into our application via an environment variable and that name needs to match the `ssm_parameter_store_name` in terraform.tfvars. When our application starts, it will retrieve the password from Parameter Store and pass it along to our application via an environment variable. The environment variables we configure for App Runner is easily accessible so care should be taken with sensitive information.


### Build

Initialise Terraform:

```bash
terraform init
```

Build the infrastructure and pipeline using terraform:

```bash
terraform apply
```

Terraform will display an action plan. When asked whether you want to proceed with the actions, enter `yes`.

Wait for Terraform to complete the build before proceeding. It will take few minutes to complete “terraform apply”. If an operation times out, simply rerun `terraform apply`.

### What's Terraform doing?

This step typically takes about 10-15 minutes to complete as Terraform does a lot of heavy lifting for us! While terraform is setting up the infrastructure, in parallel it is also running a script in `appbuild.tf` to use Maven to build our application, fetching all of the dependencies, and then creating a docker image, tagging it and pushing it to our newly created ECR repository.

## Run Petclinic application locally

Once the local build process has completed and the docker image has been created, we can run the container to test it locally from our Cloud9 environment.

While terraform is still running, we can open a new terminal by clicking on the green plus sign at the end of the list of tabs on the lower half of the wind and select "New Terminal". Run the following inside the Cloud9 terminal:

```bash
docker run -it --rm -p 8080:80  --name petclinic petclinic
```
![ApplicationLocal](images/docker-local-run.png)

This will run the application using container port of 80 and will expose the application to host port of 8080. Click Preview from the top menu and then click “Preview Running Application.” It will open a browser displaying the Spring Petclinic application.

When finished exploring the application, you can close the Preview tab, and with the terminal window running our Docker Container focused, press Control-C to stop the container to release resources.

### Explore the stack you have built

Once the build is complete, you can explore your environment using the AWS console:
- View the App Runner service using the [AWS App Runner console](https://console.aws.amazon.com/apprunner/)
- View the RDS database using the [Amazon RDS console](https://console.aws.amazon.com/rds).
- View the ECR repo using the [Amazon ECR console](https://console.aws.amazon.com/ecr).
- View the CodeCommit repo using the [AWS CodeCommit console](https://console.aws.amazon.com/codecommit).
- View the CodeBuild project using the [AWS CodeBuild console](https://console.aws.amazon.com/codebuild).
- View the pipeline using the [AWS CodePipeline console](https://console.aws.amazon.com/codepipeline).



### Explore the App Runner service
Open the App Runner service configuration file [terraform/services.tf](terraform/services.tf) file and explore the options specified in the file.

```typescript
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
  depends_on = [aws_iam_role.apprunner-service-role, aws_db_instance.db, aws_route_table.private-route-table, null_resource.petclinic_springboot]
}
```

The `source_configuration` section is the most interesting segment of this template. The `image_configuration` section defines the port that our container is listening on, as well as sets various environment variables to be passed to it. While the `image_identifier` and `image_repository_type` values specify which container this application should use. This section also references other resources like IAM policies to be used for pulling the image (`authentication_configuration`) and for the container to run under (`instance_configuration`) as well as defining the autoscaling configuration.

**Note:** In a production environment it is a best practice to use a meaningful tag instead of using the `:latest` tag.

## Deploy petclinic application using the pipeline

You will now use git to push the petclinic application through the pipeline.

Terraform has already created a local repo for the petclinic application, configured our username and email, and added our new CodeCommit repo as a remote tracking branch, so we are all ready to push changes. The template for this is in `push2codecommit.tf`.


We can verify that our remote is configured correctly by running the following commands:

```bash
cd ~/environment/aws-apprunner-terraform/petclinic
git remote -v
```

You should see something like:

```bash
origin  https://git-codecommit.eu-west-2.amazonaws.com/v1/repos/petclinic (fetch)
origin  https://git-codecommit.eu-west-2.amazonaws.com/v1/repos/petclinic (push)
```


### Trigger the pipeline

To trigger the pipeline, push the master branch to the remote as follows:

```bash
git push -u origin master
```




### Test the application

From the output of the Terraform build, note the Terraform output `apprunner_service_url`.

```bash
cd ~/environment/aws-apprunner-terraform/terraform
export tf_apprunner_service_url=$(terraform output --raw apprunner_service_url)
echo $tf_apprunner_service_url
```

Use this in your browser to access the application.

![Petclinic](images/petclinic.png)
## Push a change through the pipeline and re-test

The pipeline can now be used to deploy any changes to the application.

You can try this out by changing the welcome message as follows:

```
cd ~/environment/aws-apprunner-terraform/petclinic
vi src/main/resources/messages/messages.properties
```
Change the value for the welcome string, for example, to "Hello".

Commit the change:

```
git add .
git commit -m "Changed welcome string"
```

Push the change to trigger pipeline:

```bash
git push origin master
```

The pipeline will pull the code, build the docker image, push it to ECR, and deploy it to your ECS cluster. This will take a few minutes for CodePipeline to build our new Container Image and push it to ECR, and then a few mintues for App Runner to bring up the new container and then cut traffic over to the new version.
You can monitor the pipeline in the [AWS CodePipeline console](https://console.aws.amazon.com/codepipeline), and then you can monitor App Runner deploy progress in the [AWS App Runner Console](https://console.aws.amazon.com/apprunner).

## Demonstrate Auto Scaling

Next, we will generate some load against our application so we can see how it behaves under load and to trigger autoscaling. We will need to install [Locust](https://locust.io), a simple Python load testing tool. This is as simple as a single command:

```bash
pip install locust
```

Locust uses python code to specify how it behaves. There's a locustfile.py in the root of the repo and inspecting it reveals how simple it is to generate requests against the home page of the application.

```
from locust import HttpUser, task

class WebUser(HttpUser):
  @task
  def index(self):
    self.client.get("/")
```

We can start generating load by running this command:

```bash
cd ~/environment/aws-apprunner-terraform/
locust --headless -u 1000 -r 5 -f locustfile.py -H $tf_apprunner_service_url
```

This will generate a maximum of 1000 users, adding 5 new user per second and it will run continually until we stop it by pressing Control-C.

That command uses an environment variable which was set earlier in this workshop. In case you don't have that set in this terminal window, this is the command you'll need:

```bash
cd ~/environment/aws-apprunner-terraform/terraform
export tf_apprunner_service_url=$(terraform output --raw apprunner_service_url)
echo $tf_apprunner_service_url
```

Now that we are generating load, we can view how the application is responding by heading to the [AWS App Runner Console](https://console.aws.amazon.com/apprunner), selecting our application and then clicking into the Metrics tab. This page shows some of the CloudWatch metrics that are automatically collected. Data is collected at one minute intervals and by default the last 3 hours of data is displayed. We can focus on more recent data by clicking `1h` and we can get updated data by clicking on the reload button adjacent to the time selectors.

As more users are being added to our load test, we will see the number of requests ramping up, and watch the number of active instances respond to the increase in load, and the effect it has on the latency of the requests. Ideally, all of the requests will be successfully served as 200 responses, but there may be some transient 400 or 500 errors if load is ramping up faster than we can initialize new application instances.


## Tearing down the stack

**Note:** If you are participating in this workshop at an AWS-hosted event using Event Engine and a provided AWS account, you do not need to complete this step. We will cleanup all managed accounts afterwards on your behalf.

Make sure that you remember to tear down the stack when finished to avoid unnecessary charges. You can free up resources as follows:

```
cd ~/environment/aws-apprunner-terraform/terraform
terraform destroy
```

When prompted enter `yes` to allow the stack termination to proceed.

Once complete, note that you will have to manually empty and delete the S3 bucket used by the pipeline.

## Remove the Parameter Store database password

```bash
aws ssm delete-parameter --name /database/password
```
