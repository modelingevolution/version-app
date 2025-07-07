#!/bin/bash

# VersionApp Build Script
# Builds Docker images for the VersionApp with specified versions

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
VERSION="1.0.0"
PUSH=false
REGISTRY="ghcr.io/modelingevolution"
IMAGE_NAME="version-app"

# Help function
show_help() {
    cat << EOF
VersionApp Build Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -v, --version VERSION    Version to build (default: 1.0.0)
    -p, --push              Push image to registry after build
    -r, --registry REGISTRY Registry URL (default: ghcr.io/modelingevolution)
    -n, --name NAME         Image name (default: version-app)
    --help                  Show this help message

EXAMPLES:
    # Build version 1.0.0 locally
    $0 -v 1.0.0
    
    # Build version 1.1.0 and push to registry
    $0 -v 1.1.0 --push
    
    # Build with custom registry
    $0 -v 1.0.0 --registry myregistry.com/myorg --push

PREREQUISITES:
    - Docker installed and running
    - If pushing: authenticated with registry (docker login)

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate version format
if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Version must be in format X.Y.Z (e.g., 1.0.0)${NC}"
    exit 1
fi

# Build configuration
LOCAL_TAG="versionapp:$VERSION"
REGISTRY_TAG="$REGISTRY/$IMAGE_NAME:$VERSION"

echo -e "${GREEN}VersionApp Build Script${NC}"
echo "========================"
echo "Version: $VERSION"
echo "Local tag: $LOCAL_TAG"
if [ "$PUSH" = true ]; then
    echo "Registry tag: $REGISTRY_TAG"
fi
echo ""

# Build the image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build \
    -t "$LOCAL_TAG" \
    --build-arg VERSION="$VERSION" \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful: $LOCAL_TAG${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Tag for registry if pushing
if [ "$PUSH" = true ]; then
    echo -e "${YELLOW}Tagging image for registry...${NC}"
    docker tag "$LOCAL_TAG" "$REGISTRY_TAG"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Tagged: $REGISTRY_TAG${NC}"
    else
        echo -e "${RED}❌ Tagging failed${NC}"
        exit 1
    fi
    
    # Push to registry
    echo -e "${YELLOW}Pushing to registry...${NC}"
    docker push "$REGISTRY_TAG"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Pushed: $REGISTRY_TAG${NC}"
    else
        echo -e "${RED}❌ Push failed${NC}"
        exit 1
    fi
fi

# Test the image locally
echo -e "${YELLOW}Testing image locally...${NC}"

# Stop any existing test container
docker stop versionapp-test 2>/dev/null || true
docker rm versionapp-test 2>/dev/null || true

# Run test container
CONTAINER_ID=$(docker run -d -p 5001:5000 --name versionapp-test "$LOCAL_TAG")

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Container started: $CONTAINER_ID${NC}"
    
    # Wait for container to be ready
    echo "Waiting for application to start..."
    sleep 3
    
    # Test endpoints
    echo "Testing endpoints..."
    
    # Test version endpoint
    VERSION_RESPONSE=$(curl -s http://localhost:5001/version 2>/dev/null || echo "failed")
    if [[ $VERSION_RESPONSE == *"\"version\":\"$VERSION\""* ]]; then
        echo -e "${GREEN}✅ Version endpoint: $VERSION_RESPONSE${NC}"
    else
        echo -e "${RED}❌ Version endpoint failed: $VERSION_RESPONSE${NC}"
    fi
    
    # Test health endpoint
    HEALTH_RESPONSE=$(curl -s http://localhost:5001/health 2>/dev/null || echo "failed")
    if [[ $HEALTH_RESPONSE == *"\"status\":\"healthy\""* ]]; then
        echo -e "${GREEN}✅ Health endpoint: OK${NC}"
    else
        echo -e "${RED}❌ Health endpoint failed: $HEALTH_RESPONSE${NC}"
    fi
    
    # Test root endpoint
    ROOT_RESPONSE=$(curl -s http://localhost:5001/ 2>/dev/null || echo "failed")
    if [[ $ROOT_RESPONSE == *"\"application\":\"VersionApp\""* ]]; then
        echo -e "${GREEN}✅ Root endpoint: OK${NC}"
    else
        echo -e "${RED}❌ Root endpoint failed: $ROOT_RESPONSE${NC}"
    fi
    
    # Cleanup test container
    docker stop versionapp-test >/dev/null 2>&1
    docker rm versionapp-test >/dev/null 2>&1
    
    echo -e "${GREEN}✅ Test container cleaned up${NC}"
else
    echo -e "${RED}❌ Failed to start test container${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo ""
echo "Available commands:"
echo "  Run locally:  docker run -d -p 5000:5000 $LOCAL_TAG"
echo "  Check version: curl http://localhost:5000/version"
echo "  View logs:    docker logs <container_id>"
if [ "$PUSH" = true ]; then
    echo "  Pull from registry: docker pull $REGISTRY_TAG"
fi
echo ""