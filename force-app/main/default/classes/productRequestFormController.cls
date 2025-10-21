public class productRequestFormController {

    @AuraEnabled
    public list<productCategoryData> productRequestFormProducts {get; set;}
    
    //get products for order form
    @AuraEnabled
    public static List<productCategoryData> getProductRequestFormProducts(String productREquestId){
        return productRequestFormController.getOrderFormProductsForProductRequest(productRequestId);
        
    }
    
	//get products for product request order form
    @AuraEnabled
    public static List<productCategoryData> getOrderFormProductsForProductRequest(String productRequestId){
        Product_Request__c r = [SELECT Id, Pricebook__c FROM Product_Request__c WHERE Id = :productRequestId];
        String pricebookId = r.Pricebook__c;
        
        Map<String, Product_Request_Line_Item__c> rliProdMap = new Map<String, Product_Request_Line_Item__c>();
        for(Product_Request_Line_Item__c rli:[SELECT Id, Product__c, Product_Description__c, Quantity__c FROM Product_Request_Line_Item__c WHERE Product_Request__c = :productRequestId]){
            rliProdMap.put(rli.Product__c, rli);
        }
        
        system.debug('fetching ' + pricebookId);
        List<productCategoryData> pcd = new List<productCategoryData>();

        Map<String, List<productCategoryData.product>> productMap = new map<String, List<productCategoryData.product>>();
        Map<String, Integer> categoryMap = new map<String, Integer>();
        Map<String, Integer> tabQuantityMap = new Map<String, Integer>();
        
        For(Order_Form_Category__c pc: [SELECT Id, Name, Case_Quantity__c FROM Order_Form_Category__c]){
            categoryMap.put(pc.Name, integer.valueOf(pc.Case_Quantity__c));
            tabQuantityMap.put(pc.Name, 0);
        }
        
        List<PricebookEntry> pbes = [SELECT Id, Product2Id, Product2.Name, Product2.Description, UnitPrice, Max_Quantity__c, Product2.Order_Form_Category__r.Name 
                                    FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2.Shipping_Product__c = false AND IsActive = true AND Product2.Exclude_From_Order_Form__c != true Order By Product2.Order_Form_Category__r.Sequence_Number__c];
        system.debug(pbes);
        
        for(PricebookEntry pbe: pbes){
            List<productCategoryData.product> prods = new List<productCategoryData.product>();
            String tab = pbe.Product2.Order_Form_Category__r.Name;
            if(productMap.containsKey(tab)){
                prods  = productMap.get(tab);
            }

            productCategoryData.product p = new productCategoryData.product();
            	p.pricebookEntryId = pbe.id;
            	p.product2Id = pbe.product2Id;
                p.sku = pbe.product2.Name;
                p.description = pbe.Product2.Description;
                p.price = pbe.UnitPrice;
            	p.maxQuantity = Integer.valueOf(pbe.Max_Quantity__c);
            
            if(rliProdMap.containsKey(pbe.product2Id)){
            Product_Request_Line_Item__c rli = rliProdMap.get(pbe.product2Id);            
            	p.quantity = integer.ValueOf(rli.quantity__c);
                p.productRequestLineItemId = rli.Id;
                Integer tabQuantity = tabQuantityMap.get(tab);
                tabQuantityMap.put(tab, tabQuantity + p.quantity);
            }
            prods.add(p);
            productMap.put(tab, prods);
        }
		
        for(String tab: productMap.keySet()){
            productCategoryData data = new productCategoryData(tab, categoryMap.get(tab), tabQuantityMap.get(tab), productMap.get(tab));
            pcd.add(data);
        }
        
        system.debug(pcd);
        
        return pcd;
        
    }

    
    @AuraEnabled
    public static Pricebook2 getPricebook (String productRequestId){
        String pricebookId = [SELECT Id, Pricebook__c FROM Product_Request__c WHERE Id = :productRequestId LIMIT 1].pricebook__c;
        Pricebook2 pb = [SELECT Id, Name FROM Pricebook2 WHERE Id = :pricebookId LIMIT 1];
        return pb;
        
    }
    
        public class trunkStockUser{
        @AuraEnabled
    	public String recordTypeId;
        @AuraEnabled
    	public Boolean userSubmitsAsOthers;
        @AuraEnabled
        public Boolean hideForm;
        @AuraEnabled
        public Boolean userAllotmentMet;
        @AuraEnabled
        public Boolean trunkStockPeriodClosed;
        @AuraEnabled
        public Contact userContact;
    }
    
    @auraEnabled
    public static trunkStockUser getTrunkStockUser(String userId, String recordId){
        trunkStockUser u = new trunkStockUser();
        u.userContact = [SELECT Id, AccountID, MailingAddress, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingStateCode, MailingCountryCode 
                         FROM Contact 
                         WHERE User_Id__c = :userId AND AccountId = :Constants_ProductRequest.TRUNK_STOCK_ACCOUNT_ID LIMIT 1];
		Product_Request__c req = [SELECT Id, RecordTypeId FROM Product_Request__c WHERE id = :recordId LIMIT 1];
        String TrunkStockRT = Schema.SObjectType.Product_Request__c.getRecordTypeInfosByDeveloperName().get('Trunk_Stock').getRecordTypeId(); 
        if(req.RecordTypeId == TrunkStockRT){
	        u.userSubmitsAsOthers = FeatureManagement.checkPermission('SubmitsTrunkStockAsOthers');
	        List<Order> userTSOrdersThisMonth = [SELECT Id FROM Order WHERE RecordTypeId = :Constants.ORDER_PRODUCT_REQUEST_RECORDTYPE AND ShipToContactId = :u.UserContact.Id AND EffectiveDate = THIS_MONTH AND Product_Request__r.RecordType.Name = 'Trunk Stock'];
			u.userAllotmentMet = userTSOrdersThisMonth.size() >= Constants_ProductRequest.USER_TRUNK_STOCK_MAX_ORDERS;
	        u.trunkStockPeriodCLosed = Date.Today().Day()>= Constants_ProductRequest.TRUNK_STOCK_LAST_DAY;
	        if((u.userAllotmentMet || u.trunkStockPeriodClosed) && !u.userSubmitsAsOthers){
    	        u.hideForm = true;
        	} else {
            	u.hideForm = false;
        	}
        } else {
            u.hideform = false;
            u.userAllotmentMet = false;
            u.trunkStockPeriodClosed = false;
        }
        
        return u;
    }

    @AuraEnabled
    public static void submitProductRequestOrderForm (String pricebookName, String productRequestId, List<productCategoryData> orderFormProductCategoryData, String submitForApproval){
        //get existing line items for update/comparison
        system.debug(submitForApproval);
        List<Product_Request_Line_Item__c> existingRLIs = [SELECT Id, product__c FROM Product_request_Line_Item__c WHERE Product_Request__c = :productRequestId];
        List<Product_Request_Line_Item__c> rlisToRemove = new List<Product_Request_Line_Item__c>();
        map<String, Product_Request_Line_Item__c> prodRlisAdding = new map<String, Product_Request_Line_Item__c>();
        
        String PricebookId = [SELECT Id FROM Pricebook2 WHERE Name = :pricebookName].Id;
        Product_Request__c r = [SELECT Id, Approval_Status__c, Is_Approved__c, Request_Approval_From__c, RecordType.Name, RecordTypeId FROM Product_Request__c WHERE Id = :productRequestId];
        List<Product_Request_Line_Item__c> rlis = new List<Product_Request_Line_Item__c>();
        for(productCategoryData pcd: orderFormProductCategoryData){
            for(productCategoryData.product p: pcd.products){
                if (p.quantity>0){
                    Product_Request_Line_Item__c rli = new Product_Request_Line_Item__c(
                        Id = p.productRequestLineItemId,
                        Product_Request__c = r.Id,
                        Product__c = p.product2Id,
                        Quantity__c = p.quantity
                    );
                    rlis.add(rli);
                    prodRlisAdding.put(p.product2Id, Rli);
                }
            }
        }
        
        //check all existing Line Items to be sure they're accounted for, or remove any no longer used
        if(existingRLIs.size()>0){
            for(Product_Request_Line_Item__c existing: existingRLIs){
                if(prodRlisAdding.size()>0 && !prodRlisAdding.containsKey(existing.Product__c)){
                    rlisToRemove.add(existing);
                }
            }    
        }
        
        
        if(rlisToRemove.size()>0){
        	delete rlisToRemove;    
        }
        
        system.debug(rlis);
        if(rlis.size()>0){
        	upsert rlis;    
        }
        
        Boolean needsApproval = true;
        if(r.RecordTypeId == Schema.SObjectType.Product_Request__c.getRecordTypeInfosByName().get('Trunk Stock').getRecordTypeId()){
               needsApproval = Constants_ProductRequest.TRUNK_STOCK_NEEDS_APPROVAL;
               r.Approval_Status__c = COnstants_ProductRequest.TRUNK_STOCK_APPROVAL_STATUS_ONSUBMIT;
               r.Is_Approved__c = !needsApproval;
            if(needsApproval && Constants_ProductRequest.TRUNK_STOCK_MANAGER_APPROVAL){
                r.Request_Approval_From__c = [SELECT Id, ManagerId FROM User WHERE Id = :r.Requested_By__c].ManagerId;
            } else if(needsApproval) {
                r.Request_Approval_From__c =  Constants_ProductRequest.TRUNK_STOCK_APPROVER_ID;
            }
       } else if (r.RecordTypeId == Schema.SObjectType.Product_Request__c.getRecordTypeInfosByName().get('Event Request').getRecordTypeId()){
               needsApproval = Constants_ProductRequest.EVENT_NEEDS_APPROVAL;
               r.Approval_Status__c = Constants_ProductRequest.EVENT_APPROVAL_STATUS_ONSUBMIT;
               if(needsApproval){
                   r.Request_Approval_From__c = Constants_ProductRequest.EVENT_APPROVER_ID;
               }
        } else if (r.RecordTypeId == Schema.SObjectType.Product_Request__c.getRecordTypeINfosByName().get('Drop Ship').getRecordTypeId()){
           needsApproval = Constants_ProductRequest.DROP_SHIP_NEEDS_APPROVAL;
           r.Approval_Status__c = Constants_ProductRequest.DROP_SHIP_APPROVAL_STATUS_ONSUBMIT;
           if(needsApproval){
              r.Request_Approval_From__c = Constants_ProductRequest.DROP_SHIP_APPROVER_ID;
           }
              
        }
        

        if(!needsApproval){
            r.Is_Approved__c = true;
        }
        
    	update r;
    }    
    
    
}