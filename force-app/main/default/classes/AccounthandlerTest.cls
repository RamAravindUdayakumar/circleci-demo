@isTest
private class AccounthandlerTest {

    @testSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 1; i <= 5; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology',
                Phone = '987654321' + i
            ));
        }
        insert accounts;
    }

    @isTest
    static void testGetRecentAccounts() {
        Test.startTest();
        List<Account> result = Accounthandler.getRecentAccounts(3);
        Test.stopTest();

        Assert.areEqual(3, result.size(), 'Should return exactly 3 accounts based on the limit.');
        Assert.isNotNull(result[0].Name, 'Account name should be populated.');
    }

    @isTest
    static void testCreateAccountSuccess() {
        Test.startTest();
        Account newAcc = Accounthandler.createAccount('Acme Corp', 'Manufacturing', '1234567890');
        Test.stopTest();

        Assert.isNotNull(newAcc.Id, 'Account should have been inserted and received an Id.');
        
        Account insertedAcc = [
            SELECT Name, Industry, Phone 
            FROM Account 
            WHERE Id = :newAcc.Id 
            LIMIT 1
        ];
        Assert.areEqual('Acme Corp', insertedAcc.Name, 'Account name should match.');
        Assert.areEqual('Manufacturing', insertedAcc.Industry, 'Industry should match.');
    }

    @isTest
    static void testCreateAccountBlankNameException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            Accounthandler.createAccount('', 'Finance', '1234567890');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'An AuraHandledException should be thrown when the account name is blank.');
    }
}