/**
 * @description Five9ListItem_TriggerHandler_Test contains tests for the Five9ListItem_TriggerHandler class.
 *
 * NOTE: This code is having an issue actually creating Five9LSP__Five9_List_Item__c onto a Five9LSP__Five9_List__c.
 * The creation fials in the Five9 code accessing a null value.  Testing is limited without being able to create
 * these objects.
 */
@IsTest
public without sharing class Five9ListItem_TriggerHandler_Test {
	private static Five9_TestEnv environment;

	@TestSetup
	static void makeData() {
		environment = new Five9_TestEnv();

		environment.createBase();
	}

	static void loadData() {
		environment.loadBase();
	}

	/**  TODO: FUTURE: MAKE TESTS WORK
	@IsTest
	static void test_afterInsert() {
		loadData();

		Test.startTest();

		Five9LSP__Five9_List_Item__c itemLead = makeFive9ListItem(five9ListLead.Id, clientLead.Id, 'Pending');
		itemLead.Id = 'a2017000003BEW8AAO';
		Five9LSP__Five9_List_Item__c itemAccount = makeFive9ListItem(five9ListAccount.Id, prospect.Id, 'Pending');
		itemAccount.Id = 'a2017000003M8W8BAO';

		// TODO: LATER: Insert the items so have real Ids
		Map<Id, Five9LSP__Five9_List_Item__c> mapItems = new Map<Id, Five9LSP__Five9_List_Item__c>();
		mapItems.put(itemLead.Id, itemLead);
		mapItems.put(itemAccount.Id, itemAccount);
		Five9ListItem_TriggerHandler handler = new Five9ListItem_TriggerHandler();
		handler.afterInsert(mapItems);

		Test.stopTest();

		prospect = [SELECT Id, Name, Five9_List_Name__c FROM Account WHERE Name = '!!!TEST PROSPECT'];
		clientLead = [SELECT Id, Name, Five9_List_Name__c FROM Lead WHERE LastName = 'TESTLEAD'];

		System.assertEquals(five9ListAccount.Id, prospect.Five9_List_Name__c, 'Should be assigned to the list');
		System.assertEquals(five9ListLead.Id, clientLead.Five9_List_Name__c, 'Should be assigned to the list');
	}

	@IsTest
	static void test_afterUpdate() {
		loadData();

		Test.startTest();

		Five9LSP__Five9_List_Item__c itemLead = makeFive9ListItem(five9ListLead.Id, clientLead.Id, 'Pending');
		itemLead.Id = 'a2017000003BEW8AAO';
		Five9LSP__Five9_List_Item__c itemAccount = makeFive9ListItem(five9ListAccount.Id, prospect.Id, 'Pending');
		itemAccount.Id = 'a2017000003M8W8BAO';

		// TODO: LATER: Insert the items so have real Ids
		Map<Id, Five9LSP__Five9_List_Item__c> mapItems = new Map<Id, Five9LSP__Five9_List_Item__c>();
		mapItems.put(itemLead.Id, itemLead);
		mapItems.put(itemAccount.Id, itemAccount);
		Five9ListItem_TriggerHandler handler = new Five9ListItem_TriggerHandler();
		handler.afterUpdate(mapItems, mapItems);

		Test.stopTest();

		prospect = [SELECT Id, Name, Five9_List_Name__c FROM Account WHERE Name = '!!!TEST PROSPECT'];
		clientLead = [SELECT Id, Name, Five9_List_Name__c FROM Lead WHERE LastName = 'TESTLEAD'];

		System.assertEquals(five9ListAccount.Id, prospect.Five9_List_Name__c, 'Should be assigned to the list');
		System.assertEquals(five9ListLead.Id, clientLead.Five9_List_Name__c, 'Should be assigned to the list');
	}

	@IsTest
	static void test_afterDelete() {
		loadData();

		clientLead.Five9_List_Name__c = five9ListLead.Id;
		prospect.Five9_List_Name__c = five9ListAccount.Id;
		update clientLead;
		update prospect;

		Test.startTest();

		Five9LSP__Five9_List_Item__c itemLead = makeFive9ListItem(five9ListLead.Id, clientLead.Id, 'Pending');
		itemLead.Id = 'a2017000003BEW8AAO';
		Five9LSP__Five9_List_Item__c itemAccount = makeFive9ListItem(five9ListAccount.Id, prospect.Id, 'Pending');
		itemAccount.Id = 'a2017000003M8W8BAO';

		// TODO: LATER: Insert the items so have real Ids
		Map<Id, SObject> mapItems = new Map<Id, Five9LSP__Five9_List_Item__c>();
		mapItems.put(itemLead.Id, itemLead);
		mapItems.put(itemAccount.Id, itemAccount);
		Five9ListItem_TriggerHandler handler = new Five9ListItem_TriggerHandler();
		handler.afterDelete(mapItems);

		Test.stopTest();

		prospect = [SELECT Id, Name, Five9_List_Name__c FROM Account WHERE Name = '!!!TEST PROSPECT'];
		clientLead = [SELECT Id, Name, Five9_List_Name__c FROM Lead WHERE LastName = 'TESTLEAD'];

		System.assertEquals(five9ListAccount.Id, prospect.Five9_List_Name__c, 'Should be assigned to the list');
		System.assertEquals(five9ListLead.Id, clientLead.Five9_List_Name__c, 'Should be assigned to the list');
	}
	**/
}