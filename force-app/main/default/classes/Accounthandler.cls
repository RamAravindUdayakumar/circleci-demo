public with sharing class Accounthandler {

    // Retrieve active accounts with their industry and annual revenue
    @AuraEnabled(cacheable=true)
    public static List<Account> getRecentAccounts(Integer recordLimit) {
        return [
            SELECT Id, Name, Industry, AnnualRevenue, Phone, CreatedDate
            FROM Account
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT :recordLimit
        ];
    }

    // Insert a new account record
    @AuraEnabled
    public static Account createAccount(String accountName, String industry, String phone) {
        if (String.isBlank(accountName)) {
            throw new AuraHandledException('Account Name cannot be blank.');
        }

        Account newAcc = new Account(
            Name = accountName,
            Industry = industry,
            Phone = phone
        );

        insert as user newAcc;
        return newAcc;
    }
}