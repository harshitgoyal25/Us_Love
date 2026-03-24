# ── Stage 1: Build ──────────────────────────────────────────────
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app

# Copy Gradle wrapper & build files first (for layer caching)
COPY gradlew gradlew.bat settings.gradle build.gradle ./
COPY gradle/ gradle/

# Download dependencies (cached unless build files change)
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon || true

# Copy source and build the fat JAR
COPY src/ src/
RUN ./gradlew bootJar --no-daemon

# ── Stage 2: Run ────────────────────────────────────────────────
FROM eclipse-temurin:17-jre
WORKDIR /app

COPY --from=build /app/build/libs/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
