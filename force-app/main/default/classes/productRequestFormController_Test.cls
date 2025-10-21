@isTest
public class productRequestFormController_Test {

    	
    @testSetup
    public static void testData(){
        
        TestDataFactory.productRequestUserSetup();
        
        Account emp = [SELECT Id FROM Account WHERE Name = 'Nutrafol EMPLOYEE'];
        system.debug('EMployee Account: ' + emp);
        Contact con = [SELECT id, User_Id__c FROM Contact WHERE AccountId = :emp.id];
        Pricebook2 pb = [SELECT id FROM Pricebook2 WHERE Name = 'Trunk Stock'];
        
        RecordType Rec = [select id,Name from RecordType where Name = 'Trunk Stock'];
        Product_Request__C PR = new Product_Request__c();
        PR.RecordTypeId = Rec.Id;
        PR.Customer_Name__c = con.Id;
        PR.Requested_By__c = con.User_Id__c;
        PR.Account_Name__c = emp.Id;
        PR.Pricebook__c = pb.Id;
        insert PR;
    }
    
    @isTest
    public static void testAll(){
        
        User u = [SELECT Id FROM USer WHERE Alias = 'bdm'];
        
		Product_Request__c pr = [SELECT Id, Pricebook__c, Pricebook__r.Name FROM Product_Request__c];
        system.debug(pr.Id);
        Pricebook2 p1 = [SELECT Id FROM Pricebook2 WHERE Id = :pr.Pricebook__c LIMIT 1];
        system.debug(p1);
        Pricebook2 p = productRequestFormController.getPricebook(pr.Id);
        System.assertEquals(p.Id, pr.Pricebook__c);
        
    //    System.runAs(u){
        
        List<productCategoryData> pcd = productRequestFormController.getOrderFormProductsForProductRequest(pr.Id);
		        
        pcd[1].products[0].quantity = 60;
        productRequestFormController.submitProductRequestOrderForm(p.Name, pr.Id, pcd, 'true');
        productRequestFormController.getTrunkStockUser(u.id, pr.id);
		productRequestFormController.getProductRequestFormProducts(pr.id);
        }
 //   }
    
}