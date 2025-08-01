/**
 * @description TestFactoryFive9ListItem contains methods to create test Five9ListsItem.
 */
@IsTest
public without sharing class TestFactoryFive9ListItem {
	/**
	 * @description createFive9List creates a new Five9List record in the database.
	 * @param  idList  Identifier of the Five9 List
	 * @param  idItem  Identifier of the Object
	 * @param  status  Status of the Item
	 * @return Five9LSP__Five9_List_Item__c
	 */
	public static Five9LSP__Five9_List_Item__c createFive9ListItem(Id idList, Id idItem, String status) {
		Five9LSP__Five9_List_Item__c Five9ListItem = makeFive9ListItem(idList, idItem, status);
		insert Five9ListItem;
		return Five9ListItem;
	}

	/**
	 * @description makeFive9ListItem creates a Five9LSP__Five9_List_Item__c object.
	 * @param  idList  Identifier of the Five9 List
	 * @param  idItem  Identifier of the Object
	 * @param  status  Status of the Item
	 * @return Five9LSP__Five9_List_Item__c
	 */
	public static Five9LSP__Five9_List_Item__c makeFive9ListItem(Id idList, Id idItem, String status) {
		DateTime now = DateTime.now();

		Five9LSP__Five9_List_Item__c result = new Five9LSP__Five9_List_Item__c(
			Five9LSP__Five9_List__c = idList,
			Five9LSP__Last_Allow_Sync__c = true,
			Five9LSP__Sync_Status__c = status,
			Five9LSP__Sync_Message__c = 'TESTING',
			Five9LSP__Last_Sync_Time__c = now,
			Five9LSP__Previous_Update_Time__c = now
		);

		if (Id_Service.isType(idItem, 'Account')) {
			result.Five9LSP__Account__c = idItem;
		} else {
			result.Five9LSP__Lead__c = idItem;
		}
		return result;
	}    
}