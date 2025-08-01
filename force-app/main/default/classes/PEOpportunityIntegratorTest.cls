@IsTest
public class PEOpportunityIntegratorTest {
	@IsTest
    public static void test_MakeHttpCallToPricingEngine(){
        // Set up test data
        List<String> statesList = new List<String>{'state1', 'tate2'};
        String accountId = 'test_account_id';
        Map<String, String> headers = new Map<String, String>();
		headers.put('Content-Type', 'application/xml; charset=UTF-8');
        String response =  '{"states":["state1","state2"],"acc_id":"test_account_id"}';
        Test.setMock(
			HttpCalloutMock.class,
			new GenericMockCallout(200, 'OK',response, headers)
		);
        Test.startTest();
        PEOpportunityIntegrator.makeHttpCallToPricingEngine(statesList, accountId);
        Test.stopTest();
        System.assert(response.contains('state1'), 'Mock response should contain state1');
        System.assert(response.contains(accountId), 'Mock response should contain accountId');
    }
}