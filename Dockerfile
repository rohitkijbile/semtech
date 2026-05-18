# Use an official and secure JRE runtime layer
FROM eclipse-temurin:17-jre-jammy

# Set the working directory inside the container
WORKDIR /app

# Copy the compiled jar file from the target directory to the container
COPY target/*.jar app.jar

# Expose the standard Spring Boot port
EXPOSE 8080

# Command to execute the application
ENTRYPOINT ["java", "-jar", "app.jar"]