@isTest
private class DropShipController_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            ShippingStreet = '123 Test St',
            ShippingCity = 'Test City',
            ShippingStateCode = 'CA',
            ShippingPostalCode = '12345',
            ShippingCountryCode = 'US'
        );
        insert testAccount;

        Account testChildAccount = new Account(
            Name = 'Test Account',
            ParentId = TestAccount.id,
            ShippingStreet = '123 Test St',
            ShippingCity = 'Test City',
            ShippingStateCode = 'CA',
            ShippingPostalCode = '12345',
            ShippingCountryCode = 'US'
        );
        insert testChildAccount;
        
        // Create test Contacts
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(
            AccountId = testAccount.Id,
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com'
        ));
        contacts.add(new Contact(
            AccountId = testAccount.Id,
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane.smith@test.com'
        ));
        insert contacts;
        
        // Create AccountContactRelations
        List<AccountContactRelation> relations = new List<AccountContactRelation>();
        for (Contact c : contacts) {
            AccountContactRelation acr = new AccountContactRelation(
                AccountId = testChildAccount.Id,
                ContactId = c.Id,
                IsActive = true
            );
            relations.add(acr);
        }
        insert relations;
    }
    
    @isTest
    static void testGetRelatedContacts() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account WHERE ParentId != null LIMIT 1];
        
        // Test the method
        Test.startTest();
        List<DropShipController.ContactOption> results = 
            DropShipController.getRelatedContacts(testAccount.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(2, results.size(), 'Should return 2 contacts');
        System.assertNotEquals(null, results[0].value, 'Contact value should not be null');
        System.assertNotEquals(null, results[0].label, 'Contact label should not be null');
        System.assert(results[0].label.contains('@'), 'Label should contain email');
    }
    
    @isTest
    static void testGetRelatedContactsNoContacts() {
        // Create account with no contacts
        Account emptyAccount = new Account(Name = 'Empty Account');
        insert emptyAccount;
        
        // Test the method
        Test.startTest();
        List<DropShipController.ContactOption> results = 
            DropShipController.getRelatedContacts(emptyAccount.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(0, results.size(), 'Should return 0 contacts');
    }
}