@IsTest
public class TestFactoryDocument {
    public static Document__c createDocument_SupportDocumentRecordType(String documentName, String customerType, String productType, String state, Boolean isInsert){
        Document__c document = new Document__c(Document_Name__c= documentName,
                                              Customer_Type__c= customerType,
                                              Product_Type__c= productType,
                                              State__c= state,
                                              RecordTypeId= RecordTypeService.getId('Document__c','Support_Documents'),
                                              Type__c='Upload',
                                              Markup_Type__c= 'Bundled',
                                              Comp_Option__c='With Comp');
        if(isInsert){
            insert document;
        }
        return document;
    }
   
}