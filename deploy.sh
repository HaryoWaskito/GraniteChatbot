#!/bin/bash

# Sequential container deployment script (fixes cgroup issues)
# Usage: ./deploy.sh [your-replicate-token]

set -e  # Exit on any error

APP_NAME="granite-chatbot"
GITHUB_REPO="https://github.com/HaryoWaskito/GraniteChatbot.git"
REPLICATE_TOKEN="$1"

echo "🚀 Starting sequential containerized deployment..."

# Check if token is provided
if [ -z "$REPLICATE_TOKEN" ]; then
    echo "❌ Error: Please provide Replicate API token"
    echo "Usage: ./deploy.sh YOUR_REPLICATE_TOKEN"
    exit 1
fi

# Stop and remove existing containers
echo "🛑 Cleaning up existing containers..."
podman stop granite-caddy granite-chatbot 2>/dev/null || true
podman rm granite-caddy granite-chatbot 2>/dev/null || true

# Remove old images
echo "🧹 Cleaning up old images..."
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

# Build the chatbot image
echo "🔨 Building chatbot container..."
podman build -t $APP_NAME .

# Start the chatbot container first
echo "🏃 Starting chatbot container..."
podman run -d \
    --name granite-chatbot \
    -p 8080:8080 \
    -e "Replicate__ApiToken=$REPLICATE_TOKEN" \
    -e "ASPNETCORE_ENVIRONMENT=Production" \
    -e "ASPNETCORE_URLS=http://+:8080" \
    --restart=always \
    $APP_NAME

# Wait for chatbot to be ready
echo "⏳ Waiting for chatbot to start..."
sleep 10

# Check if chatbot is running
if ! podman ps | grep -q granite-chatbot; then
    echo "❌ Chatbot container failed to start. Checking logs..."
    podman logs granite-chatbot
    exit 1
fi

# Test if chatbot is responding
echo "🧪 Testing chatbot connectivity..."
if curl -f http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Chatbot is responding on port 8080"
else
    echo "⚠️ Chatbot might still be starting up..."
fi

# Start Caddy container
echo "🔧 Starting Caddy reverse proxy..."
podman run -d \
    --name granite-caddy \
    -p 80:80 -p 443:443 \
    -v caddy_data:/data \
    -v caddy_config:/config \
    --restart=always \
    caddy:2-alpine \
    caddy reverse-proxy --from granite-chatbot.my.id --to localhost:8080

# Wait for Caddy to start
sleep 5

# Check final status
echo "📊 Final container status:"
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

if podman ps | grep -q granite-caddy && podman ps | grep -q granite-chatbot; then
    echo ""
    echo "🎉 Deployment successful!"
    echo ""
    echo "🌐 Your chatbot is available at:"
    echo "   🔗 Direct: http://103.127.134.226:8080"
    echo "   🔗 Domain: http://granite-chatbot.my.id (via Caddy)"
    echo "   🔒 HTTPS: https://granite-chatbot.my.id (auto-SSL)"
    echo ""
    echo "📊 Service Status:"
    echo "   ✅ Chatbot: Running on port 8080"
    echo "   ✅ Caddy: Running on ports 80/443"
    echo ""
    echo "🔍 SSL certificate will be automatically obtained by Caddy"
    
else
    echo "❌ Some containers failed to start. Checking logs..."
    echo ""
    echo "=== Chatbot Logs ==="
    podman logs granite-chatbot 2>/dev/null || echo "Chatbot container not found"
    echo ""
    echo "=== Caddy Logs ==="
    podman logs granite-caddy 2>/dev/null || echo "Caddy container not found"
    exit 1
fi

echo ""
echo "📝 Useful commands:"
echo "   Check status: podman ps"
echo "   Chatbot logs: podman logs granite-chatbot"
echo "   Caddy logs:   podman logs granite-caddy"
echo "   Restart:      ./deploy.sh $REPLICATE_TOKEN"