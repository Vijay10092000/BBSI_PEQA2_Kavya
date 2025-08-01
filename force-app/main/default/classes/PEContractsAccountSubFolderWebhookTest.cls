@IsTest
public class PEContractsAccountSubFolderWebhookTest {
    @testSetup
    public static void loadData(){
        //insert account
        Account acc1 = TestFactoryAccount.makeAccount('BBSI TEST ACCOUNT 1', 'Client');
        acc1.Contracts_Accounts_SubFolder_Id__c='123456';
        
        Account acc2 = TestFactoryAccount.makeAccount('BBSI TEST ACCOUNT 2', 'Client');
        insert new List<Account>{acc1,acc2};     
        
        //insert custom setting
        Box_Contracts_Folder__c contractsCustomSetting = new Box_Contracts_Folder__c();
        contractsCustomSetting.FolderId__c='1234567890';
        contractsCustomSetting.Folder_Name__c='Contracts';
        insert contractsCustomSetting;
    }
    
    private static RestRequest createRequest(Id accId){
        String requestBody = '{'+
            			'"accountId":'+'"'+accId+'"'+
            '}';
        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/createContractsSubfolder';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(requestBody);
        return request;
    }
    
    //create RestResponse
    private static RestResponse createResponse(Integer statusCode, String requestBodykey, String requestBody){
        Map<String,String> resMap = new Map<String,String>{requestBodykey => requestBody};
        String jsonString = JSON.serialize(resMap);
        RestResponse response = new RestResponse();
        response.statusCode = statusCode;
        response.responseBody = Blob.valueOf(jsonString);
        return response;
    }
    
	@IsTest
    public static void testCreateFolderExistingFolderId(){
        
        Account acc = [ SELECT Id,Contracts_Accounts_SubFolder_Id__c FROM Account WHERE Name = 'BBSI TEST ACCOUNT 1' LIMIT 1];
        //REST request
        RestContext.request = createRequest(acc.Id);
        //REST response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        //run method
        Test.startTest();
        PEContractsAccountSubFolderWebhook.createFolder();
        Test.stopTest();
        
        Map<String,Object> resultMap = (Map<String,Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        
        Assert.areEqual(acc.Contracts_Accounts_SubFolder_Id__c, (String)resultMap.get('folderId'), 'FolderId should be same');
    }
    
    @IsTest
    public static void testCreateFolderNewFolderId(){
        
        Account acc = [ SELECT Id, Name, FEIN__c, Contracts_Accounts_SubFolder_Id__c, Status__c,External_ID__c,Prospect_Branch__r.Name, Prospect_Branch__r.External_ID__c 
                       FROM Account WHERE Name = 'BBSI TEST ACCOUNT 2' LIMIT 1];
        // Set up the mock HTTP response
        String mockResponse = '{"entries": [{"id": "12345", "name": "file1.txt"}], "total_count": 1}';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'OK',200));
        
        //REST request
        RestContext.request = createRequest(acc.Id);
        //REST response
        RestContext.response = createResponse(200, 'folderId', '12345');
        //run method
        Test.startTest();
        PEContractsAccountSubFolderWebhook.createFolder();
        Test.stopTest();
        
        Map<String,Object> resultMap = (Map<String,Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        System.debug('Result :'+resultMap);
        Assert.areEqual('12345', (String)resultMap.get('folderId'), 'Newly Created FolderId should be same');
    }
    
    @IsTest
    public static void testCreateFolderEmptyBody(){
        //REST request
        RestRequest req = new RestRequest();
        req.requestBody =Blob.valueOf('');
        RestContext.request = req;
        //REST response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        //run method
        Test.startTest();
        PEContractsAccountSubFolderWebhook.createFolder();
        Test.stopTest();
        
        Map<String,Object> resultMap = (Map<String,Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        
        Assert.isTrue(((String)resultMap.get('Error Message')).contains('Request body is required and cannot be null or empty.'));
        Assert.areEqual(400, RestContext.response.statusCode, 'Status Code Should be Equal');
    }
    
    @IsTest
    public static void testCreateFolderNoParentFolderId(){
        Account acc = [ SELECT Id,Contracts_Accounts_SubFolder_Id__c FROM Account WHERE Name = 'BBSI TEST ACCOUNT 1' LIMIT 1];
        
        //update Parent folderId
        Box_Contracts_Folder__c contractsFolder = [ SELECT Id,FolderId__c,Folder_Name__c FROM Box_Contracts_Folder__c WHERE Folder_Name__c = 'Contracts' LIMIT 1 ];
        contractsFolder.FolderId__c = '';
        update contractsFolder;
        
        //REST request
        RestContext.request = createRequest(acc.Id);
        //REST response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        //run method
        Test.startTest();
        PEContractsAccountSubFolderWebhook.createFolder();
        Test.stopTest();
        
        Map<String,Object> resultMap = (Map<String,Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        
        Assert.isTrue(((String)resultMap.get('Error Message')).contains('Contracts Parent Folder not found in Salesforce.'));
        Assert.areEqual(404, RestContext.response.statusCode, 'Status Code Should be Equal');
    }
    
    @IsTest
    public static void testCreateFolderNoAccountId(){
        //REST request
        String jsonReq = '{'+
            '"accountId":""'+
            '}';
        RestRequest req = new RestRequest();
        req.requestBody =Blob.valueOf(jsonReq);
        RestContext.request = req;
        //REST response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        //run method
        Test.startTest();
        PEContractsAccountSubFolderWebhook.createFolder();
        Test.stopTest();
        
        Map<String,Object> resultMap = (Map<String,Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        
        Assert.isTrue(((String)resultMap.get('Error Message')).contains('Account Id is Required to Create Contract Account Subfolder.'));
        Assert.areEqual(400, RestContext.response.statusCode, 'Status Code Should be Equal');
    }
    
    @IsTest
    public static void testCreateFolderInvalidAccountId(){
        //REST request
        String jsonReq = '{'+
            '"accountId":"0012345678909876"'+
            '}';
        RestRequest req = new RestRequest();
        req.requestBody =Blob.valueOf(jsonReq);
        RestContext.request = req;
        //REST response
        RestResponse res = new RestResponse();
        RestContext.response = res;
        //run method
        Test.startTest();
        PEContractsAccountSubFolderWebhook.createFolder();
        Test.stopTest();
        
        Map<String,Object> resultMap = (Map<String,Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        
        Assert.isTrue(((String)resultMap.get('Error Message')).contains('data not found'));
        Assert.areEqual(404, RestContext.response.statusCode, 'Status Code Should be Equal');
    }
    
    @IsTest
    public static void testCreateNewFolder(){
        
        // Set up the mock HTTP response
        String mockResponse = '{"entries": [{"id": "12345", "name": "file1.txt"}], "total_count": 1}';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'OK',200));
        
        String folderName = 'TestFolderName';
        String parentFolderId = '0987654321';
        Account acc = [ SELECT Id, Name, FEIN__c, Contracts_Accounts_SubFolder_Id__c, Status__c,External_ID__c,Prospect_Branch__r.Name, Prospect_Branch__r.External_ID__c 
                       FROM Account WHERE Name = 'BBSI TEST ACCOUNT 1' LIMIT 1];
        Test.startTest();
        String newFolderId = PEContractsAccountSubFolderWebhook.createNewFolder(folderName, parentFolderId, acc);
        Test.stopTest();
        
        Assert.areEqual('12345', newFolderId, 'Newly Created FolderId Should be Same');
    }
}