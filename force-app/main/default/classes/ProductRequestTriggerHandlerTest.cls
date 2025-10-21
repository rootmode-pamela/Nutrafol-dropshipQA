@isTest
private class ProductRequestTriggerHandlerTest {
    
    @testSetup static void setupData() {
        TestDataFactory.ProductRequestUserSetup();
        
        Account acc = UtilityClass_AC.AccountRec();
        Contact con = UtilityClass_AC.ContactRec(acc.Id);
        User u = [SELECT Id, ManagerId from User WHERE Alias = 'bdm'];
        
        
        RecordType Rec = [select id,Name from RecordType where Name = 'Drop Ship'];
        Product_Request__c PR = new Product_Request__c();
        PR.RecordTypeId = Rec.Id;
        PR.Requested_By__c = u.Id;
        PR.Customer_Name__c = con.Id;
        PR.Account_Name__c = acc.Id;
        Pr.Request_Approval_From__c = u.ManagerId;
        pR.Pricebook__c = [SELECT Id FROM Pricebook2 LIMIT 1].Id;
        insert PR;
        
        String productid = [SELECT Product2id FROM PricebookEntry WHERE Pricebook2Id = :pr.Pricebook__c LIMIT 1].Product2Id;
     
        Product_Request_Line_Item__c PRLineItem = UtilityClass_AC.ProductRequestLineItemRec(PR.Id, productid);
    }
    
    @isTest
    public static void updateProductRequestSubmitForApproval(){
        Product_Request__c PR = [SELECT Id, Approval_Status__c FROM Product_Request__c LIMIT 1];        
        PR.Approval_Status__c = 'Requested Approval Process';
        update PR;       
        

 
        Product_Request__c PR2 = [SELECT Id, Approval_Status__c FROM Product_Request__c WHERE Id = :PR.Id];        
        PR.Approval_Status__c = 'Approved';
        update PR;       
        System.assertEquals(PR.Approval_Status__c, 'Approved');

	}

}