/**
 * @SpotioPlatformEvents_Account_Test contains unit tests for the SpotioPlatformEvents_Account class.
 */
@IsTest
private class SpotioPlatformEvents_Account_Test {
	private static final Id FAKE_ACCOUNT_ID_1 = Id.valueOf('001000000001TST');
	private static final Id FAKE_ACCOUNT_ID_2 = Id.valueOf('001000000002TST');

    @IsTest
    static void test_process_OnInsert() {
		Account client = TestFactoryAccount.makeClient('CLIENT 1');
		client.Id = FAKE_ACCOUNT_ID_1;
		Account prospect = TestFactoryAccount.makeProspect('PROSPECT 1');
		prospect.Id = FAKE_ACCOUNT_ID_2;
		prospect.Spotio_Id__c = '12345';

		SpotioPlatformEvents_Account spea = new SpotioPlatformEvents_Account();

		spea.processRecord(null, client);
		spea.processRecord(null, prospect);

		Assert.areEqual(2, spea.events.size());

		Spotio_Event__e event1 = spea.events[0];
		Assert.areEqual(FAKE_ACCOUNT_ID_1, event1.Object_Id__c);
		Assert.areEqual('account', event1.Object_Name__c);
		Assert.areEqual('CREATED', event1.Type__c);

		Spotio_Event__e event2 = spea.events[1];
		Assert.areEqual(FAKE_ACCOUNT_ID_2, event2.Object_Id__c);
		Assert.areEqual('account', event2.Object_Name__c);
		Assert.areEqual('UPDATED', event2.Type__c);
	}

	@IsTest
	static void test_process_OnUpdate_NoSpotio_Standard() {
		Account clientOld = TestFactoryAccount.makeClient('CLIENT 1');
		clientOld.Id = FAKE_ACCOUNT_ID_1;

		Account clientNew = clientOld.clone(true, true, true, true);
		clientNew.Est_Annual_Payroll__c = 30000;

		SpotioPlatformEvents_Account spea = new SpotioPlatformEvents_Account();

		spea.processRecord(clientOld, clientNew);
		
		Assert.areEqual(0, spea.events.size());
	}

	@IsTest
	static void test_process_OnUpdate_NoSPotio_RecordType() {
		Account clientOld = TestFactoryAccount.makeClient('CLIENT 1');
		clientOld.Id = FAKE_ACCOUNT_ID_1;

		Account clientNew = clientOld.clone(true, true, true, true);
		clientNew.RecordTypeId = RecordTypeService.getId('Account', 'Prospect');

		User user = [SELECT Id FROM User WHERE Name = 'Boomi Integration'];

		SpotioPlatformEvents_Account spea = new SpotioPlatformEvents_Account();

		System.runAs(user) {
			spea.processRecord(clientOld, clientNew);
		}
		
		Assert.areEqual(1, spea.events.size());
	}

	@IsTest
	static void test_process_OnUpdate_Spotio_BlockedUser() {
		Account clientOld = TestFactoryAccount.makeClient('CLIENT 1');
		clientOld.Id = FAKE_ACCOUNT_ID_1;
		clientOld.Spotio_Id__c = '12345';

		Account clientNew = clientOld.clone(true, true, true, true);
		
		User user = [SELECT Id FROM User WHERE Name = 'Boomi Integration'];

		SpotioPlatformEvents_Account spea = new SpotioPlatformEvents_Account();

		System.runAs(user) {
			spea.processRecord(clientOld, clientNew);
		}
		
		Assert.areEqual(0, spea.events.size());
	}

	@IsTest
	static void test_process_OnUpdate_Spotio_Standard() {
		Account clientOld = TestFactoryAccount.makeClient('CLIENT 1');
		clientOld.Id = FAKE_ACCOUNT_ID_1;
		clientOld.Spotio_Id__c = '12345';

		Account clientNew = clientOld.clone(true, true, true, true);
		clientNew.NumberOfEmployees = 300;

		SpotioPlatformEvents_Account spea = new SpotioPlatformEvents_Account();

		spea.processRecord(clientOld, clientNew);
		
		Assert.areEqual(1, spea.events.size());
		
		Spotio_Event__e event = spea.events[0];
		Assert.areEqual(FAKE_ACCOUNT_ID_1, event.Object_Id__c);
		Assert.areEqual('account', event.Object_Name__c);
		Assert.areEqual('UPDATED', event.Type__c);
	}

	@IsTest
	static void test_process_OnUpdate_Spotio_Other() {
		Account clientOld = TestFactoryAccount.makeClient('CLIENT 1');
		clientOld.Id = FAKE_ACCOUNT_ID_1;
		clientOld.Spotio_Id__c = '12345';

		Account clientNew = clientOld.clone(true, true, true, true);
		clientNew.Active_Date__c = Date.today().addDays(3);

		SpotioPlatformEvents_Account spea = new SpotioPlatformEvents_Account();

		spea.processRecord(clientOld, clientNew);
		
		Assert.areEqual(0, spea.events.size());
	}

	@IsTest
	static void test_setContactSpotioIdsFromAccount() {
		Account client1 = TestFactoryAccount.makeClient('CLIENT 1');
		Account client2 = TestFactoryAccount.makeClient('CLIENT 2');
		client2.Spotio_Id__c = 'SPOTIO ID A2';
		insert new List<Account>{ client1, client2 };

		Contact contact1_1 = TestFactoryContact.makeClient('ONE-ONE', 'CONTACT', client1.Id);
		Contact contact1_2 = TestFactoryContact.makeClient('ONE-TWO', 'CONTACT', client1.Id);
		contact1_2.Spotio_Id__c = 'SPOTIO ID C1_2';
		Contact contact2_1 = TestFactoryContact.makeClient('TWO-ONE', 'CONTACT', client2.Id);
		insert new List<Contact>{ contact1_1, contact1_2, contact2_1 };

		Account oldClient1 = client1.clone(true, true, true, true);
		Account oldClient2 = client2.clone(true, true, true, true);

		client1.Spotio_Id__c = 'SPOTIO ID A1';

		Map<Id, Account> oldAccounts = new Map<Id, Account>{ oldClient1.Id => oldClient1, oldClient2.Id => oldClient2 };
		List<Account> newAccounts = new List<Account>{ client1, client2 };

		Set<Id> idContacts = SpotioPlatformEvents_Account.determineContactsNeedSpotioId(oldAccounts, newAccounts);

		Assert.areEqual(1, idContacts.size());
		Assert.isTrue(idContacts.contains(contact1_1.Id));
	}
}