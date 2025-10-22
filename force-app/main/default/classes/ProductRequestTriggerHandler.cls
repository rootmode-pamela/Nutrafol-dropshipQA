public class ProductRequestTriggerHandler {
    
    public void beforeInsert(List<Product_Request__c> productRequestList){
        Set<Id> contactIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        //Orders need to have a ShipToContact for all.  For Trunk Stock Product Requests this is the Requested By Contact on 
        //the dummy Nutrafol EMPLOYEES Account.  For Event Forms filled out on the Admin Event Form, search the Nutrafol Events Account 
        //for a Contact matching Name and Email, and create one if it doesn't exist.
        //If the Requested By Email is blank, fill that in from either the Customer or Requested by
        
        
        //Set defaults for Event Request
        Id eventRt = Schema.SObjectType.Product_Request__c.getRecordTypeInfosByName().get('Event Request').getRecordTypeId();
        
        //create maps for use in approval processing (admin event forms are pre-approved)
        for(Product_Request__c prodReq : productRequestList){
            system.debug(prodReq.RecordTypeId);
            
            //Event PRs are started as Drop Ship orders on the Event Account, so set the Pricebook and RT if the Account is the Event Account
            if(prodReq.Account_Name__c == Constants_ProductRequest.EVENT_ACCOUNT_ID){
                prodReq.RecordTypeId = eventRt;
                prodReq.Pricebook__c = Constants_ProductRequest.EVENT_PRICEBOOK_ID;
            }
            
			//Drop Ship Defaults
            if (prodReq.RecordTypeId == Schema.SObjectType.Product_Request__c.getRecordTypeInfosByName().get('Drop Ship').getRecordTypeId()){
            	Account a = [SELECT Id, Partner_Type__c FROM Account WHERE Id = :prodReq.Account_Name__c LIMIT 1];
                prodReq.Approval_Status__c = 'New';
                if(a.Partner_Type__c == 'Salon'){
                        prodReq.Pricebook__c = Constants_ProductRequest.DROP_SHIP_PRICEBOOK_SALON_ID;                  
                } else {
                        prodReq.Pricebook__c = Constants_ProductREquest.DROP_SHIP_PRICEBOOK_MD_ID;
                    }
                }
            
            if(prodReq.Requested_By__c != null && prodReq.Requestor_Email__c == null){
            	userIds.add(prodReq.Requested_By__c);
            }
            
            if(prodReq.Customer_Name__c != null){
            	contactIds.add(prodReq.Customer_Name__c);
            }
        }
        
        Map<Id, User> userMap = new Map<Id, User>([Select Id, Email from User Where Id IN: userIds]);
        Map<Id, Contact> contactMap = new Map<Id, Contact>([Select Id, Email, FirstName, LastName from Contact Where Id IN: contactIds]);
            
		for(Product_Request__c prodReq : productRequestList){
            //add missing emails and submit for approval
            
            if(prodReq.Requestor_Email__c == null){
            	if(prodReq.Requested_By__c != null){
            		if(userMap.get(prodReq.Requested_By__c) != null){
            	        	prodReq.Requestor_Email__c = userMap.get(prodReq.Requested_By__c).Email;      
            	    }
            	}
            	else if(prodReq.Customer_Name__c != null){
            		if(contactMap.get(prodReq.Customer_Name__c) != null){
            	    	prodReq.Requestor_Email__c = contactMap.get(prodReq.Customer_Name__c).Email;      
            	    }
            	}
        	}
            
            if(prodReq.Ship_To_Last_Name__c == null || prodReq.Ship_To_First_Name__c == null){
                if(contactMap.containsKey(prodReq.Customer_Name__c)){
                    prodReq.Ship_To_First_Name__c = contactMap.get(prodReq.Customer_Name__c).FirstName;
                    prodReq.Ship_To_Last_Name__c = contactMap.get(prodReq.Customer_Name__c).LastName;
                }    
            }
    	}
    }
    
    public void onAfterInsert(Product_Request__c[] productRequestList, Map<ID, Product_Request__c> productRequestMap){

    }

    
    public void onAfterUpdate(Product_Request__c[] updatedProductRequestList, Map<Id, Product_Request__c> oldProductRequestMap){
        SET<Id> createOrders = new SET<Id>();
        Set<Id> requestsForApproval = new Set<Id>();

        //Create Orders if Product Request is Approved or Submit for approval if needed
        for(Product_Request__c PR : updatedProductRequestList){
            system.debug(PR.Approval_Status__c);
            if(PR.Approval_Status__c == 'Approved' && oldProductRequestMap.get(PR.Id).Approval_Status__c != PR.Approval_Status__c){
                createOrders.add(PR.Id);    
            } else if (PR.Approval_Status__c == 'Requested Approval Process' && oldProductRequestMap.get(PR.Id).Approval_Status__c != PR.Approval_Status__c ){
                requestsForApproval.add(PR.Id);
            }          
        }
        if(createOrders.size() > 0){
            createOrders(createOrders);
        }
        
        if(requestsForApproval.size() >0){
            submitForApproval(requestsForApproval);
        }
    }
       
    public static void createOrders(Set<id> productRequestIdSet){
            List<Product_Request__c> productRequestList = [SELECT Id, Name, Account_Name__c, Account_Partner_Type__c,
                                                           Customer_Name__c, Requestor_Email__c, Street__c, Skip_order_Confirmation_Email__c,
                                                           City__c, State__c, Zip__c, Country__c, Pricebook__c,
                                                           		
                                                                    (SELECT Id,
                                                                            Name,
                                                                            Product__c,
                                                                            Quantity__c
                                                                            FROM Product_Request_Line_Items__r)
                                                                    FROM Product_Request__c
                                                                    WHERE Id IN: productRequestIdSet];
            
            RecordType RT = [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Order' AND Name = 'Product Request']; 
            List<Order> orderToInsertList = new List<Order>();
            List<OrderItem> orderItemToInsertList = new List<OrderItem>();
            Map<String, List<Product_Request_Line_Item__c>> productRequestLineMap = new Map<String, List<Product_Request_Line_Item__c>>();
			Set<Id> pricebookIds = new Set<Id>();
        
            for(Product_Request__c productReq: productRequestList){
                pricebookIds.add(productReq.Pricebook__c);
                productRequestLineMap.put(productReq.Id, productReq.Product_Request_Line_Items__r);
                Order orderToInsert = new  Order();
                orderToInsert.Name = productReq.Name;
                orderToInsert.Skip_Order_Emals__c = productReq.Skip_order_Confirmation_Email__c;
                orderToInsert.EffectiveDate = system.today();
                orderToInsert.Status = Constants.NEW_ORDER_STATUS;
                orderToInsert.RecordTypeId = RT.Id;
                orderToInsert.Pricebook2Id =productReq.Pricebook__c;
                orderToInsert.AccountId = productReq.Account_Name__c;
                orderToInsert.ShippingStreet = productReq.Street__c;
                orderToInsert.ShippingCity = productReq.City__c;
                orderToInsert.ShippingStateCode = productReq.State__c;
                orderToInsert.ShippingPostalCode = productReq.Zip__c;
                orderToInsert.ShippingCountry = productReq.Country__c;
                orderToInsert.Contact__c = productReq.Customer_Name__c;
                orderToInsert.ShipToContactId = productReq.Customer_Name__c;
                orderToInsert.Contact_eMail__c = productReq.Requestor_Email__c;
                orderToInsert.Product_Request__c = productReq.Id;
                orderToInsertList.add(orderToInsert);
            }
            
            list<pricebookEntry> pricebookEntList = [select id,product2Id,pricebook2Id,unitprice from pricebookEntry 
                                                     where pricebook2Id IN :pricebookIds];
            map<string,pricebookEntry> MapList = new map<string,pricebookEntry>();
            for(pricebookEntry PE : pricebookEntList){
                MapList.put(PE.product2Id+'-'+PE.pricebook2Id,PE);
            }
            
            if(orderToInsertList.size() > 0){
                insert orderToInsertList; 
                List<Order> orderToUpdateList = new List<Order>();
                for(Order orders : orderToInsertList){
                    Order orderToUpdate = new Order();
                    orderToUpdate.Id = orders.Id;
                    orderToUpdate.Status = Constants.READY_ORDER_STATUS;
                    orderToUpdateList.add(orderToUpdate);
                    for(Product_Request_Line_Item__c PRItems : productRequestLineMap.get(orders.Product_Request__c)){
                        PricebookEntry pbe = MapList.get(PRItems.Product__c+'-'+orders.Pricebook2Id);
                        OrderItem orderItemToInsert = new OrderItem(); 
                        orderItemToInsert.Product2Id = PRItems.Product__c;
                        orderItemToInsert.Quantity = PRItems.Quantity__c;
                        orderItemToInsert.OrderId = orders.Id;
                        orderItemToInsert.UnitPrice = pbe?.UnitPrice;
                        orderItemToInsert.PricebookEntryId = pbe?.Id;
                        orderItemToInsertList.add(orderItemToInsert);
                    }          
                }
                  
                if(orderItemToInsertList.size() > 0){
                    insert orderItemToInsertList; 
                    if(orderToUpdateList.size() > 0){
                      update orderToUpdateList;    
                    }
                }
            }
        }    

    public static void submitForApproval(Set<Id> requestsForApproval){
    
        List<Product_Request__c> requests = [SELECT Id, Request_Approval_From__c, Approval_Status__c FROM Product_Request__c WHERE Id IN :requestsForApproval];

        for(Product_Request__c r: requests){
        	String userId = UserInfo.getUserId(); 
        	Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        		req1.setComments('Submitting request for approval.');
        		req1.setObjectId(r.Id);
            	List<Id> approvers = new List<Id>();
            	approvers.add(r.Request_Approval_From__c);
        		req1.setNextApproverIds(approvers);
                r.Approval_Status__c = 'Submitted for Approval';
        	// Submit the approval request for the account
        	Approval.ProcessResult result = Approval.process(req1);
       
            
        }        
        

    }
    
}