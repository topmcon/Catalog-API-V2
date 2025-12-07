# Ferguson API - Catalog Integration

## 🚀 Quick Start

This API provides Ferguson product data integration for Salesforce and other catalog systems.

**Current Version:** Port 8001 (Production)  
**API Key:** `catbot123`  
**Base URL:** `http://cxc-ai.com:8001`

---

## 📁 Repository Contents

### Essential Files
- **`main.py`** - FastAPI server implementation
- **`requirements.txt`** - Python dependencies
- **`CxcFergusionAPI_UPDATED.apex`** - Updated Salesforce Apex class
- **`SALESFORCE_DEPLOYMENT_GUIDE.md`** - Complete deployment instructions
- **`QUICK_REFERENCE.md`** - API endpoint documentation

### Configuration
- **`.env.example`** - Environment variable template
- **`runtime.txt`** - Python version specification

---

## 🔧 API Endpoints

### Health Check
```bash
GET /health
Response: {"status": "healthy"}
```

### Complete Product Lookup (Recommended)
```bash
POST /lookup-ferguson-complete
Headers: X-API-KEY: catbot123
Body: {"model_number": "K-97621-SHP"}

Response: {
  "status": "success",
  "match_type": "exact|prefix|hyphen|fuzzy|none",
  "model_searched": "K-97621-SHP",
  "detail": { /* full product data */ }
}
```

### Search Products
```bash
POST /search-ferguson
Headers: X-API-KEY: catbot123
Body: {"search": "97621-SHP", "page": 1}
```

### Get Product Details
```bash
POST /product-detail-ferguson
Headers: X-API-KEY: catbot123
Body: {"url": "https://www.ferguson.com/product/..."}
```

---

## 💻 Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
nano .env  # Add UNWRANGLE_API_KEY

# Run server
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

Server runs at: `http://localhost:8001`  
API docs available at: `http://localhost:8001/docs`

---

## 🔧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `UNWRANGLE_API_KEY` | Unwrangle API key (required) | - |
| `API_KEY` | Authentication key for requests | `catbot123` |
| `PORT` | Server port | `8001` |

---

## 📦 Salesforce Integration

Deploy the updated Ferguson API to your Salesforce org:

1. **Read the guide:** `SALESFORCE_DEPLOYMENT_GUIDE.md`
2. **Use updated code:** `CxcFergusionAPI_UPDATED.apex`
3. **Key change:** Port 8000 → 8001

**Time:** 15-30 minutes | **Risk:** Low

---

## 💡 API Credits & Costs

- **Search:** 10 credits/call
- **Detail:** 10 credits/call  
- **Complete Lookup:** 10 credits/call ⭐ **(Recommended - includes smart matching)**

---

## 🧪 Testing the API

Quick test commands:

```bash
# Health check
curl http://localhost:8001/health

# Search for a product
curl -X POST http://localhost:8001/search-ferguson \
  -H "X-API-KEY: catbot123" \
  -H "Content-Type: application/json" \
  -d '{"search": "K-97621-SHP"}'

# Complete lookup with smart matching
curl -X POST http://localhost:8001/lookup-ferguson-complete \
  -H "X-API-KEY: catbot123" \
  -H "Content-Type: application/json" \
  -d '{"model_number": "97621-SHP"}'
```

---

## 📚 Documentation

- **`QUICK_REFERENCE.md`** - API endpoint reference
- **`SALESFORCE_DEPLOYMENT_GUIDE.md`** - Complete Salesforce deployment guide
- **`CxcFergusionAPI_UPDATED.apex`** - Updated Apex class code

---

## ✅ Test Status

**Last Tested:** December 7, 2025

| Component | Status | Details |
|-----------|--------|---------|
| API Server | ✅ PASSED | All endpoints operational |
| Health Check | ✅ PASSED | Response < 100ms |
| Search Endpoint | ✅ PASSED | Returns product data with variants |
| Detail Endpoint | ✅ PASSED | Complete specs, images, resources |
| Complete Lookup | ✅ PASSED | Smart matching working (Kohler, Graff tested) |
| Apex Class | ✅ VALIDATED | Syntax valid, port 8001 configured |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📄 License

Proprietary - Ferguson API Integration
