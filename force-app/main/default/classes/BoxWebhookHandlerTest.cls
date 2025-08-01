@IsTest
public class BoxWebhookHandlerTest {
    
    @testSetup
    static void setupData(){
        //create an account
        Account acc  = TestFactoryAccount.createAccount('BBSI TEST ACCOUNT','Client');
        
        //Create opportunity
		Opportunity opp = TestFactoryOpportunity.createClient('BBSI TEST OPPORTUNITY', acc.Id, System.today(), 'Prospect');		        
        
        //Create Document
        Document__c doc = TestFactoryDocument.createDocument_SupportDocumentRecordType('BBSI TEST DOCUMENT','New', 'PEO', 'All States', true);
        
        
        //create Opportunity_Document__c
        Opportunity_Document__c oppDoc1 = TestFactoryOpportunity_Document.createOpportunityDocument(opp.Id, doc.Id, false);
        oppDoc1.Box_Sign_UUID__c = '6ac9572b-1aff-4ad4-aaa2-c2f058d3a8c1';
        
        //insert 
        insert new List<Opportunity_Document__c>{oppDoc1};
        
    }
    
	// Utility method to create a mock request
    private static RestRequest createMockRequest(String method, String body) {
        //time stamp
        DateTime test_time = DateTime.now();
        String time_stamp = test_time.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        if(body ==null){
            body ='';
        }
        
        //keys
        Map<String,String> mdt_record_map = BoxWebhookHandler.get_keys_from_mdt();
        
        // Combine request_body + timestamp
        String combined_data_as_hex = EncodingUtil.convertToHex(Blob.valueOf(body)) + EncodingUtil.convertToHex(Blob.valueOf(time_stamp));
        Blob data_to_sign = EncodingUtil.convertFromHex(combined_data_as_hex);
        // Generate HMAC-SHA256 with Primary Key
        Blob hmac_primary_key = Crypto.generateMac('HmacSHA256', data_to_sign, Blob.valueOf(mdt_record_map.get('Box_Primary_Key')));
        String encoded_primary_key = EncodingUtil.base64Encode(hmac_primary_key);
        
        //Generate HMAC-SHA256 with secondary Key
        Blob hmac_secondary_key = Crypto.generateMac('HmacSHA256', data_to_sign, Blob.valueOf(mdt_record_map.get('Box_Secondary_Key')));
        String encoded_secondary_key = EncodingUtil.base64Encode(hmac_primary_key);
        
        RestRequest req = new RestRequest();
        req.httpMethod = method;
        req.requestUri = '/services/apexrest/boxSignWebhook';
        req.addHeader('box-delivery-timestamp',time_stamp);
        req.addHeader('box-signature-primary',encoded_primary_key);
        req.addHeader('box-signature-secondary',encoded_secondary_key);
        if (body != null) {
            req.requestBody = Blob.valueOf(body);
        }
        return req;
    }
    
    // Utility method to create a mock request
    private static RestRequest createMockRequest_invalid_headers(String method, String body) {
        //time stamp
        DateTime test_time = DateTime.now();
        String time_stamp = test_time.format('yyyy-MM-dd\'T\'HH:mm:ss');

        RestRequest req = new RestRequest();
        req.httpMethod = method;
        req.requestUri = '/services/apexrest/boxSignWebhook';
        req.addHeader('box-delivery-timestamp',time_stamp);
        req.addHeader('box-signature-primary','dsfweq24353tremfgseiur90q340/=');
        req.addHeader('box-signature-secondary','sdlfjdso409r093ioir54980eirojhnkfdshf=');
        if (body != null) {
            req.requestBody = Blob.valueOf(body);
        }
        return req;
    }
    
    
    // Test for @HttpPost - Positive Case
    @IsTest
    static void test_doPost() {
        String sampleJson = '{' +
            '"type":"webhook_event",' +
            '"id":"48d00471-8a8b-4cd3-b288-2c7bd4cfbd64",' +
            '"trigger":"SIGN_REQUEST.SIGNATURE_REQUESTED",' +
            '"additional_info":{' +
                '"sign_request_id":"6ac9572b-1aff-4ad4-aaa2-c2f058d3a8c1"' +
            '}' +
        '}';

        // Mock REST context
        RestContext.request = createMockRequest('POST', sampleJson);
        RestContext.response = new RestResponse();
		
        Test.startTest();
        // Call the method
        BoxWebhookHandler.do_post();
        Test.stopTest();
        
        List<Opportunity_Document__c> oppdocs = [ SELECT Id, Status__c,Box_Sign_UUID__c FROM Opportunity_Document__c WHERE Box_Sign_UUID__c='6ac9572b-1aff-4ad4-aaa2-c2f058d3a8c1' ];
        for(Opportunity_Document__c oppdoc: oppdocs){
            Assert.areEqual('Pending Signature',oppdoc.Status__c, 'Status should updated as Pending Signature');
        }

    }
    
    @IsTest
    static void test_doPost_nullRequest(){
        // Mock REST context
        RestContext.request = createMockRequest('POST', null);
        RestContext.response = new RestResponse();
		
        Test.startTest();
        // Call the method
        BoxWebhookHandler.do_post();
        Test.stopTest();
		//Assertions
        System.assertEquals(500, RestContext.response.statusCode, 'Status Code Should be 500');
        System.assert(RestContext.response.responseBody.toString().contains('Error'), 'Response Body Should Contain Error');
    }
    
    @IsTest
    static void test_doPost_headers_failed() {
        String sampleJson = '{' +
            '"type":"webhook_event",' +
            '"id":"48d00471-8a8b-4cd3-b288-2c7bd4cfbd64",' +
            '"trigger":"SIGN_REQUEST.SIGNATURE_REQUESTED",' +
            '"additional_info":{' +
                '"sign_request_id":"6ac9572b-1aff-4ad4-aaa2-c2f058d3a8c1"' +
            '}' +
        '}';

        // Mock REST context
        RestContext.request = createMockRequest_invalid_headers('POST', sampleJson);
        RestContext.response = new RestResponse();
		
        Test.startTest();
        // Call the method
        BoxWebhookHandler.do_post();
        Test.stopTest();
        
        Assert.areEqual(401, RestContext.response.statusCode, 'Status code should be 401');
        Assert.isTrue(RestContext.response.responseBody.toString().contains('Authorisation Failed'));
    }
    
}