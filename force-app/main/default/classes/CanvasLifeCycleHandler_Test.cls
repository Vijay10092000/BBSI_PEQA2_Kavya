/**
 * @description CanvasLifeCycleHandler_Test contains methods to exclude context data and include custom parameters into Canvas App.
 */
@isTest
public class CanvasLifeCycleHandler_Test {
    @isTest
    /**
	 * @description test_excludeContextTypes excludes context information in which the canvas app is running
	 */
    static void test_excludeContextTypes(){
        CanvasLifeCycleHandler handler = new CanvasLifeCycleHandler();
        Set<Canvas.ContextTypeEnum> excludes = handler.excludeContextTypes();
        //Assert.areNotEqual(null,excludes,'Exclude Context Should Return a Set');
    }
    @isTest
    /**
	 * @description test_OnRender_With_Account adds custom parameters of Account into the Canvas App
	 */
	static void test_OnRender_With_Account() {
        // Create test account
        Account acc = TestFactoryAccount.createAccount('Test Account','client');
        // Test handler with some mock environment context values
        Map<String, String> envValues = new Map<String, String>();
        // Mock the RenderContext and set the recordId parameter
        Canvas.RenderContext mock = Canvas.Test.mockRenderContext(null, envValues);
        mock.getEnvironmentContext().setParametersAsJSON('{"recordId":"'+ acc.Id +'"}');    
        CanvasLifeCycleHandler handler = new CanvasLifeCycleHandler();
        Canvas.Test.testCanvasLifecycle(handler, mock);
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(mock.getEnvironmentContext().getParametersAsJSON());
        Assert.areEqual(acc.Name, params.get('Name'),'Name Should Be acc.Name');
        Assert.areEqual(acc.Industry, params.get('Industry'));
        Assert.areEqual(acc.Id, params.get('recordId'));
	}
    @isTest
     /**
	 * @description test_OnRender_With_Opportunity adds custom parameters of Opportunity into the Canvas App
	 */
	static void test_OnRender_With_Opportunity() {
        Account acc = TestFactoryAccount.createAccount('Test Account','client'); 
        // Create test Opportunity
        Opportunity opp = TestFactoryOpportunity.createClient('Test Opportunity', acc.Id, Date.today(), 'Prospecting');
        // Test handler with some mock environment context values
        Map<String, String> envValues = new Map<String, String>();
        // Mock the RenderContext and set the recordId parameter
        Canvas.RenderContext mock = Canvas.Test.mockRenderContext(null, envValues);
        mock.getEnvironmentContext().setParametersAsJSON('{"recordId":"' + opp.Id + '"}');
        CanvasLifeCycleHandler handler = new CanvasLifeCycleHandler();
        Canvas.Test.testCanvasLifecycle(handler, mock);
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(mock.getEnvironmentContext().getParametersAsJSON());
        Assert.areEqual(opp.Name, params.get('Name'),'Name Should Be opp.Name');
        Assert.areEqual(acc.Industry, params.get('Industry'),'Industry should be equal to Account Industry');
        Assert.areEqual(acc.Id, params.get('AccountId'),'We should able to get AccountId');
	}
}