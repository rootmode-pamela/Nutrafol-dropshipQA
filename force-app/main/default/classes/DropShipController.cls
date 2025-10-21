public with sharing class DropShipController {
    
    @AuraEnabled(cacheable=true)
    public static List<ContactOption> getRelatedContacts(Id accountId) {
        List<Id> accountIds = new List<Id>{accountId};
        accountIds.add(accountId);
        String parentAccountId = [SELECT Id, ParentId FROM Account WHERE Id = :accountId LIMIT 1].ParentId;
        if (parentAccountId != null) {
            accountIds.add(parentAccountId);
        }
        List<ContactOption> contactOptions = new List<ContactOption>();
        
        // Query all related contacts through AccountContactRelation
        List<AccountContactRelation> relations = [
            SELECT ContactId, Contact.Name, Contact.Email
            FROM AccountContactRelation
            WHERE AccountId in :accountIds 
            AND IsActive = true
            ORDER BY Contact.Name ASC
        ];
        
        Set<Id> contactIds = new Set<Id>();
        for (AccountContactRelation relation : relations) {
            if(!contactIds.contains(relation.ContactId)){
                ContactOption option = new ContactOption();
                option.value = relation.ContactId;
                option.label = relation.Contact.Name;
                if (relation.Contact.Email != null) {
                    option.label += ' (' + relation.Contact.Email + ')';
                }
                contactOptions.add(option);
                contactIds.add(relation.ContactId);
            }
        }
        
        return contactOptions;
    }
    
    // Wrapper class for contact options
    public class ContactOption {
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String label;
    }
}