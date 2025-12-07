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

class FergusonCompleteLookupRequest(BaseModel):
    model_number: str = Field(..., description="Manufacturer model number")

def find_matching_variant(search_results: dict, model_number: str) -> Optional[str]:
    """
    Find the variant that matches the requested model number.
    Returns the variant's URL for use in detail lookup.
    Implements EXACT matching (case-insensitive).
    """
    model_upper = model_number.upper().strip()
    
    for product in search_results.get("products", []):
        for variant in product.get("variants", []):
            variant_model = variant.get("model_no", "").upper().strip()
            
            # Exact match (case-insensitive)
            if variant_model == model_upper:
                return variant.get("url")
    
    return None

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "ferguson-api",
        "version": "1.0.0",
        "unwrangle_configured": bool(UNWRANGLE_API_KEY),
        "endpoints": {
            "search": "/search-ferguson - Returns BASIC info only (10% of data)",
            "detail": "/product-detail-ferguson - Returns COMPLETE attributes (90% of data)",
            "complete": "/lookup-ferguson-complete - RECOMMENDED: All 3 steps automatically"
        },
        "warning": "⚠️ Always use /lookup-ferguson-complete or call both search AND detail endpoints"
    }

@app.post("/search-ferguson")
async def search_ferguson_products(request: FergusonSearchRequest, x_api_key: Optional[str] = Header(None)):
    """
    Search Ferguson products by model number or keyword.
    
    ⚠️ WARNING: This only returns BASIC data (name, brand, price, variants).
    You MUST call /product-detail-ferguson to get complete specifications!
    
    Returns only 10% of product data. Use /lookup-ferguson-complete instead.
    """
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    if not UNWRANGLE_API_KEY:
        raise HTTPException(status_code=500, detail="Unwrangle API key not configured")
    start_time = time.time()
    try:
        params = {"platform": "fergusonhome_search", "search": request.search, "page": request.page, "api_key": UNWRANGLE_API_KEY}
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
                "metadata": {"response_time": f"{response_time:.2f}s", "timestamp": datetime.utcnow().isoformat(), "api_version": "fergusonhome_search_v1"},
                "warning": "⚠️ INCOMPLETE DATA: This returns only basic info. Call /product-detail-ferguson for complete attributes."}
    except requests.RequestException as e:
        raise HTTPException(status_code=503, detail=f"Unwrangle API request failed: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ferguson search failed: {str(e)}")

@app.post("/product-detail-ferguson")
async def get_ferguson_product_detail(request: FergusonProductRequest, x_api_key: Optional[str] = Header(None)):
    """
    Get COMPLETE Ferguson product details with all attributes.
    
    ⚠️ CRITICAL: This endpoint returns the FULL product data including:
    - Complete specifications (material, dimensions, certifications)
    - Features list
    - High-resolution images
    - Variant-specific pricing and inventory
    - Warranty information
    - Installation resources
    - Reviews and ratings
    
    YOU MUST ALWAYS CALL THIS to get complete product attributes!
    This is the 90% of data not returned by search endpoint.
    """
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

@app.post("/lookup-ferguson-complete")
async def lookup_ferguson_complete(request: FergusonCompleteLookupRequest, x_api_key: Optional[str] = Header(None)):
    """
    Complete Ferguson product lookup - executes all 3 steps automatically.
    
    This is the RECOMMENDED endpoint to use for product enrichment.
    It handles:
    1. Searching for the product
    2. Finding matching variant
    3. Fetching complete product attributes
    
    Returns: Complete product data ready for enrichment
    Cost: 20 credits (10 for search + 10 for detail)
    """
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    if not UNWRANGLE_API_KEY:
        raise HTTPException(status_code=500, detail="Unwrangle API key not configured")
    
    model_number = request.model_number
    overall_start = time.time()
    
    try:
        # STEP 1: Search for product
        print(f"Step 1: Searching for model {model_number}...")
        step1_start = time.time()
        search_params = {
            "api_key": UNWRANGLE_API_KEY,
            "platform": "fergusonhome_search",
            "search": model_number,
            "page": 1
        }
        search_response = requests.get("https://data.unwrangle.com/api/getter/", params=search_params, timeout=45)
        search_response.raise_for_status()
        search_data = search_response.json()
        step1_time = time.time() - step1_start
        
        if not search_data.get("success"):
            raise HTTPException(status_code=404, detail="Product not found in Ferguson")
        
        if not search_data.get("results"):
            raise HTTPException(
                status_code=404,
                detail=f"No products found for model {model_number}"
            )
        
        print(f"Step 1: ✓ Found {len(search_data.get('results', []))} products ({step1_time:.2f}s)")
        
        # STEP 2: Find matching variant
        print(f"Step 2: Finding exact variant match for {model_number}...")
        step2_start = time.time()
        variant_url = find_matching_variant(
            {"products": search_data.get("results", [])},
            model_number
        )
        step2_time = time.time() - step2_start
        
        if not variant_url:
            # Return available variants for debugging
            available_variants = []
            for product in search_data.get("results", []):
                for variant in product.get("variants", []):
                    available_variants.append(variant.get("model_no"))
            
            raise HTTPException(
                status_code=404,
                detail={
                    "error": "Variant not found",
                    "requested_model": model_number,
                    "available_models": available_variants,
                    "hint": "Model number must match exactly (case-insensitive)",
                    "total_products_found": len(search_data.get("results", [])),
                    "total_variants_found": len(available_variants)
                }
            )
        
        print(f"Step 2: ✓ Found variant URL ({step2_time:.2f}s)")
        
        # STEP 3: Get complete product details
        print(f"Step 3: Fetching complete product attributes...")
        step3_start = time.time()
        import urllib.parse
        encoded_url = urllib.parse.quote(variant_url, safe='')
        
        detail_params = {
            "api_key": UNWRANGLE_API_KEY,
            "platform": "fergusonhome_detail",
            "url": encoded_url,
            "page": 1
        }
        detail_response = requests.get("https://data.unwrangle.com/api/getter/", params=detail_params, timeout=45)
        detail_response.raise_for_status()
        detail_data = detail_response.json()
        step3_time = time.time() - step3_start
        
        if not detail_data.get("success"):
            raise HTTPException(
                status_code=500,
                detail="Failed to fetch product details"
            )
        
        print(f"Step 3: ✓ Retrieved complete product data ({step3_time:.2f}s)")
        
        # Return COMPLETE product information - ALL fields from Unwrangle API
        product_detail = detail_data.get("detail", {})
        overall_time = time.time() - overall_start
        
        return {
            "success": True,
            "model_number": model_number,
            "variant_url": variant_url,
            "product": {
                # ========== BASIC INFORMATION ==========
                "id": product_detail.get("id"),
                "name": product_detail.get("name"),
                "brand": product_detail.get("brand"),
                "brand_url": product_detail.get("brand_url"),
                "brand_logo": product_detail.get("brand_logo"),
                "model_number": product_detail.get("model_number"),
                "url": product_detail.get("url"),
                "product_type": product_detail.get("product_type"),
                "application": product_detail.get("application"),
                
                # ========== PRICING & INVENTORY ==========
                "price": product_detail.get("price"),
                "price_range": product_detail.get("price_range", {}),
                "currency": product_detail.get("currency"),
                "base_type": product_detail.get("base_type"),
                "shipping_fee": product_detail.get("shipping_fee"),
                "has_free_installation": product_detail.get("has_free_installation"),
                
                # ========== INVENTORY & VARIANTS ==========
                "variants": product_detail.get("variants", []),
                "variant_count": product_detail.get("variant_count"),
                "has_variant_groups": product_detail.get("has_variant_groups"),
                "has_in_stock_variants": product_detail.get("has_in_stock_variants"),
                "all_variants_in_stock": product_detail.get("all_variants_in_stock"),
                "total_inventory_quantity": product_detail.get("total_inventory_quantity"),
                "in_stock_variant_count": product_detail.get("in_stock_variant_count"),
                "is_configurable": product_detail.get("is_configurable"),
                "configuration_type": product_detail.get("configuration_type"),
                
                # ========== IMAGES & VIDEOS ==========
                "images": product_detail.get("images", []),
                "videos": product_detail.get("videos", []),
                
                # ========== PRODUCT DETAILS ==========
                "description": product_detail.get("description"),
                "is_discontinued": product_detail.get("is_discontinued"),
                
                # ========== SPECIFICATIONS (CRITICAL!) ==========
                "specifications": product_detail.get("specifications", {}),
                "feature_groups": product_detail.get("feature_groups", []),
                "dimensions": product_detail.get("dimensions", {}),
                "attribute_ids": product_detail.get("attribute_ids", []),
                
                # ========== IDENTIFIERS ==========
                "upc": product_detail.get("upc"),
                "barcode": product_detail.get("barcode"),
                
                # ========== CERTIFICATIONS & COMPLIANCE ==========
                "certifications": product_detail.get("certifications", []),
                "country_of_origin": product_detail.get("country_of_origin"),
                
                # ========== WARRANTY ==========
                "warranty": product_detail.get("warranty"),
                "manufacturer_warranty": product_detail.get("manufacturer_warranty"),
                
                # ========== RESOURCES & DOCUMENTATION ==========
                "resources": product_detail.get("resources", []),
                
                # ========== CATEGORIES ==========
                "categories": product_detail.get("categories", []),
                "base_category": product_detail.get("base_category"),
                "business_category": product_detail.get("business_category"),
                "related_categories": product_detail.get("related_categories", []),
                
                # ========== REVIEWS & RATINGS ==========
                "rating": product_detail.get("rating"),
                "review_count": product_detail.get("review_count"),
                "total_reviews": product_detail.get("total_reviews"),
                "questions_count": product_detail.get("questions_count"),
                
                # ========== COLLECTION ==========
                "collection": product_detail.get("collection"),
                
                # ========== RELATED PRODUCTS & OPTIONS ==========
                "has_recommended_options": product_detail.get("has_recommended_options"),
                "recommended_options": product_detail.get("recommended_options", []),
                "has_accessories": product_detail.get("has_accessories"),
                "has_replacement_parts": product_detail.get("has_replacement_parts"),
                "replacement_parts_url": product_detail.get("replacement_parts_url"),
                
                # ========== SPECIAL FLAGS ==========
                "is_by_appointment_only": product_detail.get("is_by_appointment_only")
            },
            "credits_used": 20,
            "steps_completed": {
                "1_search": "✓",
                "2_variant_match": "✓",
                "3_detail_fetch": "✓"
            },
            "performance": {
                "step1_search_time": f"{step1_time:.2f}s",
                "step2_match_time": f"{step2_time:.2f}s",
                "step3_detail_time": f"{step3_time:.2f}s",
                "total_time": f"{overall_time:.2f}s"
            },
            "metadata": {
                "timestamp": datetime.utcnow().isoformat(),
                "api_version": "ferguson_complete_v1"
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Complete lookup failed: {str(e)}"
        )

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"success": False, "error": exc.detail})

@app.exception_handler(Exception)
async def general_exception_handler(request, exc: Exception):
    return JSONResponse(status_code=500, content={"success": False, "error": f"Internal server error: {str(exc)}"})

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=PORT, reload=False)
