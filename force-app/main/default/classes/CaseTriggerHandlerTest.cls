@isTest
private class CaseTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        List<Case> testCases = new List<Case>{
            new Case(
                Subject = 'Web Inquiry',
                Origin = 'Web',
                Status = 'New',
                Priority = null // Should default to Medium
            ),
            new Case(
                Subject = 'Urgent Phone Issue',
                Origin = 'Phone',
                Status = 'New',
                Priority = 'Low' // Should escalate to High
            )
        };
        insert testCases;
    }

    @isTest
    static void testBeforeInsertDefaults() {
        Case webCase = [SELECT Priority FROM Case WHERE Subject = 'Web Inquiry' LIMIT 1];
        Case phoneCase = [SELECT Priority FROM Case WHERE Subject = 'Urgent Phone Issue' LIMIT 1];

        System.assertEquals('Medium', webCase.Priority, 'Blank priority should default to Medium.');
        System.assertEquals('High', phoneCase.Priority, 'Phone origin cases should escalate to High priority.');
    }

    @isTest
    static void testBeforeUpdateValidationFailure() {
        Case phoneCase = [SELECT Id, Status, Priority, Description FROM Case WHERE Subject = 'Urgent Phone Issue' LIMIT 1];
        phoneCase.Status = 'Closed';
        phoneCase.Description = null;

        Test.startTest();
        try {
            update phoneCase;
            System.assert(false, 'Expected DmlException when closing High priority case without description.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Description is required before closing a High Priority Case.'),
                'Unexpected validation message: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdateValidationSuccess() {
        Case phoneCase = [SELECT Id, Status, Priority, Description FROM Case WHERE Subject = 'Urgent Phone Issue' LIMIT 1];
        phoneCase.Status = 'Closed';
        phoneCase.Description = 'Issue resolved via phone troubleshooting.';

        Test.startTest();
        update phoneCase;
        Test.stopTest();

        Case updatedCase = [SELECT Status FROM Case WHERE Id = :phoneCase.Id];
        System.assertEquals('Closed', updatedCase.Status, 'Case should close successfully when Description is populated.');
    }
}