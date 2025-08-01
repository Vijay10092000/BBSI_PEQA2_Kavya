/**
 * @description TestFactoryFive9List contains methods to create test Five9Lists.
 */
@IsTest
public without sharing class TestFactoryFive9ListAssignment {

	/**
	 * @description createFive9List creates a new Five9List record in the database.
	 * @param  name     Name of the Five9List
	 * @param  type     Controlling Object name for the Five9List
	 * @return Five9List
	 */
	public static Five9_List_Assignment__c createFive9ListAssignment(Id idList, Id idLead, Id idAccount) {
		Five9_List_Assignment__c Five9ListAssignment = makeFive9ListAssignment(idList, idLead, idAccount);
		insert Five9ListAssignment;
		return Five9ListAssignment;
	}

	/**
	 * @description makeFive9ListAssignment create a Five9_List_Assignment__c record.
	 * @return Five9_List_Assignment__c
	 */
	public static Five9_List_Assignment__c makeFive9ListAssignment(Id idList, Id idLead, Id idAccount) {
		return new Five9_List_Assignment__c(
			Lead__c = idLead,
			Account__c = idAccount,
			Last_Call_Center_Agent__c = null,
			Last_Call_Date__c = null,
			Last_Call_Result__c = null,
			Last_Contact__c = null,
			Five9_List__c = idList
		);
	}    
}