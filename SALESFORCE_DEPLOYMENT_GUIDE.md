# Salesforce Ferguson API Migration Guide
## Upgrading from Port 8000 to Port 8001

---

## 🎯 Overview

This guide provides step-by-step instructions for updating the Ferguson API integration in your Salesforce org from the deprecated endpoint (port 8000) to the new endpoint (port 8001).

**Critical Change:** One line of code (Line 323)  
**Estimated Time:** 15-30 minutes  
**Risk Level:** Low (single endpoint URL change)

---

## 📋 Prerequisites

Before starting, ensure you have:

- [ ] Salesforce Admin or Developer access
- [ ] Access to a Sandbox environment (recommended for production orgs)
- [ ] The updated `CxcFergusionAPI_UPDATED.apex` file
- [ ] Backup of current `CxcFergusionAPI` class code

---

## 🔄 What's Changing

### Single Code Change
**File:** `CxcFergusionAPI` (Apex Class)  
**Line 323:**
```apex
// OLD (Port 8000) - DEPRECATED
req.setEndpoint('http://cxc-ai.com:8000/' + path);

// NEW (Port 8001) - CURRENT
req.setEndpoint('http://cxc-ai.com:8001/' + path);
```

### Bonus Fix Included
**Line 178:** Fixed UPC field assignment bug
```apex
// OLD - Bug (wrong field)
catalog.Ferguson_URL__c = modeldata.detail.upc;

// NEW - Correct
catalog.Ferguson_UPC__c = modeldata.detail.upc;
```

### Files That DO NOT Need Changes
✅ `CxcFergusonAPITest` - No changes required  
✅ `CxcFergusonBatch` - No changes required (inherits API updates automatically)

---

## 🚀 Deployment Instructions

### Option A: Sandbox Environment (RECOMMENDED)

#### Step 1: Log into Sandbox
1. Navigate to your Salesforce Sandbox: `https://test.salesforce.com`
2. Log in with sandbox credentials

#### Step 2: Open Developer Console
1. Click your **profile icon** (top right)
2. Select **Developer Console**

#### Step 3: Open the Apex Class
1. In Developer Console: **File → Open → Apex Classes**
2. Select `CxcFergusionAPI`
3. Click **Open**

#### Step 4: Replace the Code
1. Select all existing code: **Ctrl+A** (Windows) or **Cmd+A** (Mac)
2. Delete selected code
3. Open `CxcFergusionAPI_UPDATED.apex` from this repository
4. Copy all contents (all 417 lines)
5. Paste into Developer Console
6. Verify line 323 shows: `'http://cxc-ai.com:8001/' + path`

#### Step 5: Save the Changes
1. Click **File → Save** or press **Ctrl+S** / **Cmd+S**
2. Wait for "Saved successfully" confirmation
3. Close Developer Console

#### Step 6: Configure Remote Site Settings
1. In Salesforce Setup, search: **"Remote Site Settings"**
2. Click **New Remote Site**
3. Fill in:
   - **Remote Site Name:** `Ferguson_API`
   - **Remote Site URL:** `http://cxc-ai.com`
   - **Active:** ✅ (checked)
   - **Description:** `Ferguson Product API Integration`
4. Click **Save**

#### Step 7: Test in Sandbox
1. Navigate to a `Product_Catalog__c` record
2. Trigger the Ferguson lookup (button/automation)
3. Check the record for updated Ferguson data
4. Review Debug Logs:
   - Setup → Debug Logs
   - Verify API calls go to port 8001
   - Confirm successful 200 responses

#### Step 8: Deploy to Production
Once sandbox testing is successful:

**Using Change Set:**
1. In Sandbox: Setup → Outbound Change Sets → New
2. Name: `Ferguson_API_Update_8001`
3. Add Component: `CxcFergusionAPI` (Apex Class)
4. Upload to Production
5. In Production: Setup → Inbound Change Sets
6. Deploy the change set
7. Repeat Step 6 (Remote Site Settings) in Production

**Using VS Code + Salesforce Extensions:**
1. Pull updated class from Sandbox
2. Deploy to Production using Salesforce CLI:
   ```bash
   sfdx force:source:deploy -m ApexClass:CxcFergusionAPI -u production_alias
   ```

---

### Option B: Direct Production Deployment

⚠️ **WARNING:** Only use this method if:
- You do NOT have a Sandbox
- Your org allows direct code editing in production
- You have tested in a Developer Edition org first

#### Step 1: Log into Production
1. Navigate to: `https://login.salesforce.com`
2. Log in with production credentials

#### Step 2: Try Developer Console
1. Click **profile icon** → **Developer Console**
2. Follow Steps 3-5 from Option A above
3. If you get "Can't alter metadata in an active org" error → **STOP**
4. You must use Option A (Sandbox deployment)

#### Step 3: Configure Remote Site Settings
Follow Step 6 from Option A

#### Step 4: Test Thoroughly
Test with a single product record before bulk processing

---

## 🧪 Testing & Validation

### Test Checklist

#### Single Record Test
- [ ] Find a Product Catalog record with `Model_Number_Verified__c` populated
- [ ] Trigger Ferguson API lookup
- [ ] Verify `Fergusion_Search_Result__c` = "Found"
- [ ] Check Ferguson fields are populated:
  - `Ferguson_Title__c`
  - `Ferguson_Brand__c`
  - `Ferguson_Price__c`
  - `Ferguson_URL__c`
  - `Ferguson_Categories__c`
- [ ] Verify child records created:
  - `Ferguson_Specification__c` records
  - `Ferguson_Document__c` records

#### Debug Log Validation
1. Setup → Debug Logs → New
2. Select your user
3. Set to `FINEST` level
4. Run API lookup
5. Open log and search for:
   ```
   req.setEndpoint('http://cxc-ai.com:8001/
   ```
6. Verify response: `Status=200`

#### Batch Processing Test (Optional)
```apex
// Execute in Developer Console Anonymous Apex
Database.executeBatch(new CxcFergusonBatch(), 1);
```
- [ ] Monitor batch job: Setup → Apex Jobs
- [ ] Verify multiple records updated successfully
- [ ] Check for any errors in logs

---

## 🔍 Troubleshooting

### Issue: "Can't alter metadata in an active org"
**Solution:** You're in a production org. Use Option A (Sandbox deployment)

### Issue: "Unauthorized endpoint"
**Cause:** Remote Site Settings not configured  
**Solution:** 
1. Setup → Remote Site Settings
2. Verify `http://cxc-ai.com` is listed and **Active** is checked
3. If missing, follow Step 6 from deployment instructions

### Issue: "Variant Not Found"
**Cause:** Model number format mismatch (common with Kohler products)  
**Symptoms:** `Fergusion_Search_Result__c` = "Variant Not Found"  
**Solution:** This is a data issue, not a code issue
- Check if model needs K- prefix (e.g., `97621-SHP` → `K-97621-SHP`)
- Ferguson's smart matching on port 8001 helps with this
- Consider future enhancement: Use `/lookup-ferguson-complete` endpoint for automatic smart matching

### Issue: API returns 401 Unauthorized
**Cause:** Invalid API key  
**Solution:** Verify line 324 in code:
```apex
req.setHeader('X-API-KEY','catbot123');
```
Contact API administrator if key has changed

### Issue: Timeout errors
**Current Timeout:** 120 seconds (line 322)  
**Solution:** If frequent timeouts occur:
```apex
req.setTimeout(180000); // Increase to 3 minutes
```

---

## 📊 Monitoring After Deployment

### Week 1 Post-Deployment
- Monitor API callout logs daily
- Track success rate: `Fergusion_Search_Result__c` = "Found"
- Review any error logs in Logger custom object

### Create Dashboard (Optional)
Create a report showing:
1. Total Ferguson API calls
2. Success vs Error breakdown
3. Most common error types
4. Products still failing to match

---

## 🔮 Future Enhancements (Optional)

### Phase 2: Smart Matching Upgrade
The new API (port 8001) offers a superior `/lookup-ferguson-complete` endpoint with:
- 50% fewer API calls (1 instead of 2)
- Automatic K-/G-/M-/A- prefix handling
- Hyphen normalization (G9104BNI → G-9104-BNI)
- Fuzzy partial matching

**Benefits:**
- Reduces API credits from 20 to 10 per lookup
- Higher match rate (98%+)
- Simpler code (eliminate `parseVariant` method)

**Implementation:**
Contact development team for Phase 2 implementation guidance

---

## 📞 Support

### Code Issues
- Check Salesforce Debug Logs for detailed error traces
- Review GitHub repository for updates

### API Issues
- Contact Ferguson API support
- Reference API documentation: `QUICK_REFERENCE.md`

### Salesforce Deployment Issues
- Consult Salesforce Help: https://help.salesforce.com
- Check deployment status: Setup → Deployment Status

---

## ✅ Deployment Completion Checklist

Before marking this migration complete:

- [ ] Code updated in target environment (Sandbox/Production)
- [ ] Remote Site Settings configured for `http://cxc-ai.com`
- [ ] Single product test passed successfully
- [ ] Debug logs confirm port 8001 is being used
- [ ] Batch test completed (optional but recommended)
- [ ] Team notified of deployment
- [ ] Documentation updated (if internal docs exist)
- [ ] Old port 8000 endpoints removed from any documentation

---

## 📝 Rollback Plan

If critical issues arise after deployment:

### Immediate Rollback
1. Open Developer Console
2. Replace with backup code (port 8000 version)
3. Save and test

### Change Set Rollback (Production)
Unfortunately, Salesforce doesn't support automated rollback. You must:
1. Create new Change Set with old code
2. Deploy from Sandbox to Production
3. Estimated rollback time: 15-30 minutes

**Prevention:** Always test in Sandbox first!

---

## 📅 Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-12-07 | Initial migration guide | Ferguson API Team |

---

**Questions?** Refer to `QUICK_REFERENCE.md` for API documentation or contact your development team.
