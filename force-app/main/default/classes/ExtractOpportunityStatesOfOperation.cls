/*
 * @description This class splits the multi-select picklist field States_of_Operation__c into individual state names and returns a list of removed states and newly added states
 * It is then invoked in the Opportunity_Support_Document_Record_Creation Flow
 * 
*/

public class ExtractOpportunityStatesOfOperation {
    /*
     * @description this method extracts removed and newly added states in states of operation on opportunity
     * @param List<CompareStatesBeforeAfterUpdate> contains list of states before and after update of states of operation 
     * @return list of updated states
    */
    
    @InvocableMethod
    Public Static List<ResultStates> extractStates(List<CompareStatesBeforeAfterUpdate> statesList){
        List<ResultStates> results = new List<ResultStates>();
        for (CompareStatesBeforeAfterUpdate states : statesList) {
            List<String> oldStates = (states.oldStates != null) ? states.oldStates.split(';') : new List<String>();
            List<String> newStates = (states.newStates != null) ? states.newStates.split(';') : new List<String>();
            
            List<String> addedStates = new List<String>();
            List<String> removedStates = new List<String>();

            // Find removed states
            for (String state : oldStates) {
                if (!newStates.contains(state)) {
                    removedStates.add(state);
                }
            }

            // Find added states
            for (String state : newStates) {
                if (!oldStates.contains(state)) {
                    addedStates.add(state);
                }
            }

            ResultStates result = new ResultStates();
            result.addedStates = addedStates;
            result.removedStates = removedStates;
            
            results.add(result);
        }

        return results;
    }
    /*
     * This inner class contains the variables being invoked in Opportunity_Support_Document_Record_Creation Flow
     * */
    Public Class CompareStatesBeforeAfterUpdate{
        @InvocableVariable
        Public String oldStates;
        
        @InvocableVariable
        Public String newStates;
    }
    /*
     * This inner class contains the variables that returns list of states to Opportunity_Support_Document_Record_Creation Flow
     * */
    Public Class ResultStates{
        @InvocableVariable
        Public List<String> addedStates;
        
        @InvocableVariable
        Public List<String> removedStates;
    }

}