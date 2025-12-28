FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="EventPlatform Team"
LABEL description="Config Server - Centralized Configuration"

WORKDIR /app

# Add a non-root user
RUN addgroup -S spring && adduser -S spring -G spring

# Copy the jar file
COPY target/*.jar app.jar

# Change ownership
RUN chown -R spring:spring /app

USER spring

EXPOSE 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -q --spider http://localhost:8888/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
