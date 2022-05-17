FROM public.ecr.aws/bitnami/java:latest
VOLUME /tmp
ADD target/spring-petclinic-2.3.0.jar app.jar
EXPOSE 80
RUN apt-get update
RUN apt-get -y install awscli
ENTRYPOINT java -Djava.security.egd=file:/dev/./urandom -Dspring.datasource.password=$(aws ssm get-parameter --name /database/password --with-decrypt --region $AWS_REGION | grep Value | cut -d '"' -f4) -Dspring.datasource.username=$MYSQL_USERNAME -Dspring.datasource.initialization-mode=$DATASOURCE_INITIALIZATION_MODE -Dspring.profiles.active=$ACTIVE_PROFILE -Dspring-boot.run.profiles=$ACTIVE_PROFILE -Dspring.datasource.url=$DATASOURCE_URL -jar /app.jar
