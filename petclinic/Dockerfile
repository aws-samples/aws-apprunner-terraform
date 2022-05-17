FROM public.ecr.aws/bitnami/java:latest
VOLUME /tmp
ADD target/spring-petclinic-2.3.0.jar app.jar
EXPOSE 80
RUN apt-get update
RUN apt-get -y install awscli
ENTRYPOINT env MYSQL_PASSWORD=$(aws ssm get-parameter --name /database/password --with-decrypt --region $AWS_REGION | grep Value | cut -d '"' -f4) java -Djava.security.egd=file:/dev/./urandom -Dspring.datasource.password=$MYSQL_PASSWORD -Dspring.datasource.username=$MYSQL_USERNAME -Dspring.datasource.initialization-mode=$DATASOURCE_INITIALIZATION_MODE -Dspring-boot.run.profiles=$ACTIVE_PROFILE -Dspring.datasource.url=$DATASOURCE_URL -jar /app.jar
