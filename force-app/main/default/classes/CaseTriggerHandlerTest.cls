@isTest
private class CaseTriggerHandlerTest {

    @isTest
    static void testHandleBeforeInsert() {
        List<Case> newCases = new List<Case>{
            new Case(Subject = 'Web Inquiry', Origin = 'Web', Priority = null),
            new Case(Subject = 'Urgent Phone Issue', Origin = 'Phone', Priority = 'Low')
        };

        Test.startTest();
        CaseTriggerHandler.handleBeforeInsert(newCases);
        Test.stopTest();

        System.assertEquals('Medium', newCases[0].Priority, 'Blank priority should default to Medium.');
        System.assertEquals('High', newCases[1].Priority, 'Phone origin should escalate to High.');
    }

    @isTest
    static void testHandleBeforeUpdate() {
        // Create fake Ids in memory without DML so oldMap works
        Id fakeCaseId = Case.SObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';

        Case oldCase = new Case(Id = fakeCaseId, Status = 'New', Priority = 'High');
        Case invalidUpdate = new Case(Id = fakeCaseId, Status = 'Closed', Priority = 'High', Description = null);
        Case validUpdate = new Case(Id = fakeCaseId, Status = 'Closed', Priority = 'High', Description = 'Resolved.');

        Map<Id, Case> oldMap = new Map<Id, Case>{ fakeCaseId => oldCase };

        Test.startTest();
        // Test failure path (triggers addError)
        CaseTriggerHandler.handleBeforeUpdate(new List<Case>{ invalidUpdate }, oldMap);
        // Test success path
        CaseTriggerHandler.handleBeforeUpdate(new List<Case>{ validUpdate }, oldMap);
        Test.stopTest();

        System.assertEquals(1, invalidUpdate.getErrors().size(), 'Expected validation error when Description is blank.');
        System.assertEquals(0, validUpdate.getErrors().size(), 'Expected no errors when Description is provided.');
    }
}