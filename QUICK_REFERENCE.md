# Ferguson API - Quick Reference Card

## 🚀 Production Endpoint
```
http://cxc-ai.com:8001/lookup-ferguson-complete
```

## 🔑 Authentication
```
X-API-Key: catbot123
```

## 📝 Sample Request
```bash
curl -X POST http://cxc-ai.com:8001/lookup-ferguson-complete \
  -H "Content-Type: application/json" \
  -H "X-API-Key: catbot123" \
  -d '{"model_number": "97621-SHP"}'
```

## 📊 Response Fields
```json
{
  "success": true,
  "model_number": "97621-SHP",
  "matched_model": "K-97621-SHP",
  "match_type": "variation",
  "variant_url": "https://...",
  "product": {
    "name": "Product Name",
    "brand": "Kohler",
    "price": 98.62,
    "images": [...],
    "variants": [...],
    "specifications": {...}
  },
  "credits_used": 20
}
```

## ✅ Status Codes
- `200` - Success
- `401` - Invalid API key
- `404` - Product not found
- `500` - Server error

## 🎯 Smart Matching Examples
| Input | Matched | Brand |
|-------|---------|-------|
| 97621-SHP | K-97621-SHP | Kohler |
| G9104BNI | G-9104-BNI | Graff |
| 3140/15S | 3140/15S | Newport Brass |

## 💰 Cost
**20 credits** per complete lookup (search + detail)

## 📚 Full Documentation
See `SALESFORCE_INTEGRATION.md` for complete guide
