/**
 * @description Five9ListAssignment_Test runs tests against the Five9ListAssignment object.
 */
@IsTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
public without sharing class Five9ListAssignment_Test {
	private static Five9_TestEnv environment = new Five9_TestEnv();
	private static Five9_List_Assignment__c assignment1A;
	private static Five9_List_Assignment__c assignment1B;
	private static Five9_List_Assignment__c assignment2A;

	@TestSetup
	static void makeData() {
		environment.createBase();

		assignment1A = TestFactoryFive9ListAssignment.makeFive9ListAssignment(
			environment.five9ListLead1.Id,
			environment.clientLead1.Id,
			null
		);
		assignment1B = TestFactoryFive9ListAssignment.makeFive9ListAssignment(
			environment.five9ListLead2.Id,
			environment.clientLead1.Id,
			null
		);
		assignment2A = TestFactoryFive9ListAssignment.makeFive9ListAssignment(
			environment.five9ListLead1.Id,
			environment.clientLead2.Id,
			null
		);
		insert new List<Five9_List_Assignment__c>{ assignment1A, assignment1B, assignment2A };
	}

	static void loadData() {
		environment.loadBase();

		List<Five9_List_Assignment__c> assigns = [
			SELECT
				Id,
				Account__c,
				Five9_List__c,
				Lead__c,
				Opportunity__c,
				Pipeline_Status__c,
				Pipeline_Date_Completed__c
			FROM Five9_List_Assignment__c
			ORDER BY Lead__c ASC
		];
		assignment1A = assigns[0];
		assignment1B = assigns[1];
		assignment2A = assigns[2];
	}

	@IsTest
	public static void test_getLeadAssignments() {
		loadData();

		Set<Id> idLeads = new Set<Id>{
			environment.clientLead1.Id,
			environment.clientLead2.Id,
			environment.clientLead3.Id
		};

		Test.startTest();

		List<Five9_List_Assignment__c> assignments = Five9ListAssignment.getAssignmentsFor(idLeads);

		Test.stopTest();

		Assert.areEqual(3, assignments.size(), '3 assignment: lead1 has 2 and lead2 has 1');
		Assert.areEqual(environment.clientLead1.Id, assignments[0].Lead__c, 'lead1 has 2 assignments');
		Assert.areEqual(environment.clientLead1.Id, assignments[1].Lead__c, 'lead1 has 2 assignments');
		Assert.areEqual(environment.clientLead2.Id, assignments[2].Lead__c, 'lead2 has 1 assignments');
	}

	@IsTest
	public static void test_updateConvertedLeads() {
		loadData();

		Account account1;
		Account account2;
		Account account3;
		Opportunity opp1;
		Opportunity opp2;
		Opportunity opp3;
		Lead leadOne;
		Lead leadTwo;
		Lead leadThree;

		Test.startTest();
		User user = TestFactoryUser.createUser('TEST', 'USER', 'System Administrator', environment.branch.External_Id__c);

		System.runAs(user) {
			account1 = TestFactoryAccount.makeClient('!!!TEST 1', null, null);
			account2 = TestFactoryAccount.makeClient('!!!TEST 2', null, null);
			account3 = TestFactoryAccount.makeClient('!!!TEST 3', null, null);
			insert new List<Account>{ account1, account2, account3 };
			Date tomorrow = Date.today().addDays(1);
			opp1 = TestFactoryOpportunity.makeClient('!!! TEST1', account1.Id, tomorrow, 'Open');
			opp2 = TestFactoryOpportunity.makeClient('!!! TEST2', account2.Id, tomorrow, 'Open');
			opp3 = TestFactoryOpportunity.makeClient('!!! TEST3', account3.Id, tomorrow, 'Open');
			insert new List<Opportunity>{ opp1, opp2, opp3 };

			leadOne = new Lead(
				Id = environment.clientLead1.Id,
				ConvertedAccountId = account1.Id,
				ConvertedOpportunityId = opp1.Id
			);

			leadTwo = new Lead(
				Id = environment.clientLead1.Id,
				ConvertedAccountId = account2.Id,
				ConvertedOpportunityId = opp2.Id
			);

			leadThree = new Lead(
				Id = environment.clientLead1.Id,
				ConvertedAccountId = account3.Id,
				ConvertedOpportunityId = opp3.Id
			);
		}

		Map<Id, Lead> mapLeads = new Map<Id, Lead>();
		mapLeads.put(environment.clientLead1.Id, leadOne);
		mapLeads.put(environment.clientLead2.Id, leadTwo);
		mapLeads.put(environment.clientLead3.Id, leadThree);

		Five9ListAssignment.updateConvertedLeads(null, mapLeads);
		Test.stopTest();

		Set<Id> idLeads = new Set<Id>{
			environment.clientLead1.Id,
			environment.clientLead2.Id,
			environment.clientLead3.Id
		};
		List<Five9_List_Assignment__c> assignments = Five9ListAssignment.getAssignmentsFor(idLeads);

		Assert.areEqual(3, assignments.size(), '3 assignment: lead1 has 2 and lead2 has 1');
		Assert.areEqual(account1.Id, assignments[0].Account__c, 'lead1 Account');
		Assert.areEqual(opp1.Id, assignments[0].Opportunity__c, 'lead1 Opportunity');
		Assert.areEqual(account1.Id, assignments[1].Account__c, 'lead1 Account');
		Assert.areEqual(opp1.Id, assignments[1].Opportunity__c, 'lead1 Opportunity');
		Assert.areEqual(account2.Id, assignments[2].Account__c, 'lead2 Account');
		Assert.areEqual(opp2.Id, assignments[2].Opportunity__c, 'lead2 Opportunity');
	}

	@IsTest
	public static void test_updatePipelineStatus_Lead() {
		loadData();

		environment.clientLead1.Status = 'Unqualified';

		Map<Id, Lead> mapLeads = new Map<Id, Lead>();
		mapLeads.put(environment.clientLead1.Id, environment.clientLead1);
		mapLeads.put(environment.clientLead2.Id, environment.clientLead2);

		Test.startTest();
		Five9ListAssignment.updatePipelineStatus(null, mapLeads);
		Test.stopTest();

		List<Five9_List_Assignment__c> assignments = Five9ListAssignment.getAssignmentsFor(mapLeads.keySet());
		Assert.areEqual(3, assignments.size(), ' lead1 has 2 assignments');
		Assert.areEqual('Complete', assignments[0].Pipeline_Status__c);
		Assert.areNotEqual(null, assignments[0].Pipeline_Date_Completed__c);
		Assert.areEqual('Complete', assignments[1].Pipeline_Status__c);
		Assert.areNotEqual(null, assignments[1].Pipeline_Date_Completed__c);
		Assert.areEqual('Active', assignments[2].Pipeline_Status__c);
		Assert.areEqual(null, assignments[2].Pipeline_Date_Completed__c);
	}

	@IsTest
	public static void test_updatePipelineStatus_Opportunity() {
		loadData();

		Test.startTest();
		
        Account account1 = TestFactoryAccount.makeClient('!!!TEST 1', null,null);
        Account account2 = TestFactoryAccount.makeClient('!!!TEST 2', null,null);
        Account account3 = TestFactoryAccount.makeClient('!!!TEST 3', null,null);
		insert new List<Account>{ account1, account2, account3 };

		Date tomorrow = Date.today().addDays(1);
        Opportunity opp1 = TestFactoryOpportunity.makeClient('!!! TEST1', account1.Id, tomorrow, 'Open');
        Opportunity opp2 = TestFactoryOpportunity.makeClient('!!! TEST2', account2.Id, tomorrow, 'Open');
		Opportunity opp3 = TestFactoryOpportunity.makeClient('!!! TEST3', account3.Id, tomorrow, 'Open');
        insert new List<Opportunity>{ opp1, opp2, opp3 };

		assignment1A.Account__c = account1.Id;
		assignment1A.Opportunity__c = opp1.Id;
		assignment1B.Account__c = account1.Id;
		assignment1B.Opportunity__c = opp1.Id;
		assignment2A.Account__c = account2.Id;
		assignment2A.Opportunity__c = opp2.Id;

		update new List<Five9_List_Assignment__c>{ assignment1A, assignment1B, assignment2A };

		Map<Id, Opportunity> oldOpps = new Map<Id, Opportunity>();
		oldOpps.put(opp1.Id, new Opportunity(Id = opp1.Id, StageName = 'Open'));
		oldOpps.put(opp1.Id, new Opportunity(Id = opp2.Id, StageName = 'Open'));

		opp1.StageName = 'Closed Lost';
		Map<Id, Opportunity> newOpps = new Map<Id, Opportunity>();
		newOpps.put(opp1.Id, opp1);
		newOpps.put(opp2.Id, opp2);

		Five9ListAssignment.updatePipelineStatus(oldOpps, newOpps);

		Test.stopTest();

		List<Five9_List_Assignment__c> assignments = Five9ListAssignment.getAssignmentsFor(newOpps.keySet());
		Assert.areEqual(3, assignments.size());
		Assert.areEqual('Complete', assignments[0].Pipeline_Status__c);
		Assert.areNotEqual(null, assignments[0].Pipeline_Date_Completed__c);
		Assert.areEqual('Complete', assignments[1].Pipeline_Status__c);
		Assert.areNotEqual(null, assignments[1].Pipeline_Date_Completed__c);
		Assert.areEqual('Active', assignments[2].Pipeline_Status__c);
		Assert.areEqual(null, assignments[2].Pipeline_Date_Completed__c);
	}

	@IsTest
	public static void test_setIncludedInOtherLists() {
		loadData();

        Account account2 = TestFactoryAccount.makeClient('!!!TEST 2', null,null);

		Date tomorrow = Date.today().addDays(1);
		Opportunity opp2 = TestFactoryOpportunity.makeClient('!!! TEST2', account2.Id, tomorrow, 'Open');
		assignment2A.Account__c = account2.Id;
		assignment2A.Opportunity__c = opp2.Id;
		update assignment2A;

		Test.startTest();
		Set<Id> ids = new Set<Id>();

		ids.add(environment.clientLead1.Id);
		ids.add(environment.clientLead3.Id);
		ids.add(account2.Id);

		Five9ListAssignment.setIncludedInOtherLists(ids);
		Test.stopTest();

		List<Five9_List_Assignment__c> assignments = Five9ListAssignment.getAssignmentsFor(ids);
		Assert.areEqual(3, assignments.size());
		Assert.areEqual(true, assignments[0].Included_on_Other_Five9_Lists__c);
		Assert.areEqual(true, assignments[1].Included_on_Other_Five9_Lists__c);
		Assert.areEqual(false, assignments[2].Included_on_Other_Five9_Lists__c);
	}

	@IsTest
	public static void test_getFive9CompletedCalls() {
		loadData();		
		Task task1 = TestFactoryTask.makeTask(null,new Map<String, Object>{
			'Type' => 'Call',
			 'Status' => 'Completed',
			 'Five9_List__c' => environment.five9ListLead1.Id   
			});
		Task task2 = TestFactoryTask.makeTask(null,new Map<String, Object>{
			'Type' => 'Meeting',
			 'Status' => 'Completed',
			 'Five9_List__c' => environment.five9ListLead2.Id   
			});
		Task task3 = TestFactoryTask.makeTask(null,new Map<String, Object>{
			'Type' => 'Call',
			 'Status' => 'Completed'
			});
		Task task4 = TestFactoryTask.makeTask(null,new Map<String, Object>{
			'Type' => 'Call',
			 'Status' => 'Not Started',
			 'Five9_List__c' => environment.five9ListLead1.Id  
			});
		List<Task> tasks = new List<Task>{ task1, task2, task3, task4 };

		List<Task> validTasks = Five9ListAssignment.getFive9CompletedCalls(tasks);
		Assert.areEqual(1, validTasks.size());
		Assert.areEqual(task1, validTasks[0]);
	}

	@IsTest
	public static void test_isTaskForAssign() {
		loadData();

		Task task1 = Task_Service.createTaskCompleted(
			'Call',
			environment.clientLead1.Id,
			(Id) null,
			environment.bdm.Id,
			'Call Lead',
			'AAA'
		);

		task1.CallDisposition = 'CALL COMPETED';
		task1.Five9_List__c = environment.five9ListLead1.Id;

		Task task2 = Task_Service.createTask(
			'Call',
			environment.clientLead1.Id,
			(Id) null,
			environment.bdm.Id,
			'Call Lead',
			'BBB',
			Date.today()
		);

		TriggerHandlerInvoker.blockTriggers();
		insert new List<Task>{ task1, task2 };

		Test.startTest();

		List<Task> tasks = [
			SELECT Type, Status, IsClosed, CompletedDateTime, WhoId, WhatId, OwnerId, CallDisposition, Five9_List__c
			FROM Task
			WHERE Id = :task1.Id OR Id = :task2.Id
			ORDER BY Five9_List__c ASC NULLS LAST
		];
		task1 = tasks[0];
		task2 = tasks[1];
		TriggerHandlerInvoker.unblockTriggers();

		Assert.areEqual('Completed', task1.Status);
		Assert.areEqual(true, task1.IsClosed);
		Assert.areNotEqual(null, task1.CompletedDateTime);

		Five9_List_Assignment__c assign = TestFactoryFive9ListAssignment.makeFive9ListAssignment(
			environment.five9ListLead1.Id,
			environment.clientLead1.Id,
			null
		);		

		Test.stopTest();

		Assert.areEqual(true, Five9ListAssignment.isTaskForAssign(task1, assign, null));
		Assert.areEqual(false, Five9ListAssignment.isTaskForAssign(task2, assign, null));
	}

	@IsTest
	public static void test_updateAssignmentsFromTasks() {
		loadData();

		Task task1 = Task_Service.createTaskCompleted(
			'Call',
			environment.clientLead1.Id,
			(Id) null,
			environment.bdm.Id,
			'Call Lead',
			'AAA'
		);

		task1.CallDisposition = 'CALL COMPETED';
		task1.Five9_List__c = environment.five9ListLead1.Id;

		Task task2 = Task_Service.createTask(
			'Call',
			environment.clientLead1.Id,
			(Id) null,
			environment.bdm.Id,
			'Call Lead',
			'BBB',
			Date.today()
		);

		TriggerHandlerInvoker.blockTriggers();
		insert new List<Task>{ task1, task2 };

		Test.startTest();

		List<Task> tasks = [
			SELECT Type, Status, IsClosed, CompletedDateTime, WhoId, WhatId, OwnerId, CallDisposition, Five9_List__c
			FROM Task
			WHERE Id = :task1.Id OR Id = :task2.Id
			ORDER BY Five9_List__c ASC NULLS LAST
		];
		task1 = tasks[0];
		task2 = tasks[1];
		TriggerHandlerInvoker.unblockTriggers();

		Assert.areEqual('Completed', task1.Status);
		Assert.areEqual(true, task1.IsClosed);
		Assert.areNotEqual(null, task1.CompletedDateTime);

		Five9_List_Assignment__c assign1 = TestFactoryFive9ListAssignment.makeFive9ListAssignment(
			environment.five9ListLead1.Id,
			environment.clientLead1.Id,
			null
		);
		Five9_List_Assignment__c assign2 = TestFactoryFive9ListAssignment.makeFive9ListAssignment(
			environment.five9ListLead2.Id,
			environment.clientLead1.Id,
			null
		);

		Test.stopTest();

		List<Five9_List_Assignment__c> assigneds = Five9ListAssignment.updateAssignmentsFromTasks(
			new List<Five9_List_Assignment__c>{ assign1, assign2 },
			new List<Task>{ task1, task2 },
			new Map<Id, String>{
				environment.clientLead1.Id => 'Jake TestLead1',
				environment.clientlead2.Id => 'Jane TestLead2',
				null => ''
			}
		);

		Assert.areEqual(1, assigneds.size());
		Five9_List_Assignment__c assigned = assigneds[0];
		Assert.areEqual(task1.CompletedDateTime.date(), assigned.Last_Call_Date__c);
		Assert.areEqual(task1.OwnerId, assigned.Last_Call_Center_Agent__c);
		Assert.areEqual(task1.CallDisposition, assigned.Last_Call_Result__c);
		Assert.areEqual('Jake TestLead1', assigned.Last_Contact__c);
	}

	@IsTest
	public static void test_getWhoNames() {
		loadData();

        Task task1 = TestFactoryTask.makeTask(null,new Map<String, Object>{
        'Type' => 'Call',
         'Status' => 'Completed',
         'WhoId' => environment.clientLead1.Id   
   		 });
        Task task2 = TestFactoryTask.makeTask(null,new Map<String, Object>{
        'Type' => 'Meeting',
         'Status' => 'Completed',
         'WhoId' => environment.clientLead2.Id   
    	});
		Task task3 = TestFactoryTask.makeTask(null,new Map<String, Object>{
        'Type' => 'Call',
         'Status' => 'Completed',
         'WhoId' => null   
   		 });
        Task task4 = TestFactoryTask.makeTask(null,new Map<String, Object>{
        'Type' => 'Call',
         'Status' => 'Not Started',
         'WhoId' => environment.clientLead1.Id   
    	});
         Task task5 = TestFactoryTask.makeTask(null,new Map<String, Object>{
        'Type' => 'Call',
         'Status' => 'Not Started',
         'WhoId' => environment.contact1.Id   
    	});
		List<Task> tasks = new List<Task>{ task1, task2, task3, task4, task5 };
		Map<Id, String> mapWhoToName = Five9ListAssignment.getWhoNames(tasks);

		Assert.areEqual(4, mapWhoToName.size());
		Assert.areEqual('TESTCONTACT', mapWhoToName.get(environment.contact1.Id));
		Assert.areEqual('Jake TestLead1', mapWhoToName.get(environment.clientLead1.Id));
		Assert.areEqual('Jane TestLead2', mapWhoToName.get(environment.clientLead2.Id));
		Assert.areEqual('', mapWhoToName.get(null));
	}

	@IsTest
	@SuppressWarnings('PMD.LocalVariableNamingconventions')
	public static void test_matchItem() {
		loadData();

		Five9LSP__Five9_List_Item__c itemLead1_1 = TestFactoryFive9ListItem.makeFive9ListItem(
			environment.five9ListLead1.Id,
			environment.clientLead1.Id,
			'Active'
		);
		Five9LSP__Five9_List_Item__c itemLead2_1 = TestFactoryFive9ListItem.makeFive9ListItem(
			environment.five9ListLead1.Id,
			environment.clientLead2.Id,
			'Active'
		);
		Five9LSP__Five9_List_Item__c itemLead2_2 = TestFactoryFive9ListItem.makeFive9ListItem(
			environment.five9ListLead2.Id,
			environment.clientLead2.Id,
			'Active'
		);
		Five9LSP__Five9_List_Item__c itemProspect = TestFactoryFive9ListItem.makeFive9ListItem(
			environment.five9ListAccount.Id,
			environment.prospect.Id,
			'Active'
		);

		Five9_List_Assignment__c assign;

		// Lead and Account do not match 1
		assign = TestFactoryFive9ListAssignment.makeFive9ListAssignment(environment.five9ListLead1.Id, null, null);
		Assert.isFalse(Five9ListAssignment.matchItem(assign, itemLead1_1));

		// Lead and Account do not match 2
		assign = TestFactoryFive9ListAssignment.makeFive9ListAssignment(environment.five9ListLead2.Id, environment.clientLead1.Id, environment.prospect.Id);
		Assert.isFalse(Five9ListAssignment.matchItem(assign, itemLead2_2));

		// List matches and Lead matches
		assign = TestFactoryFive9ListAssignment.makeFive9ListAssignment(environment.five9ListLead1.Id, environment.clientLead1.Id, null);
		Assert.isTrue(Five9ListAssignment.matchItem(assign, itemLead1_1));

		// List does not match but Lead match
		assign = TestFactoryFive9ListAssignment.makeFive9ListAssignment(environment.five9ListLead1.Id, environment.clientLead1.Id, null);
		Assert.isFalse(Five9ListAssignment.matchItem(assign, itemLead2_1));

		// List and Account Match
		assign = TestFactoryFive9ListAssignment.makeFive9ListAssignment(environment.five9ListAccount.Id, null, environment.prospect.Id);
		Assert.isTrue(Five9ListAssignment.matchItem(assign, itemProspect));
	}

	@IsTest
	public static void test_updateTaskFields() {
		loadData();

        Task task1 = TestFactoryTask.makeTask(null,new Map<String, Object>{
			'Type' => 'Call',
			'Status' => 'Completed',
			'WhoId' => environment.clientLead1.Id,
			'Five9Campaign__c' => 'abc'
   		 });
        Task task2 = TestFactoryTask.makeTask(null,new Map<String, Object>{
			'Type' => 'Meeting',
			'Status' => 'Completed',
			'WhoId' => environment.contact1.Id,
			'Five9Campaign__c' => 'abc'
    	});

		List<Task> tasks = new List<Task>{ task1, task2 };
		Test.startTest();
		insert tasks;
		Map<Id, Task> oldTasks = new Map<Id, Task>([select Id, Type, Status, WhoId, Five9Campaign__c, Five9_List__c, CompletedDateTime from Task order by createddate desc limit 4]);
		for(Task t : tasks) {
			t.Five9Campaign__c = 'testing';
			t.Five9_List__c = environment.five9ListLead1.Id;   
		}
		Five9ListAssignment.updateTaskFields(null, tasks);
		Five9ListAssignment.updateAssignments(oldTasks.values());
		Five9LSP__Five9_List_Item__c itemLead1_1 = TestFactoryFive9ListItem.makeFive9ListItem(
			environment.five9ListLead1.Id,
			environment.clientLead1.Id,
			'Active'
		);
		Five9LSP__Five9_List_Item__c itemLead2_1 = TestFactoryFive9ListItem.makeFive9ListItem(
			environment.five9ListLead1.Id,
			environment.clientLead2.Id,
			'Active'
		);
		Five9LSP__Five9_List_Item__c itemLead2_2 = TestFactoryFive9ListItem.makeFive9ListItem(
			environment.five9ListLead2.Id,
			environment.clientLead2.Id,
			'Active'
		);
		Five9LSP__Five9_List_Item__c itemProspect = TestFactoryFive9ListItem.makeFive9ListItem(
			environment.five9ListAccount.Id,
			environment.prospect.Id,
			'Active'
		);
		List<Five9LSP__Five9_List_Item__c> Five9ListItems = new List<Five9LSP__Five9_List_Item__c>{ 
			itemLead1_1,
			itemLead2_1,
			itemLead2_2,
			itemProspect
		};
		Five9ListAssignment.markInactive(Five9ListItems);
		Five9ListAssignment.createAssignment(environment.five9ListLead1.Id, environment.clientLead1.Id, environment.prospect.Id, null);
		Test.stopTest();
	}
}