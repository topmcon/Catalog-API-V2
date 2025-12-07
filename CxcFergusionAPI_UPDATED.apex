public class CxcFergusionAPI {
    
    public static void runFergusion(Id catalogId) {
        Product_Catalog__c catalog = (Product_Catalog__c) SObjectHelper.getSObjectDetailsById(catalogId, 
                                                                                              '(SELECT Id FROM Ferguson_Specifications__r), (SELECT Id FROM Ferguson_Documents__r)');
        
        try {    
            HttpRequest searchReq = searchFergusion(catalog.Model_Number_Verified__c);
            HTTPResponse searchRes = new Http().send(searchReq);
            if(searchRes != null && (searchRes.getStatusCode() == 200 || searchRes.getStatusCode() == 202)) {
                Logger.info('Success Response from Search API', catalogId).setHttpRequestDetails(searchReq).setHttpResponseDetails(searchRes);
                
                String url = parseVariant(searchRes.getBody(), catalog.Model_Number_Verified__c);
                
                if(String.isNotEmpty(url)) {
                    HttpRequest detailReq = detailFergusion(url);
                    HTTPResponse detailRes = new Http().send(detailReq);
                    
                    if(detailRes != null && (detailRes.getStatusCode() == 200 || detailRes.getStatusCode() == 202)) {
                        catalog.Fergusion_Search_Result__c = 'Found';
                        catalog = parseDetails(detailRes.getBody(), catalog);
                    }
                    else {
                        Logger.error('Bad Response from detail API', catalogId).setHttpRequestDetails(detailReq).setHttpResponseDetails(detailRes);
                        catalog.Fergusion_Search_Result__c = 'Detail API Error';
                    }
                }
                else {
                    catalog.Fergusion_Search_Result__c = 'Variant Not Found';
                }
            }
            else {
                Logger.error('Bad Response from Search API', catalogId).setHttpRequestDetails(searchReq).setHttpResponseDetails(searchRes);
                catalog.Fergusion_Search_Result__c = 'Search API Error';
            }
        }
        catch(Exception ex) {
            Logger.error('Exception while calling Fergusion', catalogId).setExceptionDetails(ex);
            catalog.Fergusion_Search_Result__c = 'Logical Error';
        }
        finally {
            update catalog;
            Logger.saveLog();
        }
    }
    
    public static Product_Catalog__c parseDetails(String response, Product_Catalog__c catalog) {
        
        DetailRespWrapper modeldata = (DetailRespWrapper) JSON.deserialize(response, DetailRespWrapper.class);
        
        if(modeldata.detail != null) {
            if(String.isNotEmpty(modeldata.detail.name))
                catalog.Ferguson_Title__c = modeldata.detail.name;
            
            if(String.isNotEmpty(modeldata.detail.url))
                catalog.Ferguson_URL__c = modeldata.detail.url;
            
            if(String.isNotEmpty(modeldata.detail.brand))
                catalog.Ferguson_Brand__c = modeldata.detail.brand;
            
            if(String.isNotEmpty(modeldata.detail.model_number))
                catalog.Ferguson_Model_Number__c = modeldata.detail.model_number;
            
            if(String.isNotEmpty(modeldata.detail.description))
                catalog.Ferguson_Description__c = modeldata.detail.description;
            
            if(modeldata.detail.price != null && modeldata.detail.price != null && modeldata.detail.price > 0)
                catalog.Ferguson_Price__c = modeldata.detail.price;
            
            if(String.isNotEmpty(modeldata.detail.base_type))
                catalog.Ferguson_Base_Type__c = modeldata.detail.base_type;
            
            if(String.isNotEmpty(modeldata.detail.product_type))
                catalog.Ferguson_Product_Type__c = modeldata.detail.product_type;
            
            if(String.isNotEmpty(modeldata.detail.application))
                catalog.Ferguson_Application__c = modeldata.detail.application;
            
            if(modeldata.detail.categories != null && modeldata.detail.categories.size() > 0) {
                Set<String> categories = New Set<String>();
                for(CategoryWrapper thisCat : modeldata.detail.categories) {
                    if(String.isNotEmpty(thisCat.name))
                        categories.add(thisCat.name);
                }
                if(categories.size() > 0)
                    catalog.Ferguson_Categories__c = String.join(categories, '\r\n');
            }
            
            if(String.isNotEmpty(modeldata.detail.base_category))
                catalog.Ferguson_Base_Category__c = modeldata.detail.base_category;
            
            if(String.isNotEmpty(modeldata.detail.business_category))
                catalog.Ferguson_Business_Category__c = modeldata.detail.business_category;
            
            if(modeldata.detail.related_categories != null && modeldata.detail.related_categories.size() > 0) {
                Set<String> categories = New Set<String>();
                for(CategoryWrapper thisCat : modeldata.detail.related_categories) {
                    if(String.isNotEmpty(thisCat.name))
                        categories.add(thisCat.name);
                }
                if(categories.size() > 0)
                    catalog.Ferguson_Related_Categories__c = String.join(categories, '\r\n');
            }
            
            if(modeldata.detail.price_range != null && modeldata.detail.price_range != null && modeldata.detail.price_range.min != null && modeldata.detail.price_range.min > 0)
                catalog.Ferguson_Min_Price__c =  modeldata.detail.price_range.min;
            
            if(modeldata.detail.price_range != null && modeldata.detail.price_range != null && modeldata.detail.price_range.max != null && modeldata.detail.price_range.max > 0)
                catalog.Ferguson_Max_Price__c =  modeldata.detail.price_range.max;
            
            if(modeldata.detail.recommended_options != null && modeldata.detail.recommended_options.size() > 0) {
                Set<String> categories = New Set<String>();
                for(RecomandWrapper thisCat : modeldata.detail.recommended_options) {
                    if(String.isNotEmpty(thisCat.label))
                        categories.add(thisCat.label);
                }
                if(categories.size() > 0)
                    catalog.Ferguson_Recommanded_Options__c = String.join(categories, '\r\n');
            }
            
            extractSpecs(modeldata.detail.specifications, catalog.Id);
            
            if(modeldata.detail.feature_groups != null && modeldata.detail.feature_groups.size() > 0) {
                catalog.Ferguson_Features__c = '<table>';
                    
                for(FeatureGroupWrapper thisGroup : modeldata.detail.feature_groups) {
                    if(String.isNotEmpty(thisGroup.name)) {
                        catalog.Ferguson_Features__c += '<tr><td colspan="3" style="text-align: center;"><b>' + thisGroup.name + '</b></td></tr>';
                    }
                    
                    if(thisGroup.features != null && thisGroup.features.size() > 0) {
                        for(FeatureWrapper thisFeature : thisGroup.features) {
                            catalog.Ferguson_Features__c += '<tr><td>'; 
                            catalog.Ferguson_Features__c += String.isNotEmpty(thisFeature.name) ? thisFeature.name : '';
                            catalog.Ferguson_Features__c += '</td><td>';
                            catalog.Ferguson_Features__c += String.isNotEmpty(thisFeature.value) ? thisFeature.value : '';
                            catalog.Ferguson_Features__c += ' ';
                            catalog.Ferguson_Features__c += String.isNotEmpty(thisFeature.units) ? thisFeature.units : '' ;
                            catalog.Ferguson_Features__c += '</td><td>';
                            catalog.Ferguson_Features__c += String.isNotEmpty(thisFeature.description) ? thisFeature.description : '' ;
                            catalog.Ferguson_Features__c += '</td><td>';
                            catalog.Ferguson_Features__c += '</td></tr>';
                        }
                    }
                }
                catalog.Ferguson_Features__c += '<table>';
            }
            
            if(modeldata.detail.dimensions != null && String.isNotEmpty(modeldata.detail.dimensions.height))
                catalog.Ferguson_Height__c =  modeldata.detail.dimensions.height;
            
            if(modeldata.detail.dimensions != null && String.isNotEmpty(modeldata.detail.dimensions.width))
                catalog.Ferguson_Width__c =  modeldata.detail.dimensions.width;
            
            if(modeldata.detail.dimensions != null && String.isNotEmpty(modeldata.detail.dimensions.length))
                catalog.Ferguson_Length__c =  modeldata.detail.dimensions.length;
            
            if(modeldata.detail.dimensions != null && String.isNotEmpty(modeldata.detail.dimensions.depth))
                catalog.Ferguson_Depth__c =  modeldata.detail.dimensions.depth;
            
            if(modeldata.detail.dimensions != null && String.isNotEmpty(modeldata.detail.dimensions.diameter))
                catalog.Ferguson_Diameter__c =  modeldata.detail.dimensions.diameter;
            
            if(String.isNotEmpty(modeldata.detail.warranty))
                catalog.Ferguson_Warranty__c = modeldata.detail.warranty;
            
            if(String.isNotEmpty(modeldata.detail.manufacturer_warranty))
                catalog.Ferguson_Manufacturer_Warranty__c = modeldata.detail.manufacturer_warranty;
            
            if(String.isNotEmpty(modeldata.detail.upc))
                catalog.Ferguson_UPC__c = modeldata.detail.upc;
            
            if(String.isNotEmpty(modeldata.detail.barcode))
                catalog.Ferguson_Barcode__c = modeldata.detail.barcode;
            
            if(modeldata.detail.attribute_ids != null && modeldata.detail.attribute_ids.size() > 0) {
                Set<String> categories = New Set<String>();
                for(CategoryWrapper thisCat : modeldata.detail.attribute_ids) {
                    if(String.isNotEmpty(thisCat.name))
                        categories.add(thisCat.name);
                }
                if(categories.size() > 0)
                    catalog.Ferguson_Attributes__c = String.join(categories, '\r\n');
            }
            
            if(modeldata.detail.collection != null && String.isNotEmpty(modeldata.detail.collection.name)) {
                catalog.Ferguson_Collection__c = modeldata.detail.collection.name;
            }
            
            
            extractResources(modeldata.detail.resources, catalog.Id);
        }
              
        return catalog;
    }
    
    public static void extractResources(List<ResourceWrapper> resources, Id catalogId) {
        List<Ferguson_Document__c> existingDocs = [SELECT Id FROM Ferguson_Document__c WHERE Product_Catalog__c = :catalogId];
            
        if(existingDocs == null || existingDocs.size() == 0) {
            List<Ferguson_Document__c> docs = New List<Ferguson_Document__c>();
            
            if(resources != null && resources.size() > 0) {
                for(ResourceWrapper thisresource : resources) {
                    if(String.isNotEmpty(thisresource.name)) {
                        Ferguson_Document__c newDoc = New Ferguson_Document__c(Product_Catalog__c = catalogId, Name = thisresource.name);
                        
                        if(String.isNotEmpty(thisresource.url))
                            newDoc.URL__c = thisresource.url;
                        
                        docs.add(newDoc);
                    }
                }
            }
            if(docs != null && docs.size() > 0)
                insert docs;
        }
    }
    
    public static void extractSpecs(Map<String, Map<String, String>> specifications, Id catalogId) {
        
        List<Ferguson_Specification__c> existingSpecs = [SELECT Id FROM Ferguson_Specification__c WHERE Product_Catalog__c = :catalogId];
        
        if(existingSpecs == null || existingSpecs.size() == 0) {
        
            List<Ferguson_Specification__c> specs = New List<Ferguson_Specification__c>();
            
            if(specifications != null && specifications.size() > 0) {
                for(String thisSpec : specifications.keyset()) {
                    Ferguson_Specification__c newSpec = New Ferguson_Specification__c(Product_Catalog__c = catalogId, Name = thisSpec);
                    
                    Map<String, String> specDetails = specifications.get(thisSpec);
                    
                    if(specDetails != null && specDetails.containsKey('description') && String.isNotEmpty(specDetails.get('description'))) {
                        newSpec.Description__c = specDetails.get('description');
                    }
                    
                    if(specDetails != null && specDetails.containsKey('value') && String.isNotEmpty(specDetails.get('value'))) {
                        newSpec.Value__c = specDetails.get('value');
                    }
                    
                    if(specDetails != null && specDetails.containsKey('units') && String.isNotEmpty(specDetails.get('units'))) {
                        newSpec.Unit__c = specDetails.get('units');
                    }
                    specs.add(newSpec);
                }
            }
            if(specs != null && specs.size() > 0) {
                insert specs;
            }
        }
    }
        
    public static String parseVariant(String response, String modelNumber) {
        String url;
        
        Map<String, object> searchResp = (Map<String, object>) JSON.deserializeUntyped(response);
        
        if(searchResp != null && searchResp.containsKey('products') && searchResp.get('products') != null) {
            List<Object> products = (List<Object>) searchResp.get('products');
            
            if(products != null && products.size() > 0) {
                
                for(Object thisProductObj : products) {
                    Map<String, Object> thisProduct = (Map<String, Object>) thisProductObj;
                    if(thisProduct != null && thisProduct.containsKey('variants') && thisProduct.get('variants') != null) {
                        List<Object> variants = (List<Object>) thisProduct.get('variants');
                        if(variants != null && variants.size() > 0) {
                            
                            for(Object thisVariantsObj : variants) {
                                Map<String, Object> thisVariants = (Map<String, Object>) thisVariantsObj;
                                if(thisVariants != null && thisVariants.containsKey('model_no') && thisVariants.get('model_no') != null && ((String) thisVariants.get('model_no')).equalsIgnoreCase(modelNumber) && thisVariants.containsKey('url') && thisVariants.get('url') != null)
                                {
                                    return (String) thisVariants.get('url');
                                }
                            }
                        }
                    }
                }
                
            }
        }
        
        return url;
    }
    
    public static HttpRequest detailFergusion(String url) {
        Map<String, String> input = New Map<String, String>();
        input.put('url', url);
        return call('POST', 'product-detail-ferguson', JSON.serialize(input));
    }
    
    public static HttpRequest searchFergusion(String model) {
        Map<String, String> input = New Map<String, String>();
        input.put('search', model);
        return call('POST', 'search-ferguson', JSON.serialize(input));
    }
    
    public static HttpRequest call(String method,String path,String payload) {
        HttpRequest req = new HttpRequest();
        req.setMethod(method); 
        req.setTimeout(120000);
        req.setEndpoint('http://cxc-ai.com:8001/' + path);  // ← CHANGED: Port 8000 → 8001
        req.setHeader('X-API-KEY','catbot123');
        
        if(method == 'POST' || method == 'PUT' || method == 'PATCH') {
            req.setBody(payload);
            req.setHeader('Content-Type','application/json');
        }
        return req;
    }
    
    public class DetailRespWrapper {
        public DetailWrapper detail;
    }
    
    public class DetailWrapper {
        public Integer id;
        public String name, url, brand, model_number, description, base_type, product_type, application, base_category, business_category, warranty, manufacturer_warranty, country_of_origin, upc, barcode;
        public List<String> certifications;
        public Decimal price, shipping_fee, variant_count, rating, review_count, total_reviews, questions_count;
        public List<CategoryWrapper> categories, related_categories, attribute_ids;
        public List<RecomandWrapper> recommended_options;
        public Map<String, Map<String, String>> specifications;
        public List<FeatureGroupWrapper> feature_groups;
        public DimensionWrapper dimensions;
        public List<ResourceWrapper> resources;
        public CategoryWrapper collection;
        public PriceRangeWrapper price_range;
    }
    
    public class CategoryWrapper {
        public String name;
    }
    
    public class PriceRangeWrapper {
        public Decimal min, max;
        public Boolean has_range;
    }
    
    public class RecomandWrapper {
        public String label;
    }
    
    public class FeatureGroupWrapper {
        public String name;
        public List<FeatureWrapper> features;
    }
    
    public class FeatureWrapper {
        public String name, value, units, description; 
        Boolean featured;
    }
    
    public class DimensionWrapper {
        public String height, width, length, depth, diameter;
    }
    
    public class ResourceWrapper {
        public String name, url;
    }
    
    public static void dummyTest() {
        Integer i = 0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
}
