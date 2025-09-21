#!/bin/bash

# Containerized deployment script with Caddy reverse proxy
# Usage: ./deploy.sh [your-replicate-token]

set -e  # Exit on any error

APP_NAME="granite-chatbot"
GITHUB_REPO="https://github.com/HaryoWaskito/GraniteChatbot.git"
REPLICATE_TOKEN="$1"

echo "🚀 Starting containerized deployment with Caddy reverse proxy..."

# Check if token is provided
if [ -z "$REPLICATE_TOKEN" ]; then
    echo "❌ Error: Please provide Replicate API token"
    echo "Usage: ./deploy.sh YOUR_REPLICATE_TOKEN"
    exit 1
fi

# Check if podman-compose is available
if ! command -v podman-compose &> /dev/null; then
    echo "📦 Installing podman-compose..."
    if command -v pip3 &> /dev/null; then
        pip3 install podman-compose
    elif command -v apt &> /dev/null; then
        apt update && apt install -y python3-pip
        pip3 install podman-compose
    else
        echo "❌ Please install podman-compose manually"
        exit 1
    fi
fi

# Stop existing containers
echo "🛑 Stopping existing containers..."
podman-compose down 2>/dev/null || true
podman stop granite-caddy granite-chatbot 2>/dev/null || true
podman rm granite-caddy granite-chatbot 2>/dev/null || true

# Remove old images to force rebuild
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

# Create .env file for docker-compose
echo "📝 Creating environment configuration..."
cat > .env << EOF
REPLICATE_API_TOKEN=$REPLICATE_TOKEN
EOF

# Create logs directory
mkdir -p logs
chmod 755 logs

# Build and start containers
echo "🔨 Building and starting containers..."
podman-compose up -d --build

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Check if containers are running
if podman ps | grep -q granite-caddy && podman ps | grep -q granite-chatbot; then
    echo "✅ Deployment successful!"
    echo ""
    echo "🌐 Your chatbot is now available at:"
    echo "   🔗 https://granite-chatbot.my.id"
    echo "   🔗 http://granite-chatbot.my.id (will redirect to HTTPS)"
    echo ""
    echo "📊 Container status:"
    podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    # Test local connectivity
    echo "🧪 Testing local connectivity..."
    sleep 3
    if curl -f http://localhost:80 > /dev/null 2>&1; then
        echo "✅ Caddy is responding on port 80"
    else
        echo "⚠️  Caddy might still be starting up"
    fi
    
    echo "🔍 SSL certificate will be automatically obtained by Caddy"
    echo "   (This may take a few minutes for first-time setup)"
    
else
    echo "❌ Deployment failed. Checking container logs..."
    echo ""
    echo "=== Caddy Logs ==="
    podman logs granite-caddy 2>/dev/null || echo "Caddy container not found"
    echo ""
    echo "=== Chatbot Logs ==="
    podman logs granite-chatbot 2>/dev/null || echo "Chatbot container not found"
    exit 1
fi

echo ""
echo "🎉 Containerized deployment complete!"
echo ""
echo "📝 Useful commands:"
echo "   Check status:     podman-compose ps"
echo "   View logs:        podman-compose logs -f"
echo "   Restart services: podman-compose restart"
echo "   Stop services:    podman-compose down"
echo "   Update deployment: git pull && podman-compose up -d --build"