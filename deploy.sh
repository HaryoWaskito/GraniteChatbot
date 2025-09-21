#!/bin/bash

# Simple deployment script for VPS with Podman
# Usage: ./deploy.sh [your-replicate-token]

set -e  # Exit on any error

APP_NAME="granite-chatbot"
GITHUB_REPO="https://github.com/HaryoWaskito/GraniteChatbot.git"
REPLICATE_TOKEN="$1"

echo "🚀 Starting deployment of $APP_NAME..."

# Check if token is provided
if [ -z "$REPLICATE_TOKEN" ]; then
    echo "❌ Error: Please provide Replicate API token"
    echo "Usage: ./deploy.sh YOUR_REPLICATE_TOKEN"
    exit 1
fi

# Stop and remove existing container if it exists
echo "🛑 Stopping existing container (if any)..."
podman stop $APP_NAME 2>/dev/null || true
podman rm $APP_NAME 2>/dev/null || true

# Remove old image to force rebuild
podman rmi $APP_NAME 2>/dev/null || true

# Clone or update repository
if [ -d "$APP_NAME" ]; then
    echo "📁 Updating existing repository..."
    cd $APP_NAME
    git pull origin main
else
    echo "📥 Cloning repository..."
    git clone $GITHUB_REPO $APP_NAME
    cd $APP_NAME
fi

# Build new image
echo "🔨 Building container image..."
podman build -t $APP_NAME .

# Run new container with correct port mapping
echo "🏃 Starting new container..."
podman run -d \
    --name $APP_NAME \
    -p 8080:8080 \
    -e "Replicate__ApiToken=$REPLICATE_TOKEN" \
    -e "ASPNETCORE_ENVIRONMENT=Production" \
    --restart=always \
    $APP_NAME

# Check if container is running
sleep 5
if podman ps | grep -q $APP_NAME; then
    echo "✅ Deployment successful!"
    echo "🌐 App is running at: http://103.127.134.226:8080"
    echo "📊 Container status:"
    podman ps | grep $APP_NAME
    
    # Test the deployment
    echo "🧪 Testing deployment..."
    sleep 3
    if curl -f http://localhost:8080 > /dev/null 2>&1; then
        echo "✅ App is responding correctly!"
    else
        echo "⚠️  App might still be starting up. Check logs if needed:"
        echo "   podman logs $APP_NAME"
    fi
else
    echo "❌ Deployment failed. Check logs:"
    podman logs $APP_NAME
    exit 1
fi

echo "🎉 Deployment complete!"
echo "📝 Useful commands:"
echo "   Check logs: podman logs $APP_NAME"
echo "   Restart: podman restart $APP_NAME"
echo "   Stop: podman stop $APP_NAME"