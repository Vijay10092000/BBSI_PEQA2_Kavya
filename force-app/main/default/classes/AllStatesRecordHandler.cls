public class AllStatesRecordHandler {
    
    /*
     * @description Compares `Document__c` records with `Opportunity_Document__c` records and identifies:
     *              1. Records in `Document__c` that are not in `Opportunity_Document__c` (added records).
     *              2. Records in `Opportunity_Document__c` that are not in `Document__c` (removed records).
     * @param params A list of `RequestParams` containing:
     *               - allStateDocumentRecords: List of `Document__c` records.
     *               - allStatesOppDocRecords: List of `Opportunity_Document__c` records.
     * @return A list of `ResultParams` containing:
     *         - addedAllStatesRecords: List of `Document__c` records to be added.
     *         - removedAllStatesRecords: List of `Opportunity_Document__c` records to be removed.
     */
    @InvocableMethod
    public static List<ResultParams> checkAllStateRecords(List<RequestParams> params) {
        List<ResultParams> results = new List<ResultParams>();

        for (RequestParams param : params) {
            try {
                // Lists to store added and removed records
                List<Document__c> addedAllStatesRecords = new List<Document__c>();
                List<Opportunity_Document__c> removedAllStatesRecords = new List<Opportunity_Document__c>();

                // map Document__c records by their Ids
                Map<Id, Document__c> documentsAllStates = (param.allStateDocumentRecords != null) 
                    ? new Map<Id, Document__c>(param.allStateDocumentRecords) 
                    : new Map<Id, Document__c>();
				// map Opportunity_Document__c records by their Ids
                Map<Id, Opportunity_Document__c> oppDocAllStates = (param.allStatesOppDocRecords != null) 
                    ? new Map<Id, Opportunity_Document__c>(param.allStatesOppDocRecords) 
                    : new Map<Id, Opportunity_Document__c>();

                // Map Opportunity_Document__c records by their Document__c ID
                Map<Id, Opportunity_Document__c> oppDocMap = new Map<Id, Opportunity_Document__c>();
                for (Opportunity_Document__c oppDoc : oppDocAllStates.values()) {
                    if (oppDoc.Document__c != null) {
                        oppDocMap.put(oppDoc.Document__c, oppDoc);
                    }
                }

                if(!documentsAllStates.isEmpty()){
                    // Identify added All States Document Records
                    for (Id docId : documentsAllStates.keySet()) {
                        if (!oppDocMap.containsKey(docId)) {
                            addedAllStatesRecords.add(documentsAllStates.get(docId));
                        }
                    }
                }

                if(!oppDocMap.isEmpty()){
                    // Identify removed All States Document Records
                    for (Id docId : oppDocMap.keySet()) {
                        if (!documentsAllStates.containsKey(docId)) {
                            removedAllStatesRecords.add(oppDocMap.get(docId));
                        }
                    }
                }

                // Prepare result for this specific request
                ResultParams result = new ResultParams();
                result.addedAllStatesRecords = addedAllStatesRecords;
                result.removedAllStatesRecords = removedAllStatesRecords;
                
                results.add(result);
                
            } catch (Exception e) {
                System.debug('Error in checkAllStateRecords: ' + e.getMessage());
            }
        }

        return results; // Ensure one result per input request
    }

    /**
     * @description Class to encapsulate request parameters passed to the invocable method.
     * Contains lists of `Document__c` and `Opportunity_Document__c` records.
     */
    public class RequestParams {
        @InvocableVariable
        public List<Document__c> allStateDocumentRecords;
        @InvocableVariable
        public List<Opportunity_Document__c> allStatesOppDocRecords;
    }

    /**
     * @description Class to encapsulate result parameters returned by the invocable method.
     * Contains lists of added and removed records.
     */
    public class ResultParams {
        @InvocableVariable
        public List<Opportunity_Document__c> removedAllStatesRecords;
        @InvocableVariable
        public List<Document__c> addedAllStatesRecords;
    }
}