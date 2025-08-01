/*
 * @description this class will fetch Document__c records based on Opportunity recordType, Comp Option, Mark Up Type, States of Operation.
 * this class will be invoked by Opportunity_Support_Document_Record_Creation flow
 * 
 *  Key functionality includes:
 * - Deleting old Opportunity_Document__c records
 * - Fetching new Document__c records matching the new Opportunity values
 * - Returning relevant Document__c records to the flow for further creation
*/

public class DocumentRecordCreationHandler {
    
    private static final String OPP_RECORDTYPE_NEW = 'New';
    private static final String OPP_RECORDTYPE_PEO = 'PEO';
    private static final String OPP_COMP_OPTION_INCENTIVE = 'Lease (incentive)';
    private static final String OPP_COMP_OPTION_NO_INCENTIVE = 'Lease (no incentive)';
    private static final String NO_COMP = 'No Comp';
    private static final String documentWithComp = 'With Comp';
    
    public static String customerType;
    public static String productType;
    public static String compOption;
    public static String markupType;
    public static Boolean allStates;
    public static Boolean notAllStates;
    
    public static List<Opportunity_Document__c> recordsToDelete = new List<Opportunity_Document__c>();
    public static List<Id> oppIds = new List<Id>();
    //store udpated values for creation
    public static Set<String> newStateNames = new Set<String>();
    public static List<String> oppStates = new List<String>();
    public static Set<String> newCustomerTypes = new Set<String>();
    public static Set<String> newProductTypes = new Set<String>();
    public static Set<String> newCompOptions = new Set<String>();
    public static Set<String> newMarkupTypes = new Set<String>();
    
    //store old values for deletion
    public static Set<String> oldStateNames = new Set<String>();
    public static Set<String> oldCustomerTypes = new Set<String>();
    public static Set<String> oldProductTypes = new Set<String>();
    public static Set<String> oldCompOptions = new Set<String>();
    public static Set<String> oldMarkupTypes = new Set<String>();
    /*
     * @description this method fetches Document__c records based on Opportunity fields
     * @param reqParams are parameters that are given as inputs in flow: Opportunity_Support_Document_Record_Creation
     * @return list of Document__c records
    */
    @InvocableMethod
    Public static List<List<Document__c>> getRecords(List<RequestParams> reqParams){ 
        List<List<Document__c>> allRecordsToCreate = new List<List<Document__c>>();
        for(RequestParams params:reqParams){
            notAllStates = params.notAllStatesHandler;
            allStates = params.allStates;
            //new values
            String newCustomerType = params.recordTypeIds.contains(params.newOpp?.RecordTypeId) ? OPP_RECORDTYPE_NEW : '';
            String newProductType = params.recordTypeIds.contains(params.newOpp?.RecordTypeId) ? OPP_RECORDTYPE_PEO : '';  
            String newCompOption;
            
            if(params.newOpp?.Comp_Option__c == OPP_COMP_OPTION_NO_INCENTIVE || params.newOpp?.Comp_Option__c == OPP_COMP_OPTION_INCENTIVE){
                newCompOption = documentWithComp;
            }else{
                newCompOption = params.newOpp?.Comp_Option__c;
            }
            newCustomerTypes.add(newCustomerType);
            newProductTypes.add(newProductType);
            newCompOptions.add(newCompOption);
            newMarkupTypes.add(params.newOpp?.Markup_Type__c);
            if(params.addedStateNames != null ){
                newStateNames.addAll(params.addedStateNames);
            }
            System.debug('New State names :'+newStateNames);
            oppStates = params.newOpp?.States_of_Operation__c?.split(';');

            //old Values
            String oldCustomerType = params.recordTypeIds.contains(params.oldOpp?.RecordTypeId) ? OPP_RECORDTYPE_NEW : '';
            String oldProductType = params.recordTypeIds.contains(params.oldOpp?.RecordTypeId) ? OPP_RECORDTYPE_PEO : '';
            String oldCompOption;
            if(params.oldOpp?.Comp_Option__c == OPP_COMP_OPTION_NO_INCENTIVE || params.oldOpp?.Comp_Option__c == OPP_COMP_OPTION_INCENTIVE){
                oldCompOption = documentWithComp;
            }else{
                oldCompOption = params.oldOpp?.Comp_Option__c;
            }
            oppIds.add(params.oldOpp?.Id);
            oldCustomerTypes.add(oldCustomerType);
            oldProductTypes.add(oldProductType);
            oldCompOptions.add(oldCompOption);
            oldMarkupTypes.add(params.oldOpp?.Markup_Type__c);
            if( params.removedStateNames != null ){
                oldStateNames.addAll(params.removedStateNames);
            }
            //to delete the Opportunity Document Records
            deleteOppDocRecords();
            
            //get the Document records to create new Opportunity Document Records
            List<Document__c> recordsToCreate = getDocumentRecordsToCreate();   
            allRecordsToCreate.add(recordsToCreate);
        }
		System.debug(LoggingLevel.INFO, 'Document Record Creation handler SOQL QUERY COUNT: ' + Limits.getQueries());
        return allRecordsToCreate;
    }
    
    /**
     * @description
     * Constructs the SOQL query for deleting old Opportunity_Document__c records based on prior field values.
     * 
     * @return SOQL query string if there are records to delete, empty string otherwise
     */
    @TestVisible
    Private static String generateDeleteOppDocsQueryString(){
        String query = 'SELECT Id,State__c FROM Opportunity_Document__c WHERE Opportunity__c IN :oppIds';
        Boolean flag = true;
        if( notAllStates && (oldStateNames != null && oldStateNames.size() > 0) && !oldStateNames.equals(newStateNames) ){
            query += ' AND State__c IN :oldStateNames';
            flag = false;
            System.debug('Inside States query :');
        }
        else{
            query += ' AND (';
            if((newCustomerTypes.contains(null)) && (oldCustomerTypes != null && oldCustomerTypes.size() > 0) && !oldCustomerTypes.equals(newCustomerTypes)){
                customerType = String.join(new List<String>(oldCustomerTypes),',');
                query += (flag ? '' : ' OR ')+' Document__r.Customer_Type__c INCLUDES (:customerType)';
                flag = false;
            }else if((oldCustomerTypes != null && oldCustomerTypes.size() > 0) && !oldCustomerTypes.equals(newCustomerTypes)){
                query += ' Document__r.Customer_Type__c IN :oldCustomerTypes';
                flag = false;
            }
            if((newProductTypes.contains(null)) && (oldProductTypes != null && oldProductTypes.size() > 0) && !oldProductTypes.equals(newProductTypes)){
                productType = String.join(new List<String>(oldProductTypes),',');
                query += (flag ? '' : ' OR ')+' Document__r.Product_Type__c INCLUDES (:productType)';
                flag = false;
            }else if((oldProductTypes != null && oldProductTypes.size() > 0) && !oldProductTypes.equals(newProductTypes)){
                query += (flag ? '' : ' OR ')+' Document__r.Product_Type__c IN :oldProductTypes';
                flag = false;
            }
            if(!newCompOptions.contains(documentWithComp) && !newCompOptions.contains(NO_COMP) && (oldCompOptions != null && oldCompOptions.size() > 0) && !oldCompOptions.equals(newCompOptions)){
                compOption = String.join(new List<String>(oldCompOptions),',');
                query += (flag ? '' : ' OR ')+' Document__r.Comp_Option__c INCLUDES (:compOption)';
                flag = false;
            }else if((oldCompOptions != null && oldCompOptions.size() > 0) && !oldCompOptions.equals(newCompOptions)){
                query += (flag ? '' : ' OR ')+' Document__r.Comp_Option__c IN :oldCompOptions';
                flag = false;
            } 
            if(newMarkupTypes.contains(null) && (oldMarkupTypes != null && oldMarkupTypes.size() > 0) && !oldMarkupTypes.equals(newMarkupTypes)){
                markupType = String.join(new List<String>(oldMarkupTypes),',');
                query += (flag ? '' : ' OR ')+' Document__r.Markup_Type__c INCLUDES (:markupType)';
                flag = false;
            }
            else if((oldMarkupTypes != null && oldMarkupTypes.size() > 0) && !oldMarkupTypes.equals(newMarkupTypes)){
                query += (flag ? '' : ' OR ') +' Document__r.Markup_Type__c IN :oldMarkupTypes';
                flag = false;
            }
            query += ' )';
        }
        if(!flag){
            //delete the Old Opportunity Document records
            //deleteOppDocRecords(query);
            return query;
        }
        return '';
        
    }
    
      /**
     * @description
     * Executes the generated delete query and deletes old Opportunity_Document__c records
     */
    
    @TestVisible
    Private static void deleteOppDocRecords(){
        List<Opportunity_Document__c> getOppDocToDelete = new List<Opportunity_Document__c>();
        String query = generateDeleteOppDocsQueryString();
        if(String.isNotEmpty(query) && query != ''){
            //execute query
            getOppDocToDelete = Database.query(query);
            if(!getOppDocToDelete.isEmpty()){
                try{
                    System.debug('OppDoc Record To Delete :'+getOppDocToDelete);
                    DELETE getOppDocToDelete;
                }catch(Exception e){
                    System.debug('Error in Deleting Opportunity Document Records :'+e.getMessage());
                }
                
            }
        }
    }
    
    /**
     * @description
     * Determines whether to fetch Document__c records for 'All States' or specific states.
     * Delegates the fetch to getDocuments().
     *
     * @return List of Document__c records matching the new Opportunity field values
     */
    @TestVisible
    Private static List<Document__c> getDocumentRecordsToCreate(){
        customerType = '(\'' + String.join(newCustomerTypes, '\', \'') + '\')';
        productType = '(\'' + String.join(newProductTypes, '\', \'') + '\')';
        compOption = '(\'' + String.join(newCompOptions, '\', \'') + '\')';
        markupType = '(\'' + String.join(newMarkupTypes, '\', \'') + '\')';
        List<Document__c> documentRecords = new List<Document__c>();
        
        if(notAllStates){
            try{
                Set<String> states = new Set<String>();
                states.addAll(newStateNames);
                states.addAll(oppStates);
                documentRecords = getDocuments(states);
            }catch(Exception e){
                System.debug('Exception while fetching  Document Records:'+e.getMessage());
            }
        }
        else if( allStates ){
            try{
                documentRecords = getDocuments(new Set<String>{'All States'});
            }catch(DmlException e){
                System.debug('Exception while fetching  Document Record:'+e.getMessage());
            }
        }
        return documentRecords;
    }
    
    /**
     * @description
     * Queries Document__c records filtered by state, customer type, product type, comp option, and markup type.
     *
     * @param statesList List of state values to filter on
     * @return List of matching Document__c records
     */
    @TestVisible
    private static List<Document__c> getDocuments(Set<String> statesList){
        String statesListStr = '(\'' + String.join(statesList, '\', \'') + '\')';    
        String query = 'SELECT Id,RecordType.Id,RecordType.DeveloperName,Deprecated__c, Contact_Based__c FROM Document__c WHERE State__c IN '+statesListStr+
    			' AND Customer_Type__c INCLUDES '+customerType+
    			' AND Product_Type__c INCLUDES '+productType+
    			' AND Comp_Option__c INCLUDES '+compOption+
    			' AND Markup_Type__c INCLUDES '+markupType;
        List<Document__c> docs = new List<Document__c>();
        try{
            docs = Database.query(query);
        }catch(Exception e){
            throw new QueryException(e.getMessage());
        }
        return docs;
    }
    
    /**
     * @description
     * Invocable input class for the Flow to pass in both the new and old Opportunity records, as well as state changes.
     */
    Public class RequestParams{
        @InvocableVariable(Label='Added States List')
        Public List<String> addedStateNames;
        @InvocableVariable(Label='Removed States List')
        Public List<String> removedStateNames;
        @InvocableVariable(Label='Prior Opportunity')
        Public Opportunity oldOpp;
        @InvocableVariable(Label='Triggering Opportunity')
        Public Opportunity newOpp;
        @InvocableVariable(Label='Opportunity RecordTypeIds')
        Public List<String> recordTypeIds;
        @InvocableVariable(Label='Not All States')
        Public Boolean notAllStatesHandler;
        @InvocableVariable(Label='All States')
        Public Boolean allStates;
    }
}