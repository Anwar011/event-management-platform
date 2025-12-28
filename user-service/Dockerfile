FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="EventPlatform Team"
LABEL description="User Service - Authentication & User Management"

WORKDIR /app

# Add a non-root user
RUN addgroup -S spring && adduser -S spring -G spring

# Copy the jar file
COPY target/*.jar app.jar

# Change ownership
RUN chown -R spring:spring /app

USER spring

EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD wget -q --spider http://localhost:8081/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
