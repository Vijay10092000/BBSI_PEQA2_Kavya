@IsTest
public class BoxSignRequestsForUserTest {
	@testSetup
    static void setupTestData(){
        
        //insert box Sign record
        box__BoxSign__c signRecord = new box__BoxSign__c(box__Uuid__c= '12345');
		insert signRecord;
        
        //insert document test record
        Document__c document = TestFactoryDocument.createDocument_SupportDocumentRecordType('BBSI TestDocument','New','PEO','All States',false);
        document.Box_Template_Id_1__c = 'TestTemplateId1';
        insert document;
        
        //insert Account test record
        Account acc = TestFactoryAccount.createClient('BBSI Test Account',null,null);
        
        //insert opportunity test record
        Opportunity opp = TestFactoryOpportunity.createClient('BBSI Test Opportunity',acc.Id,Date.today(),'Proposal');
        System.debug('Opportunity :'+opp);
        
        //insert opportunity_Document test record
        Opportunity_Document__c oppDoc = TestFactoryOpportunity_Document.createOpportunityDocument(opp.Id, document.Id, true);
        
    }
        
    @IsTest
    public static void testgetLatestSignRequest_Success(){
        String responseBody = '{"entries": [{"id": "12345",' 
            +'"prefill_tags": [{"document_tag_id": "sf_unique_id_sign_request", "text_value": "1000"}],'
            +'"source_files": [{"id": "TestTemplateId1"}],'
            +'"sign_files": {"files": [{"id": "SignFileId1"}]}}]}';
        String status = 'OK';
        Integer statusCode = 200;
        //set mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(responseBody, status, statusCode));
        List<Opportunity_Document__c> oppDocs = [ SELECT Id,Document__c,Opportunity__c,Box_File_Id__c FROM Opportunity_Document__c WHERE Document_Name__c IN ('BBSI TestDocument')];
		BoxSignRequestsForUser.RequestParameters params = new BoxSignRequestsForUser.RequestParameters();
        params.timeStamp = '1000';
        params.oppDocs = oppDocs;        
		Test.startTest();
        List<List<Opportunity_Document__c>> updatedOppDocs = BoxSignRequestsForUser.getLatestSignRequest(new List<BoxSignRequestsForUser.RequestParameters>{params});
        Test.stopTest();
        
        System.assertNotEquals(null, updatedOppDocs,  'Updated records should not be null');
        System.assertEquals(1, updatedOppDocs.size());
        System.assertEquals(1, updatedOppDocs[0].size(), 'One record should be updated');
        System.assertNotEquals(null, updatedOppDocs[0][0].Box_File_Id__c);
        System.assertEquals('SignFileId1', updatedOppDocs[0][0].Box_File_Id__c, 'Updated Box_File_Id__c should be equal to signFileId from response');
    }
    
    @IsTest
    public static void testGetLatestSignRequest_EmptyResponse(){
        String responseBody = '{"entries": []}';
        String status = 'OK';
        Integer statusCode = 200;
        //set mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(responseBody, status, statusCode));
        
        List<Opportunity_Document__c> oppDocs = [ SELECT Id,Document__c,Opportunity__c,Box_File_Id__c FROM Opportunity_Document__c WHERE Document_Name__c IN ('BBSI TestDocument')];
        BoxSignRequestsForUser.RequestParameters params = new BoxSignRequestsForUser.RequestParameters();
        params.timeStamp = '1000';
        params.oppDocs = oppDocs;
        Test.startTest();
        List<List<Opportunity_Document__c>> updatedOppDocs = BoxSignRequestsForUser.getLatestSignRequest(new List<BoxSignRequestsForUser.RequestParameters>{params});
        Test.stopTest();
        
        System.assertEquals(null, updatedOppDocs[0][0].Box_File_Id__c, 'Records should not be updated as response is null');
    }
}