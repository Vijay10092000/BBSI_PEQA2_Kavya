/*
 * Opportunity_E_Signature_Box flow invokes this apex class
 * @description This class handles the retrieval of the latest Box sign request for a user and updates the associated
 * Opportunity_Document__c records with file IDs from Box.
*/
public class BoxSignRequestsForUser {
    // Constant to identify unique sign requests in Box
    private static final String SF_UNIQUE_SIGN_REQUEST_VALUE = 'sf_unique_id_sign_request';
	
    /**
     * @description Invocable method to retrieve the latest sign request details from Box and update Opportunity_Document__c records.
     * @param oppdocs A list of Opportunity_Document__c records grouped in a nested list.
     * @return A list of updated Opportunity_Document__c records, encapsulated in a nested list.
     */
    @InvocableMethod
    public static List<List<Opportunity_Document__c>> getLatestSignRequest(List<BoxSignRequestsForUser.RequestParameters> params){
        
        List<List<Opportunity_Document__c>> results = new List<List<Opportunity_Document__c>>();
        
        for(RequestParameters param: params){   
            String timeStamp = param.timeStamp;
            List<Opportunity_Document__c> oppDocs = param.oppDocs;
            String box_uuid = '';
            String responseBody = BoxCustomAPIRequest.getSignRequests();
            if(responseBody != null || responseBody != ''){
                //list to store all source files of latest sign request
                List<Object> latestSourceFileList = new List<Object>();
                //list to store all sign files of latest sign request
                List<Object> latestSignFileList = new List<Object>();
                //list to update Opportunity_Document__c
                List<Opportunity_Document__c> oppDocsToUpdate = new List<Opportunity_Document__c>();
                // Parse the JSON response
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                // Get the "entries" list from the response
                if (responseMap.containsKey('entries')) {
                    List<Object> entries = (List<Object>) responseMap.get('entries');
                    // Iterate over entries
                    //System.debug('Entries :'+entries);
                    //String Id = ''; Integer maxTimeStamp = 0;
                    for (Object entry : entries) {
                        Map<String, Object> entryMap = (Map<String, Object>) entry;
                        if (entryMap.containsKey('prefill_tags')) {
                            List<Object> prefillTags = (List<Object>) entryMap.get('prefill_tags');
                            // Iterate over the prefill tags and extract document_tag_id
                            for (Object tag : prefillTags) {
                                Map<String, Object> tagMap = (Map<String, Object>) tag;
                                if(tagMap.containsKey('document_tag_id')){
                                    if((String)tagMap.get('document_tag_id') == SF_UNIQUE_SIGN_REQUEST_VALUE){
                                        String timeStampFromResponse = (String) tagMap.get('text_value');
                                        if(timeStamp == timeStampFromResponse){
                                            latestSourceFileList = (List<Object>)entryMap.get('source_files');		 
                            				Map<String,Object> signFilesMap = (Map<String,Object>)entryMap.get('sign_files');   //sign files is object
                                            latestSignFileList = (List<Object>)signFilesMap.get('files');	
                                            if(entryMap.containsKey('id')){
                                                box_uuid = (String)entryMap.get('id');
                                            }
                                        }
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    //get Opportunity_Documents__c to update
                    oppDocsToUpdate = getFileIdsFromSignRequest(box_uuid, latestSourceFileList, latestSignFileList, oppDocs);
                   	results.add(oppDocsToUpdate);
                }
            }
        }
        return results;
    }
    
    /**
     * @description Retrieves and maps file IDs from the latest sign request to Opportunity_Document__c records.
     * @param latestSourceFileList A list of source files from the latest sign request.
     * @param latestSignFileList A list of sign files from the latest sign request.
     * @param oppDocs A list of Opportunity_Document__c records to update.
     * @return A list of updated Opportunity_Document__c records.
     */
    @TestVisible
    private static List<Opportunity_Document__c> getFileIdsFromSignRequest(String box_uuid, List<Object> latestSourceFileList, List<Object> latestSignFileList, List<Opportunity_Document__c> oppDocs ){
        //list of sourceFileIds
        List<String> sourceFileIdsList = new List<String>();
        //list of signFileIds
        List<String> signFileIdsList = new List<String>();
        //box_template_id__1__c as key, index as value
        Map<String,String> oppDocwithDocumentMap = new Map<String,String>();
        
        box__BoxSign__c boxSign ;
        //get the Box Sign records based on uuid
        if(String.isNotBlank(box_uuid)){
            System.debug('box UUID:'+box_uuid);
            List<box__BoxSign__c> bSignList = [ SELECT Id FROM box__BoxSign__c WHERE box__Uuid__c = :box_uuid LIMIT 1 ];
            if (bSignList != null  &&  bSignList.size() > 0) {
                boxSign = bSignList[0];
            }
            System.debug('boxSign Records :'+boxSign);
        }
        
        // Create a list of Source Files (same as "Box_Template_Id_1__c" on Document__c object)
        if(!latestSourceFileList.isEmpty() && latestSourceFileList != null){
            //iterate over latest source files list and store file ids 
            for(Object file:latestSourceFileList){
                Map<String,Object> fileMap = (Map<String,Object>)file;
                if(fileMap.containsKey('id')){
                    sourceFileIdsList.add((String)fileMap.get('id'));
                }
            }     
        }
        
        if(!latestSignFileList.isEmpty() && latestSignFileList != null){
            //iterate over latest sign files list and store file ids
            for(Object file:latestSignFileList){
                Map<String,Object> fileMap = (Map<String,Object>)file;
                if(fileMap.containsKey('id')){
                    signFileIdsList.add((String)fileMap.get('id'));
                }
            }
        }

        // Prepare a map of Document__c to Opportunity_Document__c record Ids
        for(Opportunity_Document__c oppDoc: oppDocs){
            oppDocwithDocumentMap.put((String)oppDoc.Document__c,String.valueOf(oppDoc.Id));
        }
        
        //get list of Document__c by Id
		// Fetch list of Document__c records from Opportunity_Document__c. 
		// These Document__c records will be ones that were selected on the UI for sending to the Recipient for Signing.
        List<Document__c> documents = getDocumentsById(oppDocwithDocumentMap.keySet());
        
        
        //document__c as key, Box_Template_Id_1__c as value
        // Create a map of Document__c record id with Box File Template Id. 
        // The Box File Template Id is the same as in SourceFileList
        for (Document__c doc: documents) {
            String docId = String.valueOf(doc.Id);
            if(oppDocWithDocumentMap.containsKey(String.valueOf(docId))){
                oppDocWithDocumentMap.put(docId,doc.Box_Template_Id_1__c);
            }
        }
        
        // Iterate over Opportunity_Document records to udpate fileId
        for (Opportunity_Document__c oppDoc: oppDocs) {
            
            //get Box_Template_id_1__c by using document from oppDocWithDocumentMap
            // Based on Document__c on OppDoc, get the Box File Template Id
            String boxTemplateId = oppDocWithDocumentMap.get(oppDoc.Document__c);
            
            if(sourceFileIdsList.contains(boxTemplateId)){
                
                // From Box Template Id, find the index in the SourceFileList
                Integer index = sourceFileIdsList.indexOf(boxTemplateId);
                
                // Search for file in SignFilesList based on this same index, 
                // and set that SignFile on the OppDoc record.
                oppDoc.Box_File_Id__c = signFileIdsList.get(index);
                oppDoc.Box_Sign_UUID__c = box_uuid;
                if( boxSign != null ){
                    oppDoc.Box_Sign__c = boxSign.Id;
                }
                
                //remove the assigned sourceFileIds and signFileIds from the lists
                sourceFileIdsList.remove(index);
                signFileIdsList.remove(index);
            }
        }
        return oppDocs;
    }
    
    /**
     * Fetches Document__c records by their IDs.
     * @param docIds A set of Document__c IDs to query.
     * @return A list of Document__c records.
     */
    @TestVisible
    private static List<Document__c> getDocumentsById(Set<String> docIds){
        return [ SELECT Id,Box_Template_Id_1__c FROM Document__c WHERE Id IN :docIds ];
    }
    
    public class RequestParameters{
        @InvocableVariable(label='Timestamp' description='Timestamp used in prefill Tags')
        public String timeStamp;
        @InvocableVariable(label='Opportunity Documents' description='Opportunity Document that user selected')
        public List<Opportunity_Document__c> oppDocs;
    }
}