# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /app

# Copy project file
COPY src/VersionApp.csproj ./src/
RUN dotnet restore ./src/VersionApp.csproj

# Copy source code
COPY src/ ./src/
WORKDIR /app/src

# Build with version from build arg
ARG VERSION=1.0.0
RUN dotnet publish -c Release -o /app/publish \
    /p:AssemblyVersion=$VERSION \
    /p:FileVersion=$VERSION \
    /p:InformationalVersion=$VERSION

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app

# Copy published app
COPY --from=build /app/publish .

# Expose port
EXPOSE 5000

# Set environment variables
ENV ASPNETCORE_URLS=http://+:5000
ENV ASPNETCORE_ENVIRONMENT=Production

# Run the application
ENTRYPOINT ["dotnet", "VersionApp.dll"]