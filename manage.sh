#!/bin/bash

# Container management script for Granite Chatbot
# Usage: ./manage.sh [command]

set -e

COMPOSE_CMD="podman-compose"

# Check if podman-compose exists, fallback to docker-compose
if ! command -v podman-compose &> /dev/null; then
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        echo "❌ Neither podman-compose nor docker-compose found"
        echo "📦 Install with: pip3 install podman-compose"
        exit 1
    fi
fi

show_usage() {
    echo "🚀 Granite Chatbot Container Management"
    echo ""
    echo "Usage: ./manage.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Start all services"
    echo "  stop      - Stop all services"  
    echo "  restart   - Restart all services"
    echo "  status    - Show container status"
    echo "  logs      - Show logs (follow)"
    echo "  build     - Rebuild containers"
    echo "  update    - Pull latest code and rebuild"
    echo "  clean     - Stop and remove all containers/volumes"
    echo "  ssl       - Check SSL certificate status"
    echo "  health    - Health check"
    echo ""
    echo "Examples:"
    echo "  ./manage.sh status"
    echo "  ./manage.sh logs"
    echo "  ./manage.sh restart"
}

case "${1:-}" in
    "start")
        echo "🚀 Starting Granite Chatbot services..."
        $COMPOSE_CMD up -d
        echo "✅ Services started!"
        $COMPOSE_CMD ps
        ;;
    
    "stop")
        echo "🛑 Stopping services..."
        $COMPOSE_CMD down
        echo "✅ Services stopped!"
        ;;
    
    "restart")
        echo "🔄 Restarting services..."
        $COMPOSE_CMD restart
        echo "✅ Services restarted!"
        $COMPOSE_CMD ps
        ;;
    
    "status"|"ps")
        echo "📊 Container Status:"
        $COMPOSE_CMD ps
        echo ""
        echo "🌐 Service URLs:"
        echo "   Main site: https://granite-chatbot.my.id"
        echo "   Health:    https://health.granite-chatbot.my.id"
        ;;
    
    "logs")
        echo "📝 Following logs (Ctrl+C to exit):"
        $COMPOSE_CMD logs -f
        ;;
    
    "build")
        echo "🔨 Rebuilding containers..."
        $COMPOSE_CMD up -d --build
        echo "✅ Rebuild complete!"
        ;;
    
    "update")
        echo "📥 Pulling latest code..."
        git pull origin main
        echo "🔨 Rebuilding with latest code..."
        $COMPOSE_CMD up -d --build
        echo "✅ Update complete!"
        $COMPOSE_CMD ps
        ;;
    
    "clean")
        echo "🧹 Cleaning up containers and volumes..."
        $COMPOSE_CMD down -v --remove-orphans
        # Remove images
        podman rmi granite-chatbot 2>/dev/null || true
        echo "✅ Cleanup complete!"
        ;;
    
    "ssl")
        echo "🔒 Checking SSL certificate..."
        echo "Certificate info for granite-chatbot.my.id:"
        openssl s_client -connect granite-chatbot.my.id:443 -servername granite-chatbot.my.id 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "❌ SSL check failed"
        ;;
    
    "health")
        echo "🏥 Health check..."
        if curl -f https://granite-chatbot.my.id > /dev/null 2>&1; then
            echo "✅ Main site is healthy"
        else
            echo "❌ Main site is not responding"
        fi
        
        if curl -f https://health.granite-chatbot.my.id/health > /dev/null 2>&1; then
            echo "✅ Health endpoint is responding"
        else
            echo "❌ Health endpoint is not responding"
        fi
        ;;
    
    "help"|"--help"|"-h"|"")
        show_usage
        ;;
    
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac