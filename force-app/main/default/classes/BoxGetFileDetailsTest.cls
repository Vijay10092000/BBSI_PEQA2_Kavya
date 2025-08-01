@isTest
public class BoxGetFileDetailsTest {
    @isTest
    static void testgetFileDetail() {
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
        // Call the method
        Test.startTest();
        List<BoxGetFileDetails.ResultParams> result = BoxGetFileDetails.getFileDetail(new List<String>{'1234567890'});
        Test.stopTest();
        
        // Validate the result
        //System.assertEquals();
        System.assertEquals('png', result[0].fileExtension, 'Returned Extension Value should be equal to extension of file name');
        System.assertEquals('171536 - 3 Carpenters - E3 Doc', result[0].filename, 'Returned FileName should be equal to file name');
    }

}