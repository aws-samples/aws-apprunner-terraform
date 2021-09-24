FROM public.ecr.aws/bitnami/java:latest
VOLUME /tmp
ADD target/spring-petclinic-2.3.0.jar app.jar
EXPOSE 80
RUN apt-get update
RUN apt-get -y install awscli
ENTRYPOINT env spring.datasource.password=$(aws ssm get-parameter --name /database/password --with-decrypt --region $AWS_REGION | grep Value | cut -d '"' -f4) java -Djava.security.egd=file:/dev/./urandom -jar /app.jar
