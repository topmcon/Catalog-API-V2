# Ferguson API

## Server Deployment (198.211.105.43)

```bash
# On server
cd /root && git clone YOUR_REPO_URL ferguson-api && cd ferguson-api
cp .env.example .env && nano .env  # Add UNWRANGLE_API_KEY
pip install -r requirements.txt

# Create systemd service
sudo tee /etc/systemd/system/ferguson-api.service > /dev/null << 'SERVICE'
[Unit]
Description=Ferguson API Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/ferguson-api
EnvironmentFile=/root/ferguson-api/.env
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload && sudo systemctl enable ferguson-api && sudo systemctl start ferguson-api
```

## API Endpoints

### Health Check
```bash
GET /health
```

### Search Ferguson Products
```bash
POST /search-ferguson
Headers: x-api-key: catbot123
Body: {"search": "faucet", "page": 1}
```

### Get Product Details
```bash
POST /product-detail-ferguson
Headers: x-api-key: catbot123
Body: {"url": "https://www.ferguson.com/product/..."}
```

## Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Copy and configure environment
cp .env.example .env
# Edit .env and add your UNWRANGLE_API_KEY

# Run the server
python main.py
```

## Environment Variables

- `UNWRANGLE_API_KEY` - Your Unwrangle API key (required)
- `API_KEY` - API key for authenticating requests (default: catbot123)
- `PORT` - Server port (default: 8000)
