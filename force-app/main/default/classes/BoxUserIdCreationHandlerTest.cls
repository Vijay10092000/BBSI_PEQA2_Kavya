@IsTest
public class BoxUserIdCreationHandlerTest {
	@testSetup
    static void setupTestData() {
        // Create test users
        User user = TestFactoryUser.makeUser('TestUser1','LastName','System Administrator','910','test@bbsi.com','testuser@bbsi.com');
        insert user;
    }  
    
    /**
     * Test case for successful user updates from Box API response.
     */
    @isTest
    static void testSuccessfulUserUpdate() {
        // Set mock response  
        String responseBody = '{"total_count": 2, "limit": 1, "entries": ['
                        + '{"id": "123456", "login": "test@bbsi.com"},'
                        + '{"id": "789012", "login": "user2@example.com"}'
                        + ']}';
        Integer statusCode = 200;
        String status = 'OK';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(responseBody,status,statusCode));

        // Call the method
        Test.startTest();
        BoxUserIdCreationHandler.updateBoxFileIdForUsers();
        Test.stopTest();

        // Query users to check if Box_User_Id__c is updated
        List<User> updatedUsers = [SELECT Email, Box_User_Id__c FROM User WHERE Email IN ('test@bbsi.com')];
        // Assertions
        System.assertEquals(1, updatedUsers.size(), 'Two users should be updated.');
        System.assertEquals('123456', updatedUsers[0].Box_User_Id__c, 'User1 should have correct Box_User_Id__c.');
        //System.assertEquals('789012', updatedUsers[1].Box_User_Id__c, 'User2 should have correct Box_User_Id__c.');
    }
    
    /**
     * Test case when the Box API response is not empty but zero entries.
     */
    @isTest
    static void testNoEntries() {
		
        String responseBody = '{"total_count": 0, "limit": 1000,"entries": []}';
        Integer statusCode = 200;
        String status = 'OK';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(responseBody,status,statusCode));
        Test.startTest();
        BoxUserIdCreationHandler.updateBoxFileIdForUsers();
        Test.stopTest();

        // Ensure no updates were made
        List<User> users = [SELECT Email, Box_User_Id__c FROM User WHERE Email IN ('test@bbsi.com') ];
        //System.assertEquals(null,users[0].Box_User_Id__c,'Box_User_Id__c should not be updated.');
        for (User usr : users) {
            System.assertEquals(null, usr.Box_User_Id__c, 'Box_User_Id__c should not be updated.');
        }
    }

}