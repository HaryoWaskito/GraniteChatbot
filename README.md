# Granite Chatbot

A beautiful AI chatbot powered by IBM Granite model via Replicate.com

## 🚀 Quick Deployment on VPS

### Prerequisites

- Linux VPS with Podman installed
- Git installed
- Your Replicate API token

### One-Command Deployment

1. **SSH to your VPS**
2. **Run this single command:**
   ```bash
   curl -sSL https://raw.githubusercontent.com/HaryoWaskito/GraniteChatbot/main/deploy.sh | bash -s YOUR_REPLICATE_TOKEN
   ```

### Manual Deployment

```bash
# Clone the repository
git clone https://github.com/HaryoWaskito/GraniteChatbot.git
cd GraniteChatbot

# Make deploy script executable
chmod +x deploy.sh

# Deploy with your token
./deploy.sh YOUR_REPLICATE_TOKEN
```

## 🔧 Local Development

### With Podman

```bash
# Build
podman build -t granite-chatbot .

# Run
podman run -d -p 8080:80 --name granite-chatbot \
  -e "Replicate__ApiToken=YOUR_TOKEN" \
  granite-chatbot

# Check logs
podman logs granite-chatbot

# Stop
podman stop granite-chatbot && podman rm granite-chatbot
```

### With .NET CLI

```bash
# Run locally
dotnet run

# Access at http://localhost:5159
```

## 🌐 Access Your Chatbot

After deployment, access your chatbot at:

- **Local:** http://localhost:8080
- **VPS:** http://YOUR_VPS_IP:8080

## 🔄 Update Deployment

To update with new changes:

```bash
./deploy.sh YOUR_REPLICATE_TOKEN
```

## 🛠️ Troubleshooting

### Check container status

```bash
podman ps -a
podman logs granite-chatbot
```

### Check if port is accessible

```bash
curl http://localhost:8080
netstat -tlnp | grep 8080
```

### Restart container

```bash
podman restart granite-chatbot
```
