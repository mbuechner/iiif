FROM maven:3-openjdk-17-slim AS MAVEN_CHAIN
COPY pom.xml /tmp/
COPY src /tmp/src/
WORKDIR /tmp/
RUN mvn package

FROM openjdk:17-alpine
ENV TZ=Europe/Berlin
ENV IIIF.PORT=8080
ENV XDG_CONFIG_HOME=/tmp
RUN mkdir /home/zdbdump && apk add curl
COPY --from=MAVEN_CHAIN /tmp/target/iiif.jar /home/iiif/iiif.jar
WORKDIR /home/iiif/
CMD ["java", "-Xms256M", "-Xmx512G", "-jar", "iiif.jar"]
EXPOSE 8080
