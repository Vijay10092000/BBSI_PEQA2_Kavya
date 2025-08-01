@IsTest
public class BoxGetSignLogFileTest {
    @IsTest
    public static void testGetSignLogFileId(){
        //create mock response
        String jsonString = '{'+
             	'"signing_log":{'+
                		'"id":"11233456789"'+
                '}'+
            '}';

        Integer statusCode = 200;
        String status = 'OK';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(jsonString,status,statusCode));

        //create sign request ids
        List<String> signRequestIds = new List<String>{'12345'};
        //start test
        Test.startTest();
        //call method
        List<String> results = BoxGetSignLogFile.getSignLogFileId(signRequestIds);
        //stop test
        Test.stopTest();
        //verify results
        System.assertEquals(1, results.size());
        System.assertEquals('11233456789', results[0]);
    }
    
    @IsTest
    public static void testGetSignLogFileId_EmptyId(){
        //create mock response
        String jsonString = '{'+
             	'"signing_log":{'+
                '}'+
            '}';

        Integer statusCode = 200;
        String status = 'OK';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(jsonString,status,statusCode));

        //create sign request ids
        List<String> signRequestIds = new List<String>{'12345'};
        //start test
        Test.startTest();
        //call method
        List<String> results = BoxGetSignLogFile.getSignLogFileId(signRequestIds);
        //stop test
        Test.stopTest();
        //verify results
        System.assertEquals(0, results.size());
    }
}