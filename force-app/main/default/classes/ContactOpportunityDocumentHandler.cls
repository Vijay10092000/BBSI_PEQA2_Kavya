/**
 * @description This class is invoked by a Flow or Process Builder to fetch `Document__c` records 
 * based on related Opportunity field values and then creates `Opportunity_Document__c` records 
 * for those documents while associating a Contact as the signer.
 *
 * The logic filters Document__c records based on:
 * - Customer Type ('New')
 * - Product Type ('PEO')
 * - Comp Option (e.g., 'With Comp' or 'No Comp')
 * - Markup Type
 * - State of Operation
 * 
 * The handler ensures the document is:
 * - Not deprecated
 * - Has Contact_Based__c = true
 * - Has record type 'Support_Documents' or 'Underwriting_Documents'
 */
public class ContactOpportunityDocumentHandler {
    
    /**
     * @description This method is invoked from a Flow:Contact: Create Opportunity Documents using the @InvocableMethod annotation.
     * It builds filters using provided Opportunity fields and fetches matching Document__c records.
     * For each Document__c, it creates corresponding Opportunity_Document__c records with links
     * to the Opportunity and Contact.
     * 
     * @param params A list of RequestParams containing the Contact and related Opportunities
     * @return A list of Opportunity_Document__c record lists to be created for each input item
     */
    @InvocableMethod
    public static List<List<Opportunity_Document__c>> getOpportunityDocuments(List<RequestParams> params){
        //to final results
        List<List<Opportunity_Document__c>> results = new List<List<Opportunity_Document__c>>();
        
        Set<String> customerTypes = new Set<String>{'New'};
        Set<String> productTypes = new Set<String>{'PEO'};
        Set<String> compOptions = new Set<String>();
        Set<String> markupTypes = new Set<String>();
        Set<String> states = new Set<String>{'All States'};
        
        //set to store oppId
        Set<Id> oppIds = new Set<Id>();
        //set to store contactId
        Set<Id> contactIds = new Set<Id>();
        
        List<Opportunity> opps = new List<Opportunity>();
        for(RequestParams param:params){
            if(param.contact != null){
                contactIds.add(param.contact.Id);
            }
            if(param.opportunities != null){
                for(Opportunity opp:param.opportunities){
                    oppIds.add(opp.Id);			//adding OppIds to set
                    if(String.isNotBlank(opp.Markup_Type__c)){
                        markupTypes.add(opp.Markup_Type__c);
                    }
                    if(String.isNotBlank(opp.Comp_Option__c)){
                        String compOption='';
                        if(opp.Comp_Option__c == 'Lease (incentive)' || opp.Comp_Option__c=='Lease (no incentive)'){
                            compOption = 'With Comp';
                        }else if(opp.Comp_Option__c == 'No Comp'){
                            compOption = opp.Comp_Option__c;
                        }
                        compOptions.add(compOption);
                    }
                    if(String.isNotBlank(opp.States_of_Operation__c)){
                        List<String> statesList = opp.States_of_Operation__c.split(';');
                        states.addAll(statesList);
                    }
               }
            }
            
            System.debug('Contact Ids :'+contactIds);
            System.debug('Opp Ids :'+oppIds);
            //get the document based on filters
            List<Document__c> docs = getDocumentsToCreate(customerTypes, productTypes, compOptions, markupTypes, states);
            System.debug('Documents :'+docs);
            
            //to create new Opportunity Document with Document__c that are not added to Document__c
            List<Opportunity_Document__c> oppDocsToCreate = new List<Opportunity_Document__c>();
            
            //create new Opportunity Document's for the Documents 
            for(Document__c doc:docs){
                for(Id oppId:oppIds){
                    Opportunity_Document__c oppDoc = new Opportunity_Document__c(Document__c=doc.Id,
                                                                                 Opportunity__c = oppId);
                    oppDocsToCreate.add(oppDoc);
                }
            }
            
            //assign contact signer for all newly created Opportunity Document
            for(Opportunity_Document__c oppDoc:oppDocsToCreate){  
                for(Id contactId:contactIds){
                    oppDoc.Contact_Signer__c = contactId;
                }
            } 
            System.debug('Final oppDocs To Create :'+oppDocsToCreate);
            results.add(oppDocsToCreate);
        }
        return results;
    }
    
    /*
     * @description this method will query Document__c based on filters
     * @params customerTypes 
     * */
    @TestVisible
    private static List<Document__c> getDocumentsToCreate(Set<String> customerTypes, Set<String> productTypes,Set<String> compOptions, Set<String> markupTypes, Set<String> states ){
        //convert set of string values to comma separated string
        String customerTypeStr = '(\'' + String.join(customerTypes, '\', \'') + '\')';
        String markupTypeStr = '(\'' + String.join(markupTypes, '\', \'') + '\')';
        String productTypeStr = '(\'' + String.join(productTypes, '\', \'') + '\')';
        String compOptionStr = '(\'' + String.join(compOptions, '\', \'') + '\')';
        String statesListStr = '(\'' + String.join(states, '\', \'') + '\')';
        
        System.debug('Customer Type :'+customerTypeStr);
        System.debug('Product Type :'+productTypeStr);
        System.debug('Comp Option :'+compOptionStr);
        System.debug('Markup Type :'+markupTypeStr);
        
        //fetch documents based on filters from opportunity, deprecated false, record type equal to Support_Document or Underwriting_Documents, Contact_Based is true
        String query = 'SELECT Id, Contact_Based__c, Comp_Option__c FROM Document__c WHERE State__c IN '+statesListStr+
            ' AND Customer_Type__c INCLUDES '+customerTypeStr+
            ' AND Product_Type__c INCLUDES '+productTypeStr+
            ' AND Comp_Option__c INCLUDES '+compOptionStr+
            ' AND Markup_Type__c INCLUDES '+markupTypeStr+
            ' AND Deprecated__c = false'+
            ' AND ( RecordType.DeveloperName = '+'\'Support_Documents\''+' OR RecordType.DeveloperName = '+'\'Underwriting_Documents\' )'+
            ' AND Contact_Based__c = true ';
        List<Document__c> docs = new List<Document__c>();
        try{
			//execute query
            docs = Database.query(query);
        }catch(Exception e){
            //throw exception
            throw new QueryException(e.getMessage());
        }
        
        //return
        return docs;
    }
    
    
    public class RequestParams{
        @InvocableVariable
        public Contact contact;
        @InvocableVariable
        public List<Opportunity> opportunities;
    }
}