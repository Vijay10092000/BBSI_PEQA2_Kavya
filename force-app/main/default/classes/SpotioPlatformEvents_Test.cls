/**
* @description SpotioPlatformEvents_Test contains Unit Tests for the SpotioPlatformEvents class.
*/
@IsTest
public without sharing class SpotioPlatformEvents_Test {
	private static final Id FAKE_PROSPECT_ID = Id.valueOf('001000000000TST');
	private static final Id FAKE_CLIENT1_ID = Id.valueOf('001000000001TST');
	private static final Id FAKE_CLIENT2_ID = Id.valueOf('001000000002TST');
	private static final Id FAKE_CONTACT_ID = Id.valueOf('003000000000TST');
	private static final Id FAKE_LEAD_ID = Id.valueOf('00Q000000000TST');

	@IsTest
	static void test_readBlockedUser() {
		SpotioPlatformEvents spe = new SpotioPlatformEvents('Account');

		Assert.isTrue(spe.blockedUsers.contains('Boomi Integration'));
		Assert.isTrue(spe.blockedUsers.contains('Spotio Integration'));

		Assert.isFalse(spe.blockedUsers.contains('Fake Name'));
	}

	@IsTest
	static void test_readFieldUpdates() {	
		SpotioPlatformEvents spe;

		spe = new SpotioPlatformEvents('Account');
		Assert.isFalse(spe.checkFields.isEmpty());
		
		spe = new SpotioPlatformEvents('Contact');
		Assert.isFalse(spe.checkFields.isEmpty());
		
		spe = new SpotioPlatformEvents('Lead');
		Assert.isFalse(spe.checkFields.isEmpty());

		spe = new SpotioPlatformEvents('FakeObject');
		Assert.isTrue(spe.checkFields.isEmpty());
	}

	@IsTest
	static void test_hasUpdatedField() {
		Account oldAcc = new Account(
			Name = 'TEST ONE'
		);
		Account newAcc = new Account(
			Name = 'TEST ONE',
			External_Id__c = 'abc'
		);
		
		SpotioPlatformEvents spe = new SpotioPlatformEvents('Account');
		spe.checkFields = new List<String>{ 'External_Id__c' };

		Assert.isTrue(spe.hasUpdatedField(oldAcc, newAcc));

		Assert.isFalse(spe.hasUpdatedField(newAcc, newAcc));
	}

	@IsTest
	static void test_addEvent() {
		SpotioPlatformEvents spe = new SpotioPlatformEvents('Contact');

		spe.addEvent(FAKE_CONTACT_ID, SpotioPlatformEvents.ActionType.CREATED);

		Assert.areEqual(1, spe.events.size());
	}

	@IsTest
	static void test_processInsert() {
		Account prospect1 = TestFactoryAccount.makeProspect('PROSPECT 1');
		prospect1.Id = FAKE_PROSPECT_ID;

		Account clientNew1 = TestFactoryAccount.makeClient('CLIENT 1');
		clientNew1.Id = FAKE_CLIENT1_ID;
		clientNew1.BillingStreet = '123 Fake Street';
		clientNew1.Spotio_Id__c = 'SPOTIO ID';

		List<Account> newAccounts = new List<Account>{ prospect1, clientNew1 };

		SpotioPlatformEvents spe = new SpotioPlatformEvents('Account');
		spe.action = SpotioPlatformEvents.ActionType.INSERTING;

		spe.process(null, newAccounts);

		Assert.areEqual(2, spe.events.size());

		Spotio_Event__e event;
		
		event = spe.events[0];
		Assert.areEqual(FAKE_PROSPECT_ID, event.Object_Id__c);
		Assert.areEqual('account', event.Object_Name__c);
		Assert.areEqual('CREATED', event.Type__c);

		event = spe.events[1];
		Assert.areEqual(FAKE_CLIENT1_ID, event.Object_Id__c);
		Assert.areEqual('account', event.Object_Name__c);
		Assert.areEqual('UPDATED', event.Type__c);
	}

	@IsTest
	static void test_processUpdate() {
		Account prospectOld1 = TestFactoryAccount.makeProspect('PROSPECT 1');
		prospectOld1.Id = FAKE_PROSPECT_ID;

		Account prospectNew1 = prospectOld1.clone(true, true, true, true);
		prospectNew1.ACA_Notes__c = 'FAKE NOTES';
		
		Account clientOld1 = TestFactoryAccount.makeClient('CLIENT 1');
		clientOld1.Id = FAKE_CLIENT1_ID;
		clientOld1.Spotio_Id__c = 'SPOTIO ID';

		Account clientNew1 = clientOld1.clone(true, true, true, true);
		clientNew1.BillingStreet = '123 Fake Street';

		Map<Id, Account> oldAccounts = new Map<Id, Account>{ 
			prospectOld1.Id => prospectOld1,
			clientOld1.Id => clientOld1 
		};

		List<Account> newAccounts = new List<Account>{ prospectNew1, clientNew1 };

		SpotioPlatformEvents spe = new SpotioPlatformEvents('Account');
		spe.action = SpotioPlatformEvents.ActionType.UPDATING;

		spe.process(oldAccounts, newAccounts);

		Assert.areEqual(1, spe.events.size());
		
		Spotio_Event__e event = spe.events[0];
		Assert.areEqual(FAKE_CLIENT1_ID, event.Object_Id__c);
		Assert.areEqual('account', event.Object_Name__c);
		Assert.areEqual('UPDATED', event.Type__c);
	}

	@IsTest
	static void test_processUpdate_BlockedUser() {
		User userBoomi = [SELECT Id FROM User WHERE Name = 'Boomi Integration' LIMIT 1];

		Account prospectOld1 = TestFactoryAccount.makeProspect('PROSPECT 1');
		prospectOld1.Id = FAKE_PROSPECT_ID;

		Account prospectNew1 = prospectOld1.clone(true, true, true, true);
		prospectNew1.ACA_Notes__c = 'FAKE NOTES';
		
		Account clientOld1 = TestFactoryAccount.makeClient('CLIENT 1');
		clientOld1.Id = FAKE_CLIENT1_ID;
		clientOld1.Spotio_Id__c = 'SPOTIO ID';

		Account clientNew1 = clientOld1.clone(true, true, true, true);
		clientNew1.BillingStreet = '123 Fake Street';

		// FIX: Confirm BillingStreet is a triggering field.

		Map<Id, Account> oldAccounts = new Map<Id, Account>{ 
			prospectOld1.Id => prospectOld1,
			clientOld1.Id => clientOld1 
		};

		List<Account> newAccounts = new List<Account>{ prospectNew1, clientNew1 };

		SpotioPlatformEvents spe = new SpotioPlatformEvents('Account');

		System.RunAs(userBoomi) {
			spe.process(oldAccounts, newAccounts);
		}

		Assert.areEqual(0, spe.events.size());
	}

	@IsTest
	static void test_preprocess() {		
		Account prospect = TestFactoryAccount.makeProspect('PROSPECT 1');		
		Account client = TestFactoryAccount.makeClient('CLIENT 1');
		Account location = TestFactoryAccount.makeAccount('LOCATION 1', 'Location');
		Account terminated = TestFactoryAccount.makeAccount('TERMINATED 1', 'Terminated');

		List<Account> newAccounts = new List<Account>{ prospect, client, location, terminated };
		
		SpotioPlatformEvents spe = new SpotioPlatformEvents('Account');
		List<Account> accounts = (List<Account>) spe.preprocess(newAccounts);

		Assert.areEqual(3, accounts.size());
		Assert.isTrue(accounts.contains(prospect));
		Assert.isTrue(accounts.contains(client));
		Assert.isTrue(accounts.contains(terminated));
		Assert.isFalse(accounts.contains(location));
	}

	@IsTest
	static void test_execute() {
		Account prospect1 = TestFactoryAccount.makeProspect('PROSPECT 1');
		prospect1.Id = FAKE_PROSPECT_ID;
		Account location = TestFactoryAccount.makeAccount('LOCATION 1', 'Location');

		List<Account> newAccounts = new List<Account>{ prospect1, location };

		SpotioPlatformEvents spe = new SpotioPlatformEvents('Account');
		spe.execute(null, newAccounts);

		Assert.areEqual(1, spe.events.size());

		Spotio_Event__e event;
		
		event = spe.events[0];
		Assert.areEqual(FAKE_PROSPECT_ID, event.Object_Id__c);
		Assert.areEqual('account', event.Object_Name__c);
		Assert.areEqual('CREATED', event.Type__c);
		
		Assert.areEqual(1, spe.numberPublished);
	}
}