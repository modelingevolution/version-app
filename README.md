# VersionApp - AutoUpdater Test Application

This is a minimal .NET 9 API project used for integration testing the ModelingEvolution.AutoUpdater.

## Features

- **GET /version** - Returns the current version of the application
- **GET /health** - Health check endpoint  
- **GET /** - Application info and available endpoints

## Building

### Local Build
```bash
dotnet build src/VersionApp.csproj
dotnet run --project src/VersionApp.csproj
```

### Docker Build
```bash
# Build version 1.0.0
docker build -t versionapp:1.0.0 --build-arg VERSION=1.0.0 .

# Build version 1.1.0  
docker build -t versionapp:1.1.0 --build-arg VERSION=1.1.0 .
```

## Testing Version Updates

1. Build and tag initial version:
   ```bash
   docker build -t versionapp:1.0.0 --build-arg VERSION=1.0.0 .
   ```

2. Run the container:
   ```bash
   docker run -d -p 5000:5000 versionapp:1.0.0
   ```

3. Check version:
   ```bash
   curl http://localhost:5000/version
   # Output: {"version":"1.0.0"}
   ```

4. Build new version:
   ```bash
   docker build -t versionapp:1.1.0 --build-arg VERSION=1.1.0 .
   ```

5. Update via AutoUpdater (when configured)

## Integration with AutoUpdater

This project is used as a test application for the ModelingEvolution.AutoUpdater. The docker-compose configuration for deployment is maintained in a separate repository: https://github.com/modelingevolution/version-app-compose.git

### Version Tagging

The project uses Git tags for version management:
```bash
git tag v1.0.0
git push origin v1.0.0
```

When AutoUpdater detects a new tag in the compose repository, it will:
1. Pull the latest compose configuration
2. Check out the tagged version  
3. Run `docker-compose up -d` to update the container