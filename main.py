"""Ferguson API - Standalone Service"""
import os
import time
from datetime import datetime
from typing import Optional
from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from dotenv import load_dotenv
import requests

load_dotenv()
UNWRANGLE_API_KEY = os.getenv("UNWRANGLE_API_KEY")
API_KEY = os.getenv("API_KEY", "catbot123")
PORT = int(os.getenv("PORT", 8000))

app = FastAPI(title="Ferguson API", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

class FergusonSearchRequest(BaseModel):
    search: str = Field(..., description="Search query")
    page: int = Field(1, ge=1)

class FergusonProductRequest(BaseModel):
    url: str = Field(..., description="Ferguson product URL")

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "ferguson-api", "version": "1.0.0", "unwrangle_configured": bool(UNWRANGLE_API_KEY)}

@app.post("/search-ferguson")
async def search_ferguson_products(request: FergusonSearchRequest, x_api_key: Optional[str] = Header(None)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    if not UNWRANGLE_API_KEY:
        raise HTTPException(status_code=500, detail="Unwrangle API key not configured")
    start_time = time.time()
    try:
        params = {"platform": "fergusonhome_search", "query": request.search, "page": request.page, "api_key": UNWRANGLE_API_KEY}
        response = requests.get("https://data.unwrangle.com/api/getter/", params=params, timeout=45)
        response.raise_for_status()
        data = response.json()
        if not data.get("success"):
            raise HTTPException(status_code=500, detail="Ferguson search unsuccessful")
        response_time = time.time() - start_time
        return {"success": True, "platform": "fergusonhome_search", "search_query": request.search, "page": request.page,
                "total_results": data.get("total_results", 0), "total_pages": data.get("no_of_pages", 0),
                "result_count": data.get("result_count", 0), "products": data.get("results", []),
                "meta_data": data.get("meta_data", {}), "credits_used": data.get("credits_used", 10),
                "metadata": {"response_time": f"{response_time:.2f}s", "timestamp": datetime.utcnow().isoformat(), "api_version": "fergusonhome_search_v1"}}
    except requests.RequestException as e:
        raise HTTPException(status_code=503, detail=f"Unwrangle API request failed: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ferguson search failed: {str(e)}")

@app.post("/product-detail-ferguson")
async def get_ferguson_product_detail(request: FergusonProductRequest, x_api_key: Optional[str] = Header(None)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    if not UNWRANGLE_API_KEY:
        raise HTTPException(status_code=500, detail="Unwrangle API key not configured")
    start_time = time.time()
    try:
        import urllib.parse
        encoded_url = urllib.parse.quote(request.url, safe='')
        params = {"platform": "fergusonhome_detail", "url": encoded_url, "page": 1, "api_key": UNWRANGLE_API_KEY}
        response = requests.get("https://data.unwrangle.com/api/getter/", params=params, timeout=45)
        response.raise_for_status()
        data = response.json()
        if not data.get("success"):
            raise HTTPException(status_code=500, detail="Ferguson detail request unsuccessful")
        response_time = time.time() - start_time
        return {"success": True, "platform": "fergusonhome_detail", "url": request.url, "result_count": data.get("result_count", 0),
                "detail": data.get("detail", {}), "credits_used": data.get("credits_used", 10),
                "metadata": {"response_time": f"{response_time:.2f}s", "timestamp": datetime.utcnow().isoformat(), "api_version": "fergusonhome_detail_v1"}}
    except requests.RequestException as e:
        raise HTTPException(status_code=503, detail=f"Unwrangle API request failed: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ferguson detail failed: {str(e)}")

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"success": False, "error": exc.detail})

@app.exception_handler(Exception)
async def general_exception_handler(request, exc: Exception):
    return JSONResponse(status_code=500, content={"success": False, "error": f"Internal server error: {str(exc)}"})

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=PORT, reload=False)
