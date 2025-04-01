FROM maven:3-eclipse-temurin-21-alpine AS mchain
WORKDIR /tmp/
COPY pom.xml .
COPY src/ src/
RUN mvn clean package

FROM eclipse-temurin:21-alpine
LABEL org.opencontainers.image.authors="m.buechner@dnb.de"
ENV TZ=Europe/Berlin
ENV IIIF.PORT=8080
RUN mkdir /opt/iiif
WORKDIR /opt/iiif
COPY --from=mchain /tmp/target/iiif.jar iiif.jar
CMD ["java", "-Xms256M", "-Xmx512G", "-jar", "iiif.jar"]
EXPOSE 8080
