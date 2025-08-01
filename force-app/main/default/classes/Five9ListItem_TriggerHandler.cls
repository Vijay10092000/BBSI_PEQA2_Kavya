/**
 * @description Five9ListItem_TriggerHandler controls trigger events for Five9LSP__Five9_List_Item__c objects.
 */
public without sharing class Five9ListItem_TriggerHandler extends TriggerHandlerInvoker.TriggerHandler_Abstract {

	/* FUTURE: Delete with User Story 65240 Remove Five9 managed package/code/etc
	// This code is blocked by the trigger being inactive
	
	/ **
	 * @description afterInsert performs actions on related objects to the mapNew sObjects after
	 * the insert.
	 * @param mapNew is the map of sObjects after being saved
	 * /
	override public void afterInsert(Map<Id, SObject> mapNew) {
		Map<Id, Five9LSP__Five9_List_Item__c> mapNewItems = (Map<Id, Five9LSP__Five9_List_Item__c>) mapNew;

		Five9ListItem_Service.setRelatedObjects(mapNewItems.values());
		Five9ListItem_Service.createFive9Assignment(mapNewItems.values());
	}

	/ **
	 * @description afterUpdate performs actions on related objects to the mapNew sObjects after
	 * the update.
	 * @param mapOld is the map of sObjects before the new changes
	 * @param mapNew is the map of sObjects with the saved changes
	 * /
	override public void afterUpdate(Map<Id, SObject> mapOld, Map<Id, SObject> mapNew) {
		Map<Id, Five9LSP__Five9_List_Item__c> mapOldItems = (Map<Id, Five9LSP__Five9_List_Item__c>) mapOld;
		Map<Id, Five9LSP__Five9_List_Item__c> mapNewItems = (Map<Id, Five9LSP__Five9_List_Item__c>) mapNew;

		Five9ListItem_Service.checkObjectChange(mapOldItems, mapNew.values());
		Five9ListItem_Service.setRelatedObjects(mapNewItems.values());
	}

	/ **
	 * @description afterDelete performs actions on related to the mapOld sObjects after
	 * the delete.
	 * @param mapOld is the map of sObjects which have been deleted
	 * /
	override public void afterDelete(Map<Id, SObject> mapOld) {
		Map<Id, Five9LSP__Five9_List_Item__c> mapOldItems = (Map<Id, Five9LSP__Five9_List_Item__c>) mapOld;

		Five9ListItem_Service.clearRelatedObjects(mapOldItems.values());
		Five9ListAssignment.markInactive(mapOldItems.values());
	}
	*/
}