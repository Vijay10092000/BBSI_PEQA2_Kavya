/**
 * @description Five9ListItem_Service contains routines to handle changes to Five9LSP__Five9_List_Item__c objects.
 */
public without sharing class Five9ListItem_Service {
	/* FUTURE: Delete with User Story 65240 Remove Five9 managed package/code/etc
	// This code is blocked by the trigger being inactive.  Also see Five9ListItem_TriggerHandler.

	/ **
	 * @description checkObjectChange description
	 * @param  mapOld  mapOld description
	 * @param  listNew listNew description
	 * /
	public static void checkObjectChange(
		Map<Id, Five9LSP__Five9_List_Item__c> mapOld,
		List<Five9LSP__Five9_List_Item__c> listNew
	) {
		if (mapOld != null) {
			for (Five9LSP__Five9_List_Item__c item : listNew) {
				if (item.Five9LSP__Lead__c != null && item.Five9LSP__Lead__c != mapOld.get(item.Id).Five9LSP__Lead__c) {
					item.Five9LSP__Lead__c.addError('Do not change the related Lead.');
				}
				if (
					item.Five9LSP__Account__c != null &&
					item.Five9LSP__Account__c != mapOld.get(item.Id).Five9LSP__Account__c
				) {
					item.Five9LSP__Account__c.addError('Do not change the related Account.');
				}
			}
		}
	}

	/ **
	 * @description setRelatedObjects updates related objects Five9 Lists.
	 * @param  listNew List of new Five9LSP__Five9_List_Item__cs
	 * /
	public static void setRelatedObjects(List<Five9LSP__Five9_List_Item__c> listNew) {
		Map<Id, Account> updateAccounts = new Map<Id, Account>();
		Map<Id, Lead> updateLeads = new Map<Id, Lead>();

		Map<Id, Sobject> mapRecords = getRecords(listNew);

		for (Five9LSP__Five9_List_Item__c item : listNew) {
			if (mapRecords.containsKey(item.Five9LSP__Account__c)) {
				Account account = (Account) mapRecords.get(item.Five9LSP__Account__c);

				if (account.Five9_List_Name__c != item.Five9LSP__Five9_List__c) {
					account.Five9_List_Name__c = item.Five9LSP__Five9_List__c;
					account.Five9_List_Source__c = item.Five9LSP__Five9_List__c;
					updateAccounts.put(account.Id, account);
				}
			}

			if (mapRecords.containsKey(item.Five9LSP__Lead__c)) {
				Lead lead = (Lead) mapRecords.get(item.Five9LSP__Lead__c);

				if (lead.Five9_List_Name__c != item.Five9LSP__Five9_List__c) {
					lead.Five9_List_Name__c = item.Five9LSP__Five9_List__c;
					updateLeads.put(lead.Id, lead);
				}
			}
		}

		List<Database.SaveResult> results;

		results = Database.update(updateAccounts.values());
		Log.writeIfError('Five9 Lists', 'Error updating Account Five9 Lists', 'Changing Five9 List', results);
		results = Database.update(updateLeads.values());
		Log.writeIfError('Five9 Lists', 'Error updating Lead Five9 Lists', 'Changing Five9 List', results);
	}

	/ **
	 * @description clearRelatedObjects clears related objects Five9 Lists.
	 * @param  listOld List of removed Five9LSP__Five9_List_Item__cs
	 * /
	public static void clearRelatedObjects(List<Five9LSP__Five9_List_Item__c> listOld) {
		Map<Id, Sobject> updates = new Map<Id, Sobject>();

		Map<Id, Sobject> mapRecords = getRecords(listOld);

		for (Five9LSP__Five9_List_Item__c item : listOld) {
			if (mapRecords.containsKey(item.Five9LSP__Account__c)) {
				Account account = (Account) mapRecords.get(item.Five9LSP__Account__c);

				if (account.Five9_List_Name__c != null) {
					account.Five9_List_Name__c = null;
					account.Five9_List_Source__c = null;
					updates.put(account.Id, account);
				}
			}

			if (mapRecords.containsKey(item.Five9LSP__Lead__c)) {
				Lead lead = (Lead) mapRecords.get(item.Five9LSP__Lead__c);

				if (lead.Five9_List_Name__c != null) {
					lead.Five9_List_Name__c = null;
					updates.put(lead.Id, lead);
				}
			}
		}

		List<Database.SaveResult> results = Database.update(updates.values());
		Log.writeIfError('Five9 Lists', 'Error updating Five9 List', 'Changing Five9 List', results);
	}

	/ **
	 * @description createFive9Assignment creates Lead or Account to the Five9 List Assigments.
	 * @param  listNew List of new Five9LSP__Five9_List_Item__cs
	 * /
	public static void createFive9Assignment(List<Five9LSP__Five9_List_Item__c> listNew) {
		Set<String> listEncoded = getNewEncoded(listNew);
		Map<Id, Id> mapIdObjectstoList = new Map<Id, Id>();

		for (String coded : listEncoded) {
			List<String> args = decode(coded);

			if (args[2] != null) {
				mapIdObjectstoList.put(args[2], args[0]);
			}
			if (args[1] != null) {
				mapIdObjectstoList.put(args[1], args[0]);
			}
		}

		Map<Id, Map<String, Id>> accountData = getAssignmentData(mapIdObjectstoList);

		List<Five9_List_Assignment__c> listCreate = new List<Five9_List_Assignment__c>();

		for (Map<String, Id> params : accountData.values()) {
			listCreate.add(
				Five9ListAssignment.createAssignment(
					params.get('Five9List'),
					params.get('Lead'),
					params.get('Account'),
					params.get('Opportunity')
				)
			);
		}

		insert listCreate;
	}

	/ **
	 * @description getRecords retrieves the related object to the Five9LSP__Five9_List_Item__cs.
	 * @param  listRecords List of Five9LSP__Five9_List_Item__cs
	 * @return Map relating Five9LSP__Five9_List_Item__c to the object.
	 * /
	@TestVisible
	private static Map<Id, Sobject> getRecords(List<Five9LSP__Five9_List_Item__c> listRecords) {
		Map<Id, Sobject> result = new Map<Id, Sobject>();

		Set<Id> idAccounts = new Set<Id>();
		Set<Id> idLeads = new Set<Id>();

		for (Five9LSP__Five9_List_Item__c item : listRecords) {
			if (item.Five9LSP__Account__c != null) {
				idAccounts.add(item.Five9LSP__Account__c);
			}

			if (item.Five9LSP__Lead__c != null) {
				idLeads.add(item.Five9LSP__Lead__c);
			}
		}

		if (!idAccounts.isEmpty()) {
			for (Account account : [SELECT Id, Name, Five9_List_Name__c FROM Account WHERE Id IN :idAccounts]) {
				result.put(account.Id, account);
			}
		}

		if (!idLeads.isEmpty()) {
			for (Lead lead : [SELECT Id, Name, Five9_List_Name__c FROM Lead WHERE Id IN :idLeads]) {
				result.put(lead.Id, lead);
			}
		}

		return result;
	}

	/ **
	 * @description encode encodes the given values into a single string.
	 * @param  idList     Five9_List__c identifier
	 * @param  idLead     Lead identifier
	 * @param  idAccount  Account  identifier
	 * @return String
	 * /
	@TestVisible
	private static String encode(String idList, String idLead, String idAccount) {
		return String.format(
			'List:{0}!Lead:{1}!Account:{2}',
			new List<String>{
				(String.isBlank(idList)) ? '' : idList,
				(String.isBlank(idLead)) ? '' : idLead,
				(String.isBlank(idAccount)) ? '' :idAccount
			}
		);
	}

	/ **
	 * @description decode dencodes the given string.
	 * @param  code  Encoded string
	 * @return List<String>
	 * /
	@TestVisible
	private static List<String> decode(String code) {
		List<String> result = code.split('!');

		result[0] = result[0].removeStart('List:');
		result[1] = result[1].removeStart('Lead:');
		result[2] = result[2].removeStart('Account:');

		if (String.isBlank(result[0])) {
			result[0] = null;
		}
		if (String.isBlank(result[1])) {
			result[1] = null;
		}
		if (String.isBlank(result[2])) {
			result[2] = null;
		}

		return result;
	}

	/ **
	 * @description getNewEncoded determine which items need Five9_List_Assignment__c.
	 * @param  listNew  Five9LSP__Five9_List_Item__c looking at
	 * @return Set<String> of encoded Strings
	 * /
	private static Set<String> getNewEncoded(List<Five9LSP__Five9_List_Item__c> listNew) {
		Set<Id> idItems = new Set<Id>();
		Set<Id> idObjects = new Set<Id>();
		Set<String> result = new Set<String>();

		for (Five9LSP__Five9_List_Item__c item : listNew) {
			if (item.Five9LSP__Account__c != null) {
				idObjects.add(item.Five9LSP__Account__c);
			} else if (item.Five9LSP__Lead__c != null) {
				idObjects.add(item.Five9LSP__Lead__c);
			}

			idItems.add(item.Five9LSP__Five9_List__c);
			result.add( encode(item.Five9LSP__Five9_List__c, item.Five9LSP__Lead__c, item.Five9LSP__Account__c) );
		}

		for (Five9_List_Assignment__c assignment : [
			SELECT Id, Account__c, Lead__c
			FROM Five9_List_Assignment__c
			WHERE Five9_List__c IN :idItems AND (Account__c IN :idObjects OR Lead__c IN :idObjects)
		]) {
			String coded = encode(assignment.Id, assignment.Lead__c, assignment.Account__c);

			if (result.contains(coded)) {
				result.remove(coded);
			}
		}

		return result;
	}

	/ **
	 * @description getAssignmentData retrieve related Lead and Opportunity for each of the Account Ids
	 * and build the data for a Five9 List Assignment record.
	 * @param  idObjects  Map of Lead and Account identifiers related to their Five9 List
	 * @return Map<Id, Map<String, Id>>
	 * /
	private static Map<Id, Map<String, Id>> getAssignmentData(Map<Id, Id> idObjects) {
		Map<Id, Map<String, Id>> result = new Map<Id, Map<String, Id>> ();
		String leadId3 = Sobject_Services.getIdPrefix('Lead');
		String accountId3 = Sobject_Services.getIdPrefix('Account');

		if (!idObjects.isEmpty()) {
			for (Id idObj : idObjects.keySet()) {
				result.put(idObj, new Map<String, Id>());
				result.get(idObj).put('Lead', ((String) idObj).startsWith(leadId3) ? idObj : null);
				result.get(idObj).put('Account', ((String) idObj).startsWith(accountId3) ? idObj : null);
				result.get(idObj).put('Opportunity', null);
				result.get(idObj).put('Five9List', idObjects.get(idObj));
			}

			for (Lead lead : [SELECT Id, ConvertedAccountId FROM Lead WHERE ConvertedAccountId IN :idObjects.keySet()]) {
				result.get(lead.ConvertedAccountId).put('Lead', lead.Id);
			}

			for (Opportunity opp : [
				SELECT Id, AccountId
				FROM Opportunity
				WHERE RecordType.Name = 'Client' AND AccountId IN :idObjects.keySet()
			]) {
				result.get(opp.AccountId).put('Opportunity', opp.Id);
			}
		}

		return result;
	}
	*/
}