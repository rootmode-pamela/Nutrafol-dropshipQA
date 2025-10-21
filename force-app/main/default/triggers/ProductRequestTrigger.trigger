trigger ProductRequestTrigger on Product_Request__c (after insert, after update, before insert) {
    ProductRequestTriggerHandler handler = new ProductRequestTriggerHandler();
    if(trigger.isBefore && trigger.isInsert){
        handler.beforeInsert(Trigger.new);      
    }
    if(trigger.isAfter && trigger.isInsert){
        handler.onAfterInsert(Trigger.new, Trigger.newMap);      
    }
    if(trigger.isAfter && trigger.isUpdate){
        handler.OnAfterUpdate(Trigger.new, trigger.oldMap);     
    }
}