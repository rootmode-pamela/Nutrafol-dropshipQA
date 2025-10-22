//Constants Class for Product Request Business Logic - Pricebooks, RecordTypes, Statuses, Default Accounts
//
//Note for functionality & Testing:  Accounts and Pricebooks must match values.  Update Apex class for TestDataFactory if changed.

public class Constants_ProductRequest {

	//Trunk Stock Product Requests
    public static final integer USER_TRUNK_STOCK_MAX_ORDERS = 1;
    //public static List<Account> Aas = [SELECT Id, Name FROM Account];
    public static final String TRUNK_STOCK_ACCOUNT_ID = getAccountId('NUTRAFOL Employee'); 
    public static final String TRUNK_STOCK_PRICEBOOK_ID = getPriceBookId('Trunk Stock');  
    public static final String TRUNK_STOCK_SALON_PRICEBOOK_ID = getPriceBookId('Trunk Stock Salon');  
    public static final Boolean TRUNK_STOCK_NEEDS_APPROVAL = true;
    public static final Boolean TRUNK_STOCK_MANAGER_APPROVAL = false;
    public static final String TRUNK_STOCK_APPROVER_ID = [SELECT Id FROM USER WHERE Username LIKE 'shayna@nutrafol.com%'].Id;
    public static final String TRUNK_STOCK_APPROVAL_STATUS_ONSUBMIT = 'Submitted for Approval';
    public static final Integer TRUNK_STOCK_LAST_DAY = 32;
    
    //Drop Ship Product Requests
    public static final String DROP_SHIP_PRICEBOOK_MD_ID = getPriceBookId('Trunk Stock');  
    public static final String DROP_SHIP_PRICEBOOK_SALON_ID = getPriceBookId('Trunk Stock Salon');  
    public static final Boolean DROP_SHIP_NEEDS_APPROVAL = true;
    public static final String DROP_SHIP_APPROVAL_STATUS_ONSUBMIT = 'Requested Approval Process';
    public static final String DROP_SHIP_APPROVER_ID = [SELECT Id FROM USER WHERE Username LIKE 'shayna@nutrafol.com%'].Id;
    
    //Admin Event Product Requests

    public static final String EVENT_ACCOUNT_ID = getAccountId('Nutrafol Events');
    public static final String EVENT_PRICEBOOK_ID = getPriceBookId('Admin Event');  
    public static final String EVENT_APPROVAL_STATUS_ONSUBMIT = 'Approved';  
    public static final Boolean EVENT_NEEDS_APPROVAL = false;
    public static final String EVENT_APPROVER_ID = '';

    
    
    public static string getPriceBookId(String name){
        if(!Test.isRunningTest()){
            return [SELECT Id FROM Pricebook2 WHERE Name = :name].Id ;
        } else {
            return Test.getStandardPricebookId();
        }    
    }
    
    public static String getAccountId(String name){
       return [SELECT Id From Account WHERE Name = :name].Id; 
    }
    
}