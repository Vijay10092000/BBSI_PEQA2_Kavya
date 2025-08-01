@IsTest
public class BoxAddTagsToFolderTest {
	@isTest
    static void testAddTagsToFolder() {
        String response = '{'+
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
  
        Map<String,String> headers = new Map<String,String>();
        headers.put('content-type','application/json');
        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class,
                    new GenericMockCallout(200, 'OK', response , headers));


        // Create test parameters
        BoxAddTagsToFolder.RequestParams params = new BoxAddTagsToFolder.RequestParams();
        params.folderId = '12345'; // Sample file ID
        params.tagValues = new List<String>{'TestTag'}; // Sample tag

        // Add the parameters to a list
        List<BoxAddTagsToFolder.RequestParams> requestParams = new List<BoxAddTagsToFolder.RequestParams>();
        requestParams.add(params);

        // Call the method
        Test.startTest();
        List<String> result = BoxAddTagsToFolder.addTagsToFolder(requestParams);
        Test.stopTest();
		
        // Validate the result
        System.assertEquals('171536 - 3 Carpenters - E3 Doc.png', result[0], 'Returned valued should be equal to extension of file name');
    }
}