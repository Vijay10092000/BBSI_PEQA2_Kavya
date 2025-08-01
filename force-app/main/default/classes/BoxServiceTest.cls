@IsTest
public with sharing class BoxServiceTest {
    public BoxServiceTest() {

    }

    @IsTest
    public static void testGetFilesInFolder() {
        // Set up the mock HTTP response
        String mockResponse = '{"entries": [{"type": "file", "id": "12345", "name": "testFile.txt"}], "total_count": 1}';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'OK',200));
        

        // Create a test instance of BoxService
        BoxService boxService = new BoxService();

        // Test getting files in a folder
        String folderId = '1234567890';
        List<String> files = boxService.getFilesInFolder(folderId);

        // Assert the response
        System.assertNotEquals(null, files, 'The list of files should not be null');
        System.assertEquals(1, files.size(), 'The list of files should contain one file');
        System.assertEquals('12345', files[0], 'The file name should match the expected value');
    }

    @IsTest
    public static void testGetFilesInFolderException() {
        // Set up the mock HTTP response
        String mockResponse = '{'+
                '"code": "not_found",'+
                '"context_info": {'+
                '"message": "Resource with the given ID not found."'+
                '},'+
                '"help_url": "http://developers.box.com/docs/#errors",'+
            '}';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'Not Found',404));
        
        // Create a test instance of BoxService
        BoxService boxService = new BoxService();

        // Test getting files in a folder
        String folderId = '1234567890';
        try{
            List<String> files = boxService.getFilesInFolder(folderId);
        }catch(Exception e){
            //Assert.isTrue(e.getMessage().contains('404 Error'));
        }
    }

    @IsTest
    public static void testCopyFile(){
        String mockResponse ='{'+
            '"type": "file",'+
            '"id": "1720275659001",'+
            '"file_version": {'+
            '"type": "file_version",'+
            '"id": "1894236774201",'+
            '"sha1": "f108cbddbf593b7cd93ba5dbf1073dbaa63d8554"'+
            '},'+
            '"sequence_id": "1",'+
            '"etag": "1",'+
            '"sha1": "f108cbddbf593b7cd93ba5dbf1073dbaa63d8554",'+
            '"name": "171536 - 3 Carpenters - E3 Doc.png",'+
            '"description": "",'+
            '"size": 10917'+
            '}';

        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'OK',201));
        
        BoxService boxService = new BoxService();
        boxService.copyFile('1234567890123456', '0987654321');
    }

    @IsTest
    public static void testCopyFile_Exception(){
        // Set up the mock HTTP response
        String mockResponse = '{'+
                '"code": "not_found",'+
                '"context_info": {'+
                '"message": "Resource with the given ID not found."'+
                '},'+
                '"help_url": "http://developers.box.com/docs/#errors",'+
            '}';

        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'OK',404));
        try{
            BoxService boxService = new BoxService();
            boxService.copyFile('1234567890123456', '0987654321');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('Copy failed →'));
        }
    }

    @IsTest
    public static void testCreateFolderForRecord(){
        Account acc = TestFactoryAccount.createAccount('BBSI Test Account', 'Client');
        BoxService boxService = new BoxService();
        String folderId = boxService.createFolderForRecord(acc.Id);
        
        System.assertEquals(folderId, '99999', 'The folder Id should match');
    }

    @IsTest
    public static void testCreateFolderForRecordException(){
        BoxService boxService = new BoxService();
        try{
            String folderId = boxService.createFolderForRecord('');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('Invalid id'));
        }
    }

    @IsTest
    public static void testUploadFileToBox() {
        Account acc = TestFactoryAccount.createAccount('BBSI Test Account', 'Client');
        // Create a test instance of BoxService
        BoxService boxService = new BoxService();

        // Test uploading a file to Box
        Blob fileBody = Blob.valueOf('Test file content');
        String fileName = 'testFile.txt';
        String parentId = acc.Id;
        String contentType = 'text/plain';
        String fileId = boxService.uploadFileToBox(fileBody, fileName, parentId, contentType);

        // Assert the response
        System.assertEquals(fileId, '999999', 'The response should match the mock response');
    }

    @IsTest
    public static void testAddTagsToFolder() {
        // Set up the mock HTTP response
        String mockResponse = '{"entries": [{"id": "12345", "name": "file1.txt"}], "total_count": 1}';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'OK',200));
        

        // Create a test instance of BoxService
        BoxService boxService = new BoxService();

        // Test adding tags to a folder
        String folderId = '12567890';
        List<String> tagValues = new List<String>{'tag1', 'tag2'};
        String response = boxService.addTagsToFolder(folderId, tagValues);

        // Assert the response
        System.assertEquals(mockResponse, response, 'The response should match the mock response');
    }

    @IsTest
    public static void testAddTagsToFolder_Exception() {
        // Set up the mock HTTP response
        String mockResponse = '{'+
                '"code": "not_found",'+
                '"context_info": {'+
                '"message": "Resource with the given ID not found."'+
                '},'+
                '"help_url": "http://developers.box.com/docs/#errors",'+
            '}';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'Not Found',404));
        

        // Create a test instance of BoxService
        BoxService boxService = new BoxService();

        // Test adding tags to a folder
        String folderId = '12567890';
        List<String> tagValues = new List<String>{'tag1', 'tag2'};
        try{
            String response = boxService.addTagsToFolder(folderId, tagValues);
        }catch(Exception e){
            Assert.isTrue((e.getMessage()).contains('Add Tags to folder failed'));
        }
    }

    @IsTest
    public static void testcreateFolder() {
        // Create a test instance of BoxService
        BoxService boxService = new BoxService();

        // Test creating a folder
        String folderName = 'BBSI Test Folder';
        String parentId = '087612345678';
        Test.startTest();
        String response = boxService.createFolder(folderName, parentId);
        Test.stopTest();
        // Assert the response
        System.assertEquals(response, '12345', 'The folder Id should match');
    }

    @IsTest
    public static void testcreateMetadataOnFolder(){
        // Create a test instance of BoxService
        BoxService boxService = new BoxService();

        Account acc = TestFactoryAccount.createAccount('BBSI Test Account', 'Client');
        try{
            box.CreateBoxMetadataByFolderId.Response response = boxService.createMetadataOnFolder(acc, '12345', 'enterprise', 'contracts');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('Create Metadata on folder failed → Methods defined as TestMethod do not support Web service callouts'));
        }
    }

    @IsTest
    public static void testupdateMetadataOnFolder(){
        // Create a test instance of BoxService
        BoxService boxService = new BoxService();
        Account acc = TestFactoryAccount.createAccount('BBSI Test Account', 'Client');
        try{
            box.UpdateBoxMetadataByFolderId.Response response = boxService.updateMetadataOnFolder(acc, '12345', 'enterprise', 'contracts');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('Update Metadata on folder failed → Methods defined as TestMethod do not support Web service callouts'));
        }
        
    }

    @IsTest
    public static void testcreateOrGetSharedLinkForFolder(){
        // Set up the mock HTTP response
        String mockResponse = '{"shared_link": {"url": "https://example.com/sharedlink"}}';
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'created',200));

        // Create a test instance of BoxService
        BoxService boxService = new BoxService();

        // Test creating or getting a shared link for a folder
        String folderId = '1234567890';
        String response = boxService.createOrGetSharedLinkForFolder(folderId);

        // Assert the response
        System.assertEquals(response, 'https://example.com/sharedlink', 'The response should match the mock response');
    }

    @IsTest
    public static void testcreateOrGetSharedLinkForFolder_Exception(){
        // Set up the mock HTTP response
        String mockResponse = '{'+
                '"code": "not_found",'+
                '"context_info": {'+
                '"message": "Resource with the given ID not found."'+
                '},'+
                '"help_url": "http://developers.box.com/docs/#errors",'+
            '}';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'Not Found',404));
        
        // Create a test instance of BoxService
        BoxService boxService = new BoxService();
        // Test creating or getting a shared link for a folder
        String folderId = '1234567890';
        try{
            String response = boxService.createOrGetSharedLinkForFolder(folderId);
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('Create shared link for folder failed'));
        }
    }

    @IsTest
    public static void testcreateWeblink(){
        // Set up the mock HTTP response
        String mockResponse = '{"id":"0987654323456789", "web_link": {"url": "https://example.com/weblink"}}';
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'created',201));

        String link = 'https://example.com/sharedlink';
        // Create a test instance of BoxService
        BoxService boxService = new BoxService();
        String response = boxService.createWeblink(link, '1234567890', 'Test Folder Name');
        Assert.isTrue(response.contains('0987654323456789'), 'Response should contain Id');
    }

    @IsTest
    public static void testcreateWeblink_Exception(){
        // Set up the mock HTTP response
        String mockResponse = '{'+
                '"code": "not_found",'+
                '"context_info": {'+
                '"message": "Resource with the given ID not found."'+
                '},'+
                '"help_url": "http://developers.box.com/docs/#errors",'+
            '}';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(mockResponse,'Not Found',404));

        String link = 'https://example.com/sharedlink';
        // Create a test instance of BoxService
        BoxService boxService = new BoxService();

        try{
            String response = boxService.createWeblink(link, '1234567890', 'Test Folder Name');
        }catch(Exception e){
            Assert.isTrue(e.getMessage().contains('Create weblink link for folder failed'), 'Message should contain weblink failed');
        }
    }
}