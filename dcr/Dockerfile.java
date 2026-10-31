# syntax=docker/dockerfile:1
# Spring Boot 3.3+ / 4.x layered image. Build: docker build -f Dockerfile.java -t app .
# Java 25 = current LTS (needs Spring Boot 3.5+); use 21 for older Spring Boot
ARG JAVA_VERSION=25

FROM eclipse-temurin:${JAVA_VERSION}-jdk-alpine AS builder

WORKDIR /app

# ---- Maven ----
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN --mount=type=cache,target=/root/.m2 ./mvnw dependency:go-offline -B

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw clean package -DskipTests -B \
    && cp target/*.jar app.jar

# ---- Gradle (replace Maven block above) ----
# COPY gradlew build.gradle.kts settings.gradle.kts ./
# COPY gradle/ gradle/
# RUN chmod +x gradlew
# RUN --mount=type=cache,target=/root/.gradle ./gradlew dependencies --no-daemon
# COPY src ./src
# RUN --mount=type=cache,target=/root/.gradle ./gradlew bootJar --no-daemon -x test \
#     && find build/libs -name '*.jar' ! -name '*-plain.jar' -exec cp {} app.jar \;

# Spring Boot 3.3+ (older versions: java -Djarmode=layertools -jar app.jar extract --destination extracted)
RUN java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted

FROM eclipse-temurin:${JAVA_VERSION}-jre-alpine AS runtime

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Least-changing layers first -> better cache reuse
COPY --from=builder /app/extracted/dependencies/ ./
COPY --from=builder /app/extracted/spring-boot-loader/ ./
COPY --from=builder /app/extracted/snapshot-dependencies/ ./
COPY --from=builder /app/extracted/application/ ./
# Fat-jar alternative (use with the second ENTRYPOINT below, remove the 4 COPY lines above):
# COPY --from=builder /app/app.jar app.jar

USER appuser

# Container support is on by default since JDK 10
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError"
# ENV SPRING_PROFILES_ACTIVE=prod
# Remote debug (dev only, also publish 5005):
# ENV JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"

EXPOSE 8080

# Requires spring-boot-starter-actuator; alpine has busybox wget
# HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
#   CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
# ENTRYPOINT ["java", "-jar", "app.jar"]
