# ---------- build stage ----------
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
# cache deps
RUN mvn -B -q -e -DskipTests dependency:go-offline
# copy sources & build
COPY src ./src
RUN mvn -B -q -e package -DskipTests

# ---------- runtime stage ----------
FROM eclipse-temurin:17-jre-alpine
# non-root user
RUN addgroup -S app && adduser -S app -G app
USER app
WORKDIR /home/app
# copy fat jar from build stage
COPY --from=build /app/target/*.jar app.jar

# app port
EXPOSE 8080

# basic container health (Spring Boot actuator health)
HEALTHCHECK CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java","-jar","app.jar"]
