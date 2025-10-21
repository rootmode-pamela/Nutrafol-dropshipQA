public class ProductRequestQuickActionController {

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
    
    public class formOptions{
        @AuraEnabled
        public String[] states;
        @AuraEnabled
        public map<String,String> trunkStockUsers;
    }
    
    @auraEnabled
    public static trunkStockUser getTrunkStockUser(String userId){
        trunkStockUser u = new trunkStockUser();
        u.recordTypeId = Schema.SObjectType.Product_Request__c.getRecordTypeInfosByDeveloperName().get('Trunk_Stock').getRecordTypeId();    
        u.userContact = [SELECT Id, AccountID, MailingAddress, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingStateCode, MailingCountryCode 
                         FROM Contact 
                         WHERE User_Id__c = :userId AND AccountId = :Constants_ProductRequest.TRUNK_STOCK_ACCOUNT_ID LIMIT 1];
        u.userSubmitsAsOthers = FeatureManagement.checkPermission('SubmitsTrunkStockAsOthers');
        List<Order> userTSOrdersThisMonth = [SELECT Id FROM Order WHERE RecordTypeId = :Constants.ORDER_PRODUCT_REQUEST_RECORDTYPE AND ShipToContactId = :u.UserContact.Id AND EffectiveDate = THIS_MONTH AND Product_Request__r.RecordType.Name = 'Trunk Stock'];
		u.userAllotmentMet = userTSOrdersThisMonth.size() >= Constants_ProductRequest.USER_TRUNK_STOCK_MAX_ORDERS;
        u.trunkStockPeriodCLosed = Date.Today().Day()>= Constants_ProductRequest.TRUNK_STOCK_LAST_DAY;
        if((u.userAllotmentMet || u.trunkStockPeriodClosed) && !u.userSubmitsAsOthers){
            u.hideForm = true;
        } else {
            u.hideForm = false;
        }
        return u;
    }

	@auraEnabled
    public static String saveNewTrunkStock(Product_Request__c newTrunkStock, Boolean saveContactAddress ){
        system.debug(newTrunkStock);
        Contact requester = [SELECT Id, FirstName, LastName, MailingStreet, MailingCity, MailingStateCode, MailingCountry, MailingPostalCode,
                             Trunk_Stock_Pricebook__c
                             FROM Contact WHERE User_Id__c = :newTrunkStock.Requested_By__c 
                                          AND AccountId = :Constants_ProductRequest.TRUNK_STOCK_ACCOUNT_ID LIMIT 1];
        newTrunkStock.Customer_Name__c = requester.Id;
        newTrunkStock.Ship_To_First_Name__c = requester.FirstName;
        newTrunkStock.Ship_To_Last_Name__c = requester.LastName;
        if(requester.Trunk_Stock_Pricebook__c == 'Salon'){
                    newTrunkStock.Pricebook__c = Constants_ProductRequest.TRUNK_STOCK_SALON_PRICEBOOK_ID;
        } else {
                 newTrunkStock.Pricebook__c = Constants_ProductRequest.TRUNK_STOCK_PRICEBOOK_ID;   
        }

        newTrunkStock.Account_Name__c = Constants_ProductRequest.TRUNK_STOCK_ACCOUNT_ID; 
        
        if(saveContactAddress){
            //if anything on the contact address has been changed, set the Contact info and save it
			if(requester.MailingStreet != newTrunkStock.Street__c || requester.MailingCity != newTrunkStock.City__c ||
               requester.MailingStateCode != newTrunkStock.State__c || requester.MailingPostalCode != newTrunkStock.Zip__c){
                   requester.MailingStreet = newTrunkStock.Street__c;
                   requester.MailingCity = newTrunkStock.City__c;
                   requester.MailingStateCode = newTrunkStock.State__c;
                   requester.MailingCountry = newTrunkStock.Country__c;
                   requester.MailingPostalCode = newTrunkStock.Zip__c;
               }            
            
            update requester;
        }
        
        insert newTrunkStock;
        system.debug(newTrunkStock.id);
        return newTrunkStock.Id;
        
    }
    
    @auraEnabled
    public static Map<String,String> trunkStockUsers(){
        Map<String,String> trunkStockUsers = new Map<String,String>();
        For(Contact c: [SELECT Id, FirstName, LastName, User_Id__c FROM Contact WHERE AccountId = :Constants_ProductRequest.TRUNK_STOCK_ACCOUNT_ID AND Trunk_Stock_Requester__c = true AND User_Id__c !=null]){
           trunkStockUsers.put(c.User_Id__c, c.FirstName + ' ' + c.LastName); 
        }
        system.debug(trunkStockUsers);
        return trunkStockUsers;
    }
    
    @auraEnabled
    public static Contact getUserContactInfo(String contactUserId){
        return [SELECT Id, AccountID, MailingAddress, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingStateCode, MailingCountryCode 
                         FROM Contact 
                         WHERE User_Id__c = :contactUserId AND AccountId = :Constants_ProductRequest.TRUNK_STOCK_ACCOUNT_ID LIMIT 1];
        
    }
    
    @auraEnabled
    public static formOptions getFormOptions(){
        formOptions o = new formOptions();
        List<String> states = new List<String>();
        o.trunkStockUsers = trunkStockUsers();
        Schema.DescribeFieldResult objFieldDescribe = Contact.MailingStateCode.getDescribe();
		List<Schema.PicklistEntry> lstPickListValues = objFieldDescribe.getPickListValues();
		for (Schema.PicklistEntry objPickList : lstPickListValues) {
    		states.add( objPickList.getValue());
		}
        o.states = states;
        return o;
        
    }
    
    @auraEnabled
    public static Map<String,String> stateList(){
        Map<String,String> states = new Map<String,String>();
        
        return states;
    }
}