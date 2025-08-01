/**
 * @description TestFactoryFive9List contains methods to create test Five9Lists.
 */
@IsTest
public without sharing class TestFactoryFive9List {
    private static final String FIVE9_TEST_USERNAME = 'BBSI-Five9-User';
	private static final String FIVE9_TEST_PASSWORD = 'InvalidPassword';
	/**
	 * @description createFive9List creates a new Five9List record in the database.
	 * @param  name     Name of the Five9List
	 * @param  type     Controlling Object name for the Five9List
	 * @return Five9List
	 */
	public static Five9LSP__Five9_List__c createFive9List(String name, String type) {
		Five9LSP__Five9_List__c Five9List = makeFive9List(name, type);
		insert Five9List;
		return Five9List;
	}

	/**
	 * @description makeFive9List creates a Five9LSP__Five9_List__c object.
	 * @param  name name  Name of the List
	 * @param  type type  Type of List (lead or account)
	 * @return Five9LSP__Five9_List__c
	 */
	public static Five9LSP__Five9_List__c makeFive9List(String name, String type) {
		return new Five9LSP__Five9_List__c(
			Name = name,
			Five9LSP__Controlling_Object__c = type.toLowerCase(),
			Five9LSP__Five9_Domain__c = 'BBSI Non E.164',
			Five9LSP__Five9_User_Name__c = FIVE9_TEST_USERNAME,
			Five9LSP__Five9_User_Password__c = FIVE9_TEST_PASSWORD,
			Five9LSP__API_URL__c = 'https://api.five9.com'
		);
	}
}