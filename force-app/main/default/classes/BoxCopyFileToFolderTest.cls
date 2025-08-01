@isTest
public class BoxCopyFileToFolderTest {
	
    @isTest
    static void testcopyFileToFolder() {
        String res ='{'+
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
		
        Map<String, String> headers = new Map<String, String>();
		headers.put('Content-Type', 'application/json');
        
        Test.setMock(
			HttpCalloutMock.class,
			new GenericMockCallout(200, 'OK', res, headers)
		);
        
		BoxCopyFileToFolder.RequestParams reqparam = new BoxCopyFileToFolder.RequestParams();
        reqparam.fileId = '1234567890';
        reqParam.destinationFolderId = '09876543221';
        reqparam.fein ='123456';
        reqparam.accountName = 'Test Account';
        reqparam.documentName ='Test Document';
        reqparam.fileExtension = 'png';
            
        // Call the method
        Test.startTest();
        List<Integer> result = BoxCopyFileToFolder.copyFileToFolder(new List<BoxCopyFileToFolder.RequestParams>{reqparam});
        Test.stopTest();
        
        // Validate the result
        System.assertEquals(200, result[0], 'The status code should be 200 for successful mock callout');
    }
}