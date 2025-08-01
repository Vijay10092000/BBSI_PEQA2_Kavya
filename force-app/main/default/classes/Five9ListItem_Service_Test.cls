/**
 * @description Five9ListItem_Service_Test contains tests for the Five9ListItem_Service class.
 *
 * NOTE: This code is having an issue actually creating Five9LSP__Five9_List_Item__c onto a Five9LSP__Five9_List__c.
 * The creation fials in the Five9 code accessing a null value.  Testing is limited without being able to create
 * these objects.
 */
@IsTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
public without sharing class Five9ListItem_Service_Test {
	
	/* FUTURE: Delete with User Story 65240 Remove Five9 managed package/code/etc
	private static Five9_TestEnv environment = new Five9_TestEnv();

	@TestSetup
	static void makeData() {
		environment.createBase();
	}

	static void loadData() {
		environment.loadBase();
	}

	@IsTest
	static void test_Trigger() {
		loadData();

		Test.startTest();

		try {
			insert TestFactoryFive9ListItem.makeFive9ListItem(
				environment.five9ListLead1.Id,
				environment.clientLead1.Id,
				'Pending'
			);

			Assert.isTrue(false, 'Exception should have been thrown.');
		} catch (Exception e) {
			Assert.isTrue(true, 'Exception should be thrown.');
		}
	}

	@IsTest
	static void test_getRecords() {
		loadData();

		Test.startTest();

		Five9LSP__Five9_List_Item__c itemLead = TestFactoryFive9ListItem.makeFive9ListItem(
			environment.five9ListLead1.Id,
			environment.clientLead1.Id,
			'Pending'
		);
		Five9LSP__Five9_List_Item__c itemAccount = TestFactoryFive9ListItem.makeFive9ListItem(
			environment.five9ListAccount.Id,
			environment.prospect.Id,
			'Pending'
		);

		Map<Id, Sobject> mapItems = Five9ListItem_Service.getRecords(
			new List<Five9LSP__Five9_List_Item__c>{ itemLead, itemAccount }
		);

		Test.stopTest();

		Assert.isTrue(mapItems.containsKey(environment.clientLead1.Id), 'Should contain the Lead.');
		Assert.isTrue(mapItems.containsKey(environment.prospect.Id), 'Should contain the Prospect.');
	}

	@IsTest
	static void test_code() {
		List<String> decoded;
		String encoded;

		encoded = Five9ListItem_Service.encode('abc', 'def', 'ghi');
		Assert.areEqual('List:abc!Lead:def!Account:ghi', encoded);
		decoded = Five9ListItem_Service.decode(encoded);
		Assert.areEqual('abc', decoded[0]);
		Assert.areEqual('def', decoded[1]);
		Assert.areEqual('ghi', decoded[2]);

		encoded = Five9ListItem_Service.encode(null, null, null);
		Assert.areEqual('List:!Lead:!Account:', encoded);
		decoded = Five9ListItem_Service.decode(encoded);
		Assert.areEqual(null, decoded[0]);
		Assert.areEqual(null, decoded[1]);
		Assert.areEqual(null, decoded[2]);

		encoded = Five9ListItem_Service.encode('list', 'lead', null);
		Assert.areEqual('List:list!Lead:lead!Account:', encoded);
		decoded = Five9ListItem_Service.decode(encoded);
		Assert.areEqual('list', decoded[0]);
		Assert.areEqual('lead', decoded[1]);
		Assert.areEqual(null, decoded[2]);

		encoded = Five9ListItem_Service.encode('list', null, 'account');
		Assert.areEqual('List:list!Lead:!Account:account', encoded);
		decoded = Five9ListItem_Service.decode(encoded);
		Assert.areEqual('list', decoded[0]);
		Assert.areEqual(null, decoded[1]);
		Assert.areEqual('account', decoded[2]);
	}
	*/
}