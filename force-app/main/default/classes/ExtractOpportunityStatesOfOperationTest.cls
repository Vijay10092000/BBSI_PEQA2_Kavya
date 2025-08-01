@isTest
public class ExtractOpportunityStatesOfOperationTest {

    @isTest
    static void testExtractStates() {
        ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate compareState = 
            new ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate();
        compareState.oldStates = 'CA;NY;TX';
        compareState.newStates = 'CA;FL;TX';
        
        List<ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate> inputList = 
            new List<ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate>{compareState};
        
        Test.startTest();
        List<ExtractOpportunityStatesOfOperation.ResultStates> results = 
            ExtractOpportunityStatesOfOperation.extractStates(inputList);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result object');
        
        ExtractOpportunityStatesOfOperation.ResultStates result = results[0];
        
        System.assertNotEquals(null, result.addedStates, 'Expected addedStates to not be null');
        System.assertEquals(1, result.addedStates.size(), 'Expected one added state');
        System.assertEquals('FL', result.addedStates[0], 'Expected added state to be FL');
        
        System.assertNotEquals(null, result.removedStates, 'Expected removedStates to not be null');
        System.assertEquals(1, result.removedStates.size(), 'Expected one removed state');
        System.assertEquals('NY', result.removedStates[0], 'Expected removed state to be NY');
    }
    
    @isTest
    static void testExtractStatesWithNullValues() {
        ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate compareState = 
            new ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate();
        compareState.oldStates = null;
        compareState.newStates = 'CA;FL';
        
        List<ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate> inputList = 
            new List<ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate>{compareState};
        
        Test.startTest();
        List<ExtractOpportunityStatesOfOperation.ResultStates> results = 
            ExtractOpportunityStatesOfOperation.extractStates(inputList);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result object');
        
        ExtractOpportunityStatesOfOperation.ResultStates result = results[0];
        
        System.assertNotEquals(null, result.addedStates, 'Expected addedStates to not be null');
        System.assertEquals(2, result.addedStates.size(), 'Expected two added states');
        System.assert(result.addedStates.contains('CA'), 'Expected added states to contain CA');
        System.assert(result.addedStates.contains('FL'), 'Expected added states to contain FL');
        
        System.assertNotEquals(null, result.removedStates, 'Expected removedStates to not be null');
        System.assertEquals(0, result.removedStates.size(), 'Expected no removed states');
    }
    
    @isTest
    static void testExtractStatesWithEmptyValues() {
        ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate compareState = 
            new ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate();
        compareState.oldStates = '';
        compareState.newStates = '';
        
        List<ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate> inputList = 
            new List<ExtractOpportunityStatesOfOperation.CompareStatesBeforeAfterUpdate>{compareState};
        
        Test.startTest();
        List<ExtractOpportunityStatesOfOperation.ResultStates> results = 
            ExtractOpportunityStatesOfOperation.extractStates(inputList);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Expected one result object');
        
        ExtractOpportunityStatesOfOperation.ResultStates result = results[0];
        
        System.assertNotEquals(null, result.addedStates, 'Expected addedStates to not be null');
        System.assertEquals(0, result.addedStates.size(), 'Expected no added states');
        
        System.assertNotEquals(null, result.removedStates, 'Expected removedStates to not be null');
        System.assertEquals(0, result.removedStates.size(), 'Expected no removed states');
    }
}