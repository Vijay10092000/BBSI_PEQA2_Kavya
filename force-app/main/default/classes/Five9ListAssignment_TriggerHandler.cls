/**
 * @description Five9ListAssignment_TriggerHandler controls trigger events for Five9 List Assignment objects.
 */
public without sharing class Five9ListAssignment_TriggerHandler extends TriggerHandlerInvoker.TriggerHandler_Abstract {
	override public void afterInsert(Map<Id, SObject> mapNew) {
		Map<Id, Five9_List_Assignment__c> newAssigns = (Map<Id, Five9_List_Assignment__c>) mapNew;

		Five9ListAssignment.updateMultipleLists(newAssigns.values());
	}

	override public void afterUpdate(Map<Id, SObject> mapOld, Map<Id, SObject> mapNew) {
		Map<Id, Five9_List_Assignment__c> oldAssigns = (Map<Id, Five9_List_Assignment__c>) mapOld;
		Map<Id, Five9_List_Assignment__c> newAssigns = (Map<Id, Five9_List_Assignment__c>) mapNew;

		Five9ListAssignment.updateMultipleLists(newAssigns.values());
	}

	override public void afterDelete(Map<Id, SObject> mapOld) {
		Map<Id, Five9_List_Assignment__c> oldAssigns = (Map<Id, Five9_List_Assignment__c>) mapOld;

		Five9ListAssignment.updateMultipleLists(oldAssigns.values());
	}

	override public void afterUndelete(Map<Id, SObject> mapNew) {
		Map<Id, Five9_List_Assignment__c> newAssigns = (Map<Id, Five9_List_Assignment__c>) mapNew;

		Five9ListAssignment.updateMultipleLists(newAssigns.values());
	}
}