@IsTest
private class BoxConnectionEnterpriseAPITest {

    /**
     * Test case for successful authentication
     */
    @isTest
    static void testSuccessfulAuthentication() {
        String responseBody = '{"access_token": "mockAccessToken123", "expires_in": 3600}';
        Integer statusCode = 200;
        String status = 'OK';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(responseBody,status,statusCode));

        // Instantiate the class and call authenticate
        BoxConnectionEnterpriseAPI api = new BoxConnectionEnterpriseAPI();
        api.authenticate();
        
        // Simulate token expiration by manually setting last refresh time
        api.setLastRefresh(DateTime.now().addSeconds(-4000).getTime());

        // Assertions
        System.assertNotEquals(api.getAccessToken(), null, 'Access token should not be null');
        System.assertEquals(api.getExpires(), 3600000, 'Expiration time should be greater than zero');
    }
    
    @isTest
    static void testFailedAuthentication() {
        
        String responseBody = '{"error": "Unauthorized"}';
        Integer statusCode = 401;
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(responseBody,'',statusCode));

        BoxConnectionEnterpriseAPI api = new BoxConnectionEnterpriseAPI();
        try {
            api.authenticate();
            System.assert(false, 'Exception should have been thrown for failed authentication');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Unauthorized'), 'Exception message should contain Unauthorized');
        }
    }
}