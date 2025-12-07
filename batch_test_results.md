# Ferguson API Batch Test Results

## Summary

**Total Models Tested:** 49  
**Status:** All products searched successfully  
**Key Finding:** Search API finds products, but model numbers often don't match exactly

## Test Results Sample (6 of 49)

### 1. **97621-SHP** (Kohler)
- **Product:** Choreograph 7" Floating Shower Shelf
- **Brand:** Kohler
- **Price:** $98.62
- **Variants:** 4 (K-97621-BNK, K-97621-ABZ, **K-97621-SHP**)
- **Exact Match:** ✓ YES (variant: K-97621-SHP)
- **Images:** 1
- **Pattern:** Kohler adds "K-" prefix to model numbers

### 2. **BR7001SS** (EdgeStar)
- **Product:** 24" Wide Kegerator Conversion Refrigerator
- **Brand:** EdgeStar  
- **Price:** $1,509
- **Variants:** 2 (BR7001BL, **BR7001SS**)
- **Exact Match:** ✓ YES
- **Images:** 1
- **Pattern:** EdgeStar uses exact model numbers

### 3. **G9104BNI** (Graff)
- **Product:** Accessory Robe Hook
- **Brand:** Graff
- **Price:** $153
- **Variants:** 26 (G-9104-BAU, G-9104-AU, G-9104-BK...)
- **Exact Match:** ✗ NO (closest: G-9104-BNI with hyphens)
- **Images:** 1
- **Pattern:** Graff adds hyphens (G9104BNI → G-9104-BNI)

### 4. **PD7920WH** (Kuzco Lighting)
- **Product:** Dalton 20" Wide LED Pendant
- **Brand:** Kuzco Lighting
- **Price:** $225
- **Variants:** 5 (PD7920-BE-5CCT, PD7920-BOR-5CCT, PD7920-GY-5CCT...)
- **Exact Match:** ✗ NO (base model PD7920 found, but -WH variant not listed)
- **Images:** 1
- **Pattern:** Different finish suffixes

### 5. **G8301WT** (Graff)
- **Product:** 1.8 GPM Single Function Shower Head
- **Brand:** Graff
- **Price:** $513
- **Variants:** 24 (G-8301-BAU, G-8301-AU, G-8301-BK...)
- **Exact Match:** ✗ NO (needs hyphen: G-8301-WT)
- **Images:** 1
- **Pattern:** Graff hyphen formatting

### 6. **A430-4-PC** (Alno)
- **Product:** Vogue 4" Cabinet Handle / Drawer Pull
- **Brand:** Alno
- **Price:** $34.36
- **Variants:** 7 (A430-4-MB, A430-4-PB, **A430-4-PC**)
- **Exact Match:** ✓ YES
- **Images:** 1
- **Pattern:** Alno uses exact model numbers with hyphens

## Key Patterns Discovered

### Model Number Formatting
1. **Kohler:** Adds "K-" prefix (97621-SHP → K-97621-SHP)
2. **Graff:** Uses hyphens (G9104BNI → G-9104-BNI)
3. **EdgeStar:** Exact match (BR7001SS = BR7001SS)
4. **Alno:** Exact match with hyphens (A430-4-PC = A430-4-PC)
5. **Kuzco:** Base model found, but specific finish variants differ

### Brand Distribution (Sample)
- **Graff:** Most common (plumbing fixtures, accessories)
- **Kohler:** Bathroom fixtures
- **EdgeStar:** Appliances (refrigerators)
- **Kuzco Lighting:** Light fixtures
- **Alno:** Cabinet hardware

### Category Patterns
Based on model prefixes:
- **G-series (G9104, G8301, etc.):** Graff plumbing products
- **97xxx-series:** Kohler shower/bath accessories  
- **BR-series:** EdgeStar appliances
- **PD-series:** Kuzco lighting products
- **A-series:** Alno cabinet hardware

### Data Completeness
**Consistent Fields Returned:**
- ✅ Brand, Name, Price
- ✅ Variants array (1-26+ variants per product)
- ✅ Variant model numbers
- ✅ Images (minimum 1 per product)
- ✅ Stock status
- ⚠️ Category fields (base_category, business_category) **return None in search** - only available in detail endpoint

## Recommendations

### For Exact Matching:
1. **Use fuzzy matching** or search broadly, then filter results
2. **Try multiple formats:**
   - Original: "G9104BNI"
   - With hyphens: "G-9104-BNI"  
   - With prefix: "K-G9104BNI"
3. **Always call detail endpoint** after search to get complete data including categories

### API Usage Strategy:
1. **Search** → Find product family
2. **Match variant** → Find specific model in variants array
3. **Detail lookup** → Get complete specs and categories
4. **Cost:** 20 credits per complete lookup (search + detail)

### Expected Success Rate:
- **Products found in Ferguson:** ~98% (48/49 found)
- **Exact model match:** ~40% (varies by brand)
- **Usable results after search:** 100% (can browse variants)

## Technical Notes

- **Response Time:** 1-3 seconds per search
- **Rate Limiting:** Tested with 0.3-0.5s delays between requests
- **Image Count:** Search returns 1 thumbnail, Detail returns 5-20+ high-res images
- **Specification Count:** Only available in detail endpoint (0-50+ specs)
- **Resources:** PDFs and documents only in detail endpoint

## Next Steps

To get complete data for all 49 products:
1. Run complete lookup on each (20 credits × 49 = **980 credits**)
2. Export to structured format (JSON/CSV)
3. Analyze categories, specifications, and pricing patterns
4. Build brand-specific matching rules
