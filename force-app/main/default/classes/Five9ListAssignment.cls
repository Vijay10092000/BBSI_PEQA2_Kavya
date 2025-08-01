/**
 * @description Five9ListAssignment handles the Five9 List Assignment object.
 */
public without sharing class Five9ListAssignment {
	/**
	 * @description updateConvertedLeads updates the related Five9ListAssignment__c records
	 * to the recently converted Leads.
	 * @param  oldLeads       Leads before changes
	 * @param  convertedLeads Leads with changes
	 */
	public static void updateConvertedLeads(Map<Id, Lead> oldLeads, Map<Id, Lead> convertedLeads) {
		List<Five9_List_Assignment__c> assignments = getAssignmentsFor(convertedLeads.keySet());
		Lead lead;

		for (Five9_List_Assignment__c assignment : assignments) {
			lead = convertedLeads.get(assignment.Lead__c);

			assignment.Account__c = lead.ConvertedAccountId;
			assignment.Opportunity__c = lead.ConvertedOpportunityId;
		}

		update (assignments);
	}

	/**
	 * @description updatePipelineStatus updates the related Five9ListAssignment__c records
	 * to the recently converted Leads.
	 * @param  oldLeads  Leads before changes
	 * @param  newLeads  Leads with changes
	 */
	public static void updatePipelineStatus(Map<Id, Lead> oldLeads, Map<Id, Lead> newLeads) {
		Map<Id, Lead> updateLeads = new Map<Id, Lead>();

		for (Lead lead : newLeads.values()) {
			if (lead.Status == 'Qualified') {
				if (oldLeads == null || oldLeads.get(lead.Id).Status != 'Qualified') {
					updateLeads.put(lead.Id, lead);
				}
			}

			if (lead.Status == 'Unqualified') {
				if (oldLeads == null || oldLeads.get(lead.Id).Status != 'Unqualified') {
					updateLeads.put(lead.Id, lead);
				}
			}
		}

		if (!updateLeads.isEmpty()) {
			setPipelineComplete(getAssignmentsFor(updateLeads.keySet()));
		}
	}

	/**
	 * @description updatePipelineStatus updates the related Five9ListAssignment__c records
	 * to the recently closed Opportunities.
	 * @param  oldOpps  Opportuntys before changes
	 * @param  newOpps  Opportuntys with changes
	 */
	public static void updatePipelineStatus(Map<Id, Opportunity> oldOpps, Map<Id, Opportunity> newOpps) {
		Map<Id, Opportunity> unqualifiedOpps = new Map<Id, Opportunity>();

		for (Opportunity opp : newOpps.values()) {
			if (opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost') {
				if (
					oldOpps == null ||
					(oldOpps.get(opp.Id).StageName != 'Closed Won' &&
					oldOpps.get(opp.Id).StageName != 'Closed Lost')
				) {
					unqualifiedOpps.put(opp.Id, opp);
				}
			}
		}

		if (!unqualifiedOpps.isEmpty()) {
			setPipelineComplete(getAssignmentsFor(unqualifiedOpps.keySet()));
		}
	}

	/**
	 * @description updateMultipleLists updates Included_on_Other_Five9_Lists__c on the Five9ListAssignment__c records.
	 * Should only be called from AFTER Trigger methods.
	 * @param  assignments  Five9_List_Assignment__c to update
	 */
	public static void updateMultipleLists(List<Five9_List_Assignment__c> assignments) {
		Set<Id> ids = new Set<Id>();

		for (Five9_List_Assignment__c assign : assignments) {
			if (assign.Account__c != null) {
				ids.add(assign.Account__c);
			} else if (assign.Lead__c != null) {
				ids.add(assign.Lead__c);
			}
		}

		if (!ids.isEmpty()) {
			setIncludedInOtherLists(ids);
		}
	}

	/**
	 * @description updateTaskFields updates the Task Five9 Fields fields.
	 * @param  oldTasks  Tasks before changes
	 * @param  newTasks  Tasks with changes
	 */
	public static void updateTaskFields(Map<Id, Task> oldTasks, List<Task> newTasks) {
		List<Task> updateTasks = new List<Task>();
		Set<String> campaigns = new Set<String>();

		for (Task task : newTasks) {
			if (task.Five9Campaign__c != null) {
				if (oldTasks == null || task.Five9Campaign__c != oldTasks.get(task.Id).Five9Campaign__c) {
					updateTasks.add(task);
					campaigns.add(task.Five9Campaign__c);
				}
			}
		}

		if (!updateTasks.isEmpty()) {
			Map<String, Id> mapFive9NameToId = getListNames(campaigns);

			for (Task task : updateTasks) {
				if (mapFive9NameToId.containsKey(task.Five9Campaign__c)) {
					task.Five9_List__c = mapFive9NameToId.get(task.Five9Campaign__c);
				}
			}
		}
	}

	/**
	 * @description updateAssignments updates Five9ListAssignment__c Task fields.
	 * @param  tasks  List of Tasks
	 */
	public static void updateAssignments(List<Task> tasks) {
		List<Task> workTasks = getFive9CompletedCalls(tasks);

		if (!workTasks.isEmpty()) {
			List<Five9_List_Assignment__c> assigns = updateAssignmentsFromTasks(getRelatedAssigns(tasks), tasks, getWhoNames(tasks));

			if (!assigns.isEmpty()) {
				update assigns;
			}
		}
	}

	/**
	 * @description markInactive updates Five9ListAssignment__c based on being removed from a Five9 List.
	 * Call from Five9ListItem_TriggerHandler AFTER-DELETE.
	 * @param  items  Map of Items
	 */
	public static void markInactive(List<Five9LSP__Five9_List_Item__c> items) {
		List<Five9_List_Assignment__c> updateAssigns = new List<Five9_List_Assignment__c>();

		List<Id> idLeads = new List<Id>();
		List<Id> idAccounts = new List<Id>();
		List<Id> idLists = new List<Id>();

		for (Five9LSP__Five9_List_Item__c item : items) {
			if (item.Five9LSP__Five9_List__c != null) {
				idLists.add(item.Five9LSP__Five9_List__c);
			}
			if (item.Five9LSP__Lead__c != null) {
				idLeads.add(item.Five9LSP__Lead__c);
			}
			if (item.Five9LSP__Account__c != null) {
				idAccounts.add(item.Five9LSP__Account__c);
			}
		}

		for (Five9_List_Assignment__c assign : [
			SELECT Id, Account__c, Lead__c, Five9_List__c
			FROM Five9_List_Assignment__c
			WHERE Five9_List__c IN :idLists
			AND (Lead__c IN :idLeads OR Account__c IN :idAccounts)
			ORDER BY Five9_List__c
		]) {
			for (Five9LSP__Five9_List_Item__c item : items) {
				if (matchItem(assign, item)) {
					assign.Pipeline_Status__c = 'Complete';
					assign.Pipeline_Date_Completed__c = Date.today();
					updateAssigns.add(assign);
				}
			}
		}

		update updateAssigns;
	}

	/**
	 * @description matchItem description
	 * @param  assign assign description
	 * @param  item   item description
	 * @return        return description
	 */
	@TestVisible
	private static Boolean matchItem(Five9_List_Assignment__c assign, Five9LSP__Five9_List_Item__c item) {
		if (item.Five9LSP__Five9_List__c == assign.Five9_List__c) {
			if (item.Five9LSP__Lead__c != null) {
				if (item.Five9LSP__Lead__c == assign.Lead__c) {
					return true;
				}
			}

			if (item.Five9LSP__Account__c != null) {
				if (item.Five9LSP__Account__c == assign.Account__c) {
					return true;
				}
			}
		}

		return false;
	}

	/**
	 * @description setIncludedInOtherLists determine if Assginemnt is on multiple lists.
	 * @param  ids  Leads and Account identifiers to look for
	 */
	@TestVisible
	private static void setIncludedInOtherLists(Set<Id> ids) {
		List<Five9_List_Assignment__c> assignments = getAssignmentsFor(ids);
		Map<Id, List<Five9_List_Assignment__c>> mapAssignments = groupAssignments(assignments);
		List<Five9_List_Assignment__c> updateAssigns = setIncludeList(mapAssignments);

		if (!updateAssigns.isEmpty()) {
			update updateAssigns;
		}
	}

	/**
	 * @description getAssignmentsFor retrieves Five9 List Assignments related to the given identifiers.
	 * @param  ids  Set of identifiers (Lead, Account or Opportunity)
	 * @return List<Five9ListAssignment__c>
	 */
	public static List<Five9_List_Assignment__c> getAssignmentsFor(Set<Id> ids) {
		return [
			SELECT
				Id,
				Account__c,
				Five9_List__c,
				Included_on_Other_Five9_Lists__c,
				Lead__c,
				Opportunity__c,
				Pipeline_Status__c,
				Pipeline_Date_Completed__c
			FROM Five9_List_Assignment__c
			WHERE Lead__c IN :ids OR Account__c IN :ids OR Opportunity__c IN :ids
			ORDER BY Lead__c ASC, Account__c ASC
		];
	}

	/**
	 * @description createAssignment makes an Five9_List_Assignment__c object.
	 * @param  idFive9List    Five9 List connecting to
	 * @param  idLead         Related Lead
	 * @param  idAccount      Related Account
	 * @param  idOpportunity  Related Opportunity
	 * @return Five9_List_Assignment__c
	 */
	public static Five9_List_Assignment__c createAssignment(Id idFive9List, Id idLead, Id idAccount, Id idOpportunity) {
		return new Five9_List_Assignment__c(
			Five9_List__c = idFive9List,
			Lead__c = idLead,
			Account__c = idAccount,
			Opportunity__c = idOpportunity,
			Date_Added_to_Five9_List__c = Date.today()
		);
	}

	/**
	 * @description setPipelineComplete mark the given assignments to Compelete if not already.
	 * @param  assignments  List of Five9_List_Assignment__c
	 */
	private static void setPipelineComplete(List<Five9_List_Assignment__c> assignments) {
		List<Five9_List_Assignment__c> updateAssign = new List<Five9_List_Assignment__c>();

		Date today = Date.today();

		for (Five9_List_Assignment__c assignment : assignments) {
			if (assignment.Pipeline_Status__c != 'Complete') {
				assignment.Pipeline_Status__c = 'Complete';
				assignment.Pipeline_Date_Completed__c = today;

				updateAssign.add(assignment);
			}
		}

		update updateAssign;
	}

	/**
	 * @description groupAssignments creates a Map relating Account or Lead Id to the lists assigned.
	 * @param  assignments  List<Five9_List_Assignment__c>
	 * @return Map<Id, List<Five9_List_Assignment__c>>
	 */
	private static Map<Id, List<Five9_List_Assignment__c>> groupAssignments(
		List<Five9_List_Assignment__c> assignments
	) {
		Map<Id, List<Five9_List_Assignment__c>> result = new Map<Id, List<Five9_List_Assignment__c>>();

		for (Five9_List_Assignment__c assignment : assignments) {
			if (assignment.Account__c != null) {
				if (!result.containsKey(assignment.Account__c)) {
					result.put(assignment.Account__c, new List<Five9_List_Assignment__c>());
				}
				result.get(assignment.Account__c).add(assignment);
			} else if (assignment.Lead__c != null) {
				if (!result.containsKey(assignment.Lead__c)) {
					result.put(assignment.Lead__c, new List<Five9_List_Assignment__c>());
				}
				result.get(assignment.Lead__c).add(assignment);
			}
		}

		return result;
	}

	/**
	 * @description setIncludeList sets the Included_on_Other_Five9_Lists__c field on the assignment record
	 * if not aready set.  Adds the changed record to the return List.
	 * @param  mapAssignments  Map relating identifiers to a list of assignments
	 * @return List<Five9_List_Assignment__c>
	 */
	private static List<Five9_List_Assignment__c> setIncludeList(
		Map<Id, List<Five9_List_Assignment__c>> mapAssignments
	) {
		List<Five9_List_Assignment__c> result = new List<Five9_List_Assignment__c>();

		for (Id id : mapAssignments.keySet()) {
			Boolean hasMultiple = (1 < mapAssignments.get(id).size());

			for (Five9_List_Assignment__c assignment : mapAssignments.get(id)) {
				if (assignment.Included_on_Other_Five9_Lists__c != hasMultiple) {
					assignment.Included_on_Other_Five9_Lists__c = hasMultiple;
					result.add(assignment);
				}
			}
		}

		return result;
	}

	@TestVisible
	private static List<Task> getFive9CompletedCalls(List<Task> tasks) {
		List<Task> result = new List<Task>();

		for (Task task : tasks) {
			if (task.Five9_List__c != null) {
				if (task.Status == 'Completed') {
					if (task.Type == 'Call') {
						result.add(task);
					}
				}
			}
		}

		return result;
	}

	/**
	 * @description getRelatedAssigns retrieves assignments related to the given Tasks.
	 * @param  tasks  Tasks looking at
	 * @return List<Five9_List_Assignment__c>
	 */
	private static List<Five9_List_Assignment__c> getRelatedAssigns(List<Task> tasks) {
		List<Five9_List_Assignment__c> result = new List<Five9_List_Assignment__c>();
		List<Id> idLists = new List<Id>();
		List<Id> idWhats = new List<Id>();
		List<Id> idWhos = new List<Id>();

		for (Task task : tasks) {
			idLists.add(task.Five9_List__c);
			idWhats.add(task.WhatId);
			idWhos.add(task.WhoId);
		}

		if (!idLists.isEmpty()) {
			result = [
				SELECT
					Id,
					Account__c,
					Account__r.Name,
					Five9_List__c,
					Included_on_Other_Five9_Lists__c,
					Lead__c,
					Lead__r.Name,
					Last_Call_Date__c,
					Last_Call_Center_Agent__c,
					Last_Call_Result__c,
					Last_Contact__c,
					Opportunity__c,
					Pipeline_Date_Completed__c,
					Pipeline_Status__c,
					TaskId__c
				FROM Five9_List_Assignment__c
				WHERE Five9_List__c IN :idLists AND (Lead__c IN :idWhos OR Account__c IN :idWhats)
				ORDER BY Five9_List__c ASC
			];
		}

		return result;
	}

	/**
	 * @description updateAssignmentsFromTasks retrieves assignments updated by the Tasks.
	 * @param  assignments  Five9_List_Assignment__c checking
	 * @param  tasks        Tasks with Five9 List
	 * @return List<Five9_List_Assignment__c>
	 */
	@TestVisible
	private static List<Five9_List_Assignment__c> updateAssignmentsFromTasks(
		List<Five9_List_Assignment__c> assignments,
		List<Task> tasks,
		Map<Id, String> mapWhoToName
	) {
		List<Five9_List_Assignment__c> result = new List<Five9_List_Assignment__c>();

		for (Task task : tasks) {
			for (Five9_List_Assignment__c assignment : assignments) {
				if (isTaskForAssign(task, assignment, mapWhoToName.get(task.WhoId))) {
					assignment.TaskId__c = task.Id;
					assignment.Last_Call_Date__c = task.CompletedDateTime.date();
					assignment.Last_Call_Center_Agent__c = task.OwnerId;
					assignment.Last_Call_Result__c = task.CallDisposition;
					assignment.Last_Contact__c = mapWhoToName.get(task.WhoId);

					result.add(assignment);
				}
			}
		}

		return result;
	}

	/**
	 * @description isTaskForAssign determines if the given Task relates to the given assignment
	 * and the values have changed.
	 * @param  task    Task checking
	 * @param  assign  Five9ListAssignment__c checking
	 * @return true if the task relates to the assignment and is changed
	 */
	@TestVisible
	private static Boolean isTaskForAssign(Task task, Five9_List_Assignment__c assign, String taskWho) {
		if (assign.Five9_List__c == task.Five9_List__c) {
			Boolean match = false;

			match |= (assign.Lead__c != null && assign.Lead__c == task.WhoId);
			match |= (assign.Account__c != null && assign.Account__c == task.WhatId);

			if (match) {
				if (task.Id == assign.TaskId__c) {
					return assign.Last_Call_Date__c <= task.CompletedDateTime.date() ||
						assign.Last_Call_Center_Agent__c != task.OwnerId ||
						assign.Last_Call_Result__c != task.CallDisposition ||
						assign.Last_Contact__c != taskWho;
				} else {
					if (assign.Last_Call_Date__c == null || assign.Last_Call_Date__c <= task.CompletedDateTime.date()) {
						return true;
					}
				}
			}
		}

		return false;
	}

	/**
	 * @description getListNames creates a Map containing the Five9 List name
	 * to Five9 List Id.
	 * @param  names  Five9 List names looking for
	 * @return Map<String, Id>
	 */
	private static Map<String, Id> getListNames(Set<String> names) {
		Map<String, Id> result = new Map<String, Id>();

		for (Five9LSP__Five9_List__c f9 : [
			SELECT Id, Name
			FROM Five9LSP__Five9_List__c
			WHERE Name IN :names
			ORDER BY Name ASC
		]) {
			result.put(f9.Name, f9.Id);
		}

		return result;
	}

	/**
	 * @description getWhoNames retrieves Lead and Contacts names from the given tasks.
	 * @param  tasks  List of Tasks
	 * @return Map relating the WhoId to the name.
	 */
	@TestVisible
	private static Map<Id, String> getWhoNames(List<Task> tasks) {
		Map<Id, String> result = new Map<Id, String>();
		Set<Id> leads = new Set<Id>();
		Set<Id> contacts = new Set<Id>();

		for (Task task : tasks) {
			if (Id_Service.isType(task.WhoId, 'Lead')) {
				leads.add(task.WhoId);
			} else if (Id_Service.isType(task.WhoId, 'Contact')) {
				contacts.add(task.WhoId);
			}
			else {
				result.put(task.WhoId, '');
			}
		}

		if (!leads.isEmpty()) {
			for (Lead lead : [SELECT Id, Name FROM Lead WHERE Id IN :leads]) {
				result.put(lead.Id, lead.Name);
			}
		}

		if (!contacts.isEmpty()) {
			for (Contact contact : [SELECT Id, Name FROM Contact WHERE Id IN :contacts]) {
				result.put(contact.Id, contact.Name);
			}
		}
		return result;
	}
}