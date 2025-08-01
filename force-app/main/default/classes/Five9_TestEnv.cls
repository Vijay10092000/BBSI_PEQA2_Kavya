/**
 * @description Five9_TestEnv aids in building tests.
 */
@IsTest
@SuppressWarnings('PMD.ApexDoc')
public without sharing class Five9_TestEnv {
	private static final String FIVE9_TEST_USERNAME = 'BBSI-Five9-User';
	private static final String FIVE9_TEST_PASSWORD = 'InvalidPassword';

	public Account branch { get; private set; }
	public Account prospect { get; private set; }
	public Lead clientLead1 { get; private set; }
	public Lead clientLead2 { get; private set; }
	public Lead clientLead3 { get; private set; }
	public Contact contact1 { get; private set; }
	public User bdm { get; private set; }
	public Five9LSP__Five9_List__c five9ListLead1 { get; private set; }
	public Five9LSP__Five9_List__c five9ListLead2 { get; private set; }
	public Five9LSP__Five9_List__c five9ListAccount { get; private set; }

	/**
	 * @description createBase creates a base test environment.
	 */
	public void createBase() {
		branch = TestFactoryAccount.createBranch('!!!TEST BRANCH', '1000', null, null);
		bdm = TestFactoryUser.createBDM(null, 'TESTBDM', 'BBSI Standard', '1000');
		prospect = TestFactoryAccount.createProspect('!!!TEST PROSPECT', null, null);
		contact1 = TestFactoryContact.createClient(null, 'TESTCONTACT', prospect.Id);

		clientLead1 = TestFactoryLead.makeClientLead('Jake', 'TestLead1', '!!!COMPANY ONE', branch.id, bdm.Id);
		clientLead1.Status = 'Assigned';
		clientLead2 = TestFactoryLead.makeClientLead('Jane', 'TestLead2', '!!!COMPANY TWO', branch.id, bdm.Id);
		clientLead2.Status = 'Assigned';
		clientLead3 = TestFactoryLead.makeClientLead('Jane', 'TestLead3', '!!!COMPANY THREE', branch.id, bdm.Id);
		clientLead3.Status = 'Assigned';
		insert new List<Lead>{ clientLead1, clientLead2, clientLead3 };

		five9ListAccount = makeFive9List('TESTING Five9 Account', 'account');
		five9ListLead1 = makeFive9List('TESTING Five9 Lead ONE', 'lead');
		five9ListLead2 = makeFive9List('TESTING Five9 Lead TWO', 'lead');
		insert new List<Five9LSP__Five9_List__c>{ five9ListLead1, five9ListLead2, five9ListAccount };
	}

	/**
	 * @description loadBase reads the base test enviroment into object's variables.
	 */
	public void loadBase() {
		bdm = [SELECT Id, Name FROM User WHERE Name = 'TESTBDM'];

		List<Account> accounts = [SELECT Id, Name, External_Id__c FROM Account WHERE Name LIKE '!!!TEST %' ORDER BY Name ASC];
		branch = accounts[0];
		prospect = accounts[1];

		contact1 = [SELECT Id, Name FROM Contact WHERE LastName = 'TESTCONTACT'];

		List<Lead> leads = [SELECT Id, Name, Status, Five9_List_Name__c FROM Lead WHERE LastName LIKE 'TestLead%' ORDER BY LastName ASC];
		clientLead1 = leads[0];
		clientLead2 = leads[1];
		clientLead3 = leads[2];

		List<Five9LSP__Five9_List__c> f9lists = [SELECT Id, Name FROM Five9LSP__Five9_List__c WHERE Name LIKE 'TESTING Five9 %' ORDER BY Name ASC];
		five9ListAccount = f9lists[0];
		five9ListLead1 = f9lists[1];
		five9ListLead2 = f9lists[2];
	}

	/**
	 * @description makeFive9List creates a Five9LSP__Five9_List__c object.
	 * @param  name name  Name of the List
	 * @param  type type  Type of List (lead or account)
	 * @return Five9LSP__Five9_List__c
	 */
	public static Five9LSP__Five9_List__c makeFive9List(String name, String type) {
		return TestFactoryFive9List.makeFive9List(name, type);
	}

	/**
	 * @description makeFive9ListItem creates a Five9LSP__Five9_List_Item__c object.
	 * @param  idList  Identifier of the Five9 List
	 * @param  idItem  Identifier of the Object
	 * @param  status  Status of the Item
	 * @return Five9LSP__Five9_List_Item__c
	 */
	public static Five9LSP__Five9_List_Item__c makeFive9ListItem(Id idList, Id idItem, String status) {
		return TestFactoryFive9ListItem.makeFive9ListItem(idList, idItem, status);		
	}

	/**
	 * @description makeFive9ListAssignment create a Five9_List_Assignment__c record.
	 * @return Five9_List_Assignment__c
	 */
	public static Five9_List_Assignment__c makeFive9ListAssignment(Id idList, Id idLead, Id idAccount) {
		return TestFactoryFive9ListAssignment.makeFive9ListAssignment(idList, idLead, idAccount);
	}
}