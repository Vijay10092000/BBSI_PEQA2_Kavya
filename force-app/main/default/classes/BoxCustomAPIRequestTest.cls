@isTest
public class BoxCustomAPIRequestTest {

    @testSetup
    static void setupData() {
        // Create a test User with a mock Box_User_Id__c
        User u1 = TestFactory.createUser('One Test', 'One.test@bbsi.com', 'One.test@bbsi.com', 'System Administrator', '910', false);
    }
    
    @isTest
    static void testGetSignRequests() {
            // Set the mock callout response for authentication (this is crucial)
            //Test.setMock(HttpCalloutMock.class, new BoxTestMockCallout('{"access_token": "mock_token", "expires_in": 3600}', 'OK', 200));
    
            // Set the mock callout response for sign requests
           // Test.setMock(HttpCalloutMock.class, new BoxTestMockCallout('{"sign_requests": [{"id": "12345", "status": "completed"}]}', 'OK', 200));
        	String responseBody = '{"next_marker": "cD0yMDI1LTAxLTI0KzEyJTNBMjUlM0E1Mi4xODk1NzklMkIwMCUzQTAw",'
                    + '"limit": 10,'
                	+ '"signrequestId":12345,'
                    + '"sign_requests": ['
                    + '{'
                    + '"is_document_preparation_needed": false,'
                    + '"redirect_url": null,'
                    + '"declined_redirect_url": null,'
                    + '"are_text_signatures_enabled": true,'
                    + '"signature_color": null,'
                    + '"email_subject": "",'
                    + '"email_message": "",'
                    + '"are_reminders_enabled": false'
                    + '}'
                    + ']}';
            Integer statusCode = 200;
            String status = 'OK';
            // Set up a mock response
            Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(responseBody,status,statusCode));
        
            // Call the method that makes the callout
            String response = BoxCustomAPIRequest.getSignRequests();
    
            // Assertions
            System.assertNotEquals(null, response, 'Response should not be null');
            System.assert(response.contains('sign_requests'), 'Response should contain sign_requests');
            System.assert(response.contains('12345'), 'Response should contain sign request ID');

        
    }

    @isTest
    static void testGetBoxUsers() {
        // Set the mock callout response for authentication
        //Test.setMock(HttpCalloutMock.class, new BoxTestMockCallout('{"access_token": "mock_token", "expires_in": 3600}', 'OK', 200));

        // Set the mock callout response for box users
        //Test.setMock(HttpCalloutMock.class, new BoxTestMockCallout('{"users": [{"id": "1", "name": "Test User"}]}', 'OK', 200));
        
        String responseBody = '{"total_count": 14,'
                    + '"users": ['
                    + '{'
                    + '"type": "user",'
                    + '"id": "35730294263",'
                    + '"name": "Test User",'
                    + '"login": "Harpreet.Singh@bbsi.com",'
                    + '"created_at": "2024-08-14T16:26:04-07:00",'
                    + '"modified_at": "2025-02-03T12:24:07-08:00",'
                    + '"language": "en",'
                    + '"timezone": "America/Los_Angeles",'
                    + '"space_amount": 10737418240,'
                    + '"space_used": 8470145,'
                    + '"max_upload_size": 161061273600,'
                    + '"status": "active"'
                    + '}'
                    + ']}';
            Integer statusCode = 200;
            String status = 'OK';
            // Set up a mock response
            Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(responseBody,status,statusCode));

        // Call the method that makes the callout
        String response = BoxCustomAPIRequest.getBoxUsers(0, 1000);

        // Assertions
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.contains('users'), 'Response should contain users');
        System.assert(response.contains('Test User'), 'Response should contain user name');
    }
}