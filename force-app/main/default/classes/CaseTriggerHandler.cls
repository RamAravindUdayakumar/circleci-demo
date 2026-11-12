public with sharing class CaseTriggerHandler {    
    /**
     * @description Sets default values on new Cases before insertion.
     * @param newCases List of new Case records from Trigger.new
     */
    public static void handleBeforeInsert(List<Case> newCases) {
        for (Case c : newCases) {
            if (String.isBlank(c.Priority)) {
                c.Priority = 'Medium';
            }
            if (c.Origin == 'Phone' && c.Priority != 'High') {
                c.Priority = 'High';
            }
        }
    }

    /**
     * @description Validates Case updates before saving.
     * @param newCases List of updated Case records from Trigger.new
     * @param oldCaseMap Map of old Case records from Trigger.oldMap
     */
    public static void handleBeforeUpdate(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);
            
            // Require resolution notes in Description when closing a High Priority Case
            if (c.Status == 'Closed' && oldCase.Status != 'Closed' && 
                c.Priority == 'High' && String.isBlank(c.Description)) {
                c.addError('Description is required before closing a High Priority Case.');
            }
        }
    }
}