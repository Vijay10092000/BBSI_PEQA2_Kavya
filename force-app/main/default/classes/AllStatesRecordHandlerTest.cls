@isTest
public class AllStatesRecordHandlerTest {
    @TestSetup
    static void setupTestData() {
        //Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Document__c' AND DeveloperName = 'YourRecordTypeDeveloperName' LIMIT 1].Id;
        // Create test Document__c records
        Document__c allStateDocument1 = new Document__c(Document_Name__c = 'Test Document1', Type__c = 'Upload', 
                                                 Customer_Type__c='NEW',
                                                 Product_Type__c='PEO',
                                                 State__c='All States');
        Document__c allStateDocument2 = new Document__c(Document_Name__c = 'Test Document2', Type__c = 'Upload', 
                                                 Customer_Type__c='NEW',
                                                 Product_Type__c='PEO',
                                                 State__c='All States');
        insert new List<Document__c>{allStateDocument1,allStateDocument2};

        // Create test Opportunity_Document__c records associated with the first two Document__c records
        Opportunity_Document__c allStateOppDocument1 = new Opportunity_Document__c(Document__c = allStateDocument1.Id);
        Opportunity_Document__c allStateOppDocument2 = new Opportunity_Document__c();
        //Opportunity_Document__c allStateOppDocument3 = new Opportunity_Document__c();
        insert new List<Opportunity_Document__c>{allStateOppDocument1,allStateOppDocument2};
    }

    @isTest
    static void testCheckAllStateRecords() {
        // Retrieve test data
        List<Document__c> allStateDocument = [ SELECT Id, Name FROM Document__c WHERE State__c = 'All States' AND Document_Name__c = 'Test Document2' ];
        List<Opportunity_Document__c> allStateOppDocument = [SELECT Id, Name, Document__c FROM Opportunity_Document__c ];
		

        // Prepare input params
        AllStatesRecordHandler.RequestParams requestParams = new AllStatesRecordHandler.RequestParams();
        requestParams.allStateDocumentRecords = allStateDocument; // Pass documents
        requestParams.allStatesOppDocRecords = allStateOppDocument; // Pass associated opp docs

        // Wrap input in a list (since InvocableMethod expects a list)
        List<AllStatesRecordHandler.RequestParams> inputParams = new List<AllStatesRecordHandler.RequestParams>{requestParams};

        // Call the method
        List<AllStatesRecordHandler.ResultParams> results = AllStatesRecordHandler.checkAllStateRecords(inputParams);

        // Verify results
        System.assertEquals(1, results.size(), 'Only one ResultParams should be returned.');
        AllStatesRecordHandler.ResultParams result = results[0];

        // Validate added records
        System.assertEquals(1, result.addedAllStatesRecords.size(), 'One document should be added.');
        //System.assertEquals(allStateDocument.Id, result.addedAllStatesRecords[0].Id, 'The third document should be added.');
	
        System.debug('removed States : '+result.removedAllStatesRecords);
        System.debug('Added States : '+result.addedAllStatesRecords);
        // Validate removed records
        System.assertEquals(1, result.removedAllStatesRecords.size(), 'One opportunity document should be marked for removal.');
        for (Opportunity_Document__c removedDoc : result.removedAllStatesRecords) {
            System.assert(allStateOppDocument.contains(removedDoc), 'Removed document should be one of the associated opportunity docs.');
        }
    }

    @isTest
    static void testNoData() {
        // Test with empty input
        AllStatesRecordHandler.RequestParams requestParams = new AllStatesRecordHandler.RequestParams();
        requestParams.allStateDocumentRecords = new List<Document__c>();
        requestParams.allStatesOppDocRecords = new List<Opportunity_Document__c>();

        List<AllStatesRecordHandler.RequestParams> inputParams = new List<AllStatesRecordHandler.RequestParams>{requestParams};
        List<AllStatesRecordHandler.ResultParams> results = AllStatesRecordHandler.checkAllStateRecords(inputParams);

        // Validate results
        System.assertEquals(1, results.size(), 'ResultParams should be returned even if inputs are empty.');
        System.assertEquals(0, results[0].addedAllStatesRecords.size(), 'No records should be added when input is empty.');
        System.assertEquals(0, results[0].removedAllStatesRecords.size(), 'No records should be removed when input is empty.');
    }
}