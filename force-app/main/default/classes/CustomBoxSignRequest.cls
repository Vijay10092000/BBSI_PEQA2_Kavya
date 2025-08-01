/**
 * @description
 * This class facilitates sending Box Sign requests from Salesforce for a set of opportunity documents.
 * It constructs the Box Sign payload (signers, source files, parent folder, and prefill tags),
 * sends the request to Box via HTTP callout, and updates the corresponding Opportunity_Document__c records
 * with the returned sign file IDs and UUIDs. 
 *
 * This class is designed to be invoked from Flow "Support Document E-Signature"
 */
public class CustomBoxSignRequest {
    private static final String EFFECTIVE_DATE_TAG = 'effective_date';
    private static final String SIGNER_ROLE_SIGNER = 'signer';
    private static final String SIGNER_ROLE_APPROVER = 'approver';
    private static final String TYPE_FILE = 'file';
    private static final String TYPE_FOLDER = 'folder';
    
     /**
     * @description Entry point for Flow invocation. Processes each Box sign request parameter set by building payloads,
     * sending callouts, and returning updated opportunity documents with the Box Sign Prepare URL.
     *
     * @param boxSignReqParams List of input parameter sets for each Box Sign request.
     * @return List of ResultParams, each containing updated Opportunity_Document__c records and prepare URL.
     */
    @InvocableMethod
    public static List<CustomBoxSignRequest.ResultParams> makeSignRequest(List<BoxSignRequestParams> boxSignReqParams){
        //list of oppDocs and prepare url to update
        List<CustomBoxSignRequest.ResultParams> results = new List<ResultParams>();

        BoxConnectionEnterpriseAPI obj = new BoxConnectionEnterpriseAPI();
        //obj.authenticate();
        //get the accessToken
        String adminAccessToken = obj.getAccessToken();
		
        //iterate to send sign request
        for(BoxSignRequestParams param:boxSignReqParams){
            //assign signers
            List<BoxSignRequestBuilder.Signer> signers = assignSigners(param.signers);
            
            //assign source files 
            List<BoxSignRequestBuilder.SourceFile> sFiles = assignSourceFiles(param.fileIds);
            
            //assign parent folder
            BoxSignRequestBuilder.ParentFolder pFolder = assignParentFolder(param.parentFolder);
            
            //assign prefill tags
            List<BoxSignRequestBuilder.PrefillTags> pTags = assignTags(param.effectiveDate, param.oppId);

            //create SignRequest
            BoxSignRequestBuilder.SignRequest req = new BoxSignRequestBuilder.SignRequest();
            req.is_document_preparation_needed = true;
            req.parent_folder = pFolder;
            req.prefill_tags = pTags;
            req.signers = signers;
            req.source_files = sFiles;
            req.email_subject = param.emailSubject;
            req.email_message = param.emailMessage;
            req.are_reminders_enabled = param.areRemindersEnabled;
            req.days_valid = param.daysValid;
            
            //make sign request
            try{
                
                HttpResponse res  = sendRequest(req,adminAccessToken, param.boxUserId);
                //deserialize sign response
                BoxSignResponseBuilder deserializedRes = (BoxSignResponseBuilder)JSON.deserialize(res.getBody(),BoxSignResponseBuilder.class);
                //udpate signFileids in Opportunity_Documents
                List<Opportunity_Document__c> oppDocsToUpdate = updateSignFileIds(param.oppDocs,deserializedRes.source_files,deserializedRes.sign_files.files, deserializedRes.id);
                
                //assign updated opportunity documents and prepare url to return to flow
                CustomBoxSignRequest.ResultParams result = new CustomBoxSignRequest.ResultParams();
                result.oppDocs = oppDocsToUpdate;
                result.prepareUrl= deserializedRes.prepare_url;
                result.statusCode = res.getStatusCode();
                results.add(result);
            }catch(CalloutException e){
                throw new CallOutException(e.getMessage());
            }catch(Exception e){
                System.debug('Exception CustomBoxSignRequest @@@@@@:'+e.getMessage());
            }
        }
        return results;
    }
    
    /**
     * @description Assigns signer details to the sign request.
     * @param emails List of signer email addresses.
     * @return List of signer objects for Box Sign request.
     */
    @TestVisible
    private static List<BoxSignRequestBuilder.Signer> assignSigners(List<box.Signer> signers){
        List<BoxSignRequestBuilder.Signer> assignedSigners = new List<BoxSignRequestBuilder.Signer>();
        Integer order=0;
        //signers
        for(box.Signer signer:signers){
            if(signer !=null){
                BoxSignRequestBuilder.Signer assignSigner = new BoxSignRequestBuilder.Signer();
                assignSigner.email = signer.email;
                assignSigner.order=signer.order;
                assignSigner.role = signer.level;
                assignedSigners.add(assignSigner);
            } 
        } 
        return assignedSigners;
    }
    
    /**
     * @description Prepares source file list for the Box Sign request.
     * @param fileIds List of file Ids.
     * @return List of SourceFile objects.
     */
    @TestVisible
    private static List<BoxSignRequestBuilder.SourceFile> assignSourceFiles(List<String> fileIds){
        List<BoxSignRequestBuilder.SourceFile> sFiles = new List<BoxSignRequestBuilder.SourceFile>();
        for(String fId:fileIds){
            BoxSignRequestBuilder.SourceFile file = new BoxSignRequestBuilder.SourceFile();
            file.id= fId;
            file.type=TYPE_FILE;
            sFiles.add(file);
        }
        return sFiles;
    }
    
    /**
     * @description Constructs the parent folder payload for Box Sign request.
     * @param parentFolder Box folder Id.
     * @return ParentFolder object.
     */
    @TestVisible
    private static BoxSignRequestBuilder.ParentFolder assignParentFolder(String parentFolder){
        BoxSignRequestBuilder.ParentFolder pFolder = new BoxSignRequestBuilder.ParentFolder();
        if(String.isNotBlank(parentFolder)){
            pFolder.id=parentFolder;
            pFolder.type= TYPE_FOLDER;
        }
        return pFolder;
    } 
    
    /**
     * @description Builds prefill tags including effective date and BoxSignDisplaySettings metadata-derived tags.
     * @param effectiveDate The date to be prefilled.
     * @param oppId Opportunity Id used to fetch additional tag values.
     * @return List of PrefillTags.
     */
    @TestVisible
    private static List<BoxSignRequestBuilder.PrefillTags> assignTags(String effectiveDate, String oppId){
        List<BoxSignRequestBuilder.PrefillTags> pTags = new List<BoxSignRequestBuilder.PrefillTags>();
        
        //add effective date tag
        effectiveDate = effectiveDate ?? '';
        pTags.add(createTag(EFFECTIVE_DATE_TAG, effectiveDate));
        
        //tags from signDisplaySetting mdt
        Map<String,String> tagsMap = getTags();
        if(tagsMap.values().size() >0){
            Set<String> fields = new Set<String>();
            fields.addAll(tagsMap.values());
            Opportunity opp = getOpportunityValues(fields, oppId);
            Map<String,Object> oppFieldMap = opp.getPopulatedFieldsAsMap();
            //iterate over tags from signDisplaySetting metadata
            for(String externalId:tagsMap.keySet()){
                //assign tag id & value
                String docTagId = externalId;
                String tagValue= '';
                
                String opp_field = tagsMap.get(externalId);
                if(opp_field.contains('.')){
                    List<String> fieldDetails = opp_field.split('\\.');
                    Map<String,Object> field_map = ((SObject)oppFieldMap.get(fieldDetails[0])).getPopulatedFieldsAsMap();
                    //tag value
                    tagValue = (String)field_map.get(fieldDetails[1]);
                }else{
                    //tag value
                    tagValue = (String)oppFieldMap.get(opp_field);
                }          
                //add to list
                pTags.add(createTag(docTagId, tagValue));
            }
        }
        
        return pTags;
    }
    
    /**
     * @description Utility method to create a prefill tag.
     * @param docTagId External tag ID.
     * @param tagValue Value to be filled in the tag.
     * @return PrefillTags object.
     */
    @TestVisible
    private static BoxSignRequestBuilder.PrefillTags createTag(String docTagId, String tagValue){
        BoxSignRequestBuilder.PrefillTags tag = new BoxSignRequestBuilder.PrefillTags();
        tag.document_tag_id=docTagId;
        tag.text_value=tagValue;
        return tag;
    }
    
    /**
     * @description Sends the actual sign request to Box via Http callout.
     * @param signReq Sign request body.
     * @param adminAccessToken Access token of Box App user.
     * @param boxUserId Box user on whose behalf the request is made.
     * @return HttpResponse from Box.
     */
    @TestVisible
    private static HttpResponse sendRequest(BoxSignRequestBuilder.SignRequest signReq, String adminAccessToken, String boxUserId){
        //json request string
        String jsonRequestBody = BoxSignRequestBuilder.buildRequestBody(signReq);
        System.debug('Sign Request body :'+jsonRequestBody);
        
        HttpRequest HttpReq = new HttpRequest();
        HttpReq.setEndpoint('callout:Box_Sign_Requests');
        HttpReq.setMethod('POST');
        HttpReq.setBody(jsonRequestBody);
        HttpReq.setHeader('authorization','Bearer '+adminAccessToken);
        HttpReq.setHeader('As-User',boxUserId);
        HttpReq.setTimeOut(15000);
        HttpResponse res  = new Http().send(HttpReq);
        return res;
    }
    
    /**
     * @description Updates Opportunity_Document__c records with Box sign file IDs and UUIDs.
     * @param oppDocs List of Opportunity_Document__c.
     * @param source_files List of source files from response.
     * @param signFiles List of signed files.
     * @param uuid Sign request UUID.
     * @return List of updated Opportunity_Document__c.
     */
    @TestVisible
    private static List<Opportunity_Document__c> updateSignFileIds(List<Opportunity_Document__c> oppDocs, List<BoxSignResponseBuilder.SourceFile> source_files, List<BoxSignResponseBuilder.SignFile> signFiles, String uuid){
        //list of Opportunity Document to update
        List<Opportunity_Document__c> oppDocsToUpdate = new List<Opportunity_Document__c>();
        //sourceFileIds
        List<String> sourceFileIds = new List<String>();      
        //signFileIds
        List<String> signFileIds = new List<String>();
        
        //assign sourceFilesIds
        for(BoxSignResponseBuilder.SourceFile sFile:source_files){
            sourceFileIds.add(sFile.id);
        }
        
        //assign signFilesIds
        for(BoxSignResponseBuilder.SignFile signFile:signFiles){
            signFileIds.add(signFile.id);
        }
        
        //docIds to find the oppDoc
        List<Id> docIds = new List<Id>();
        for(Opportunity_Document__c oppDoc:oppDocs){
            docIds.add(oppDoc.Document__c);
        }
        //map of document
        Map<Id,Document__c> docMap = new Map<Id,Document__c>(getDocumentsByIds(docIds));
        
        for(Opportunity_Document__c oppDoc:oppDocs){
            Document__c doc = docMap.get(oppDoc.Document__c);	//get document related to opportunity document
            if(String.isNotBlank(doc.Box_Template_Id_1__c)){
                Integer index = sourceFileIds.indexOf(doc.Box_Template_Id_1__c);
                if(index!=-1 && index!=null){	//if list element not found then list will return -1
                    String signFileId = signFileIds.get(index);
                    oppDoc.Box_File_Id__c = signFileId;
                    oppDoc.Box_Sign_UUID__c = uuid;
                    oppDocsToUpdate.add(oppDoc);
                }
            }
        }
        return oppDocsToUpdate;
    }
    
    /**
     * @description Queries metadata settings to fetch prefill tag mappings.
     * @return Map of document tag external IDs to Opportunity field names.
     */
    @TestVisible
    public static Map<String,String> getTags(){
        Map<String,String> tagsMap = new Map<String,String>();
        
        try{
            //query boxSignDisplaySetting metadata for opportunity object
            String boxSignSetting = [ SELECT box__Object_Name__c,box__Object_Settings__c FROM box__BoxSignDisplaySetting__mdt WHERE DeveloperName = 'Opportunity' ].box__Object_Settings__c;
            
            if(String.isNotBlank(boxSignSetting)){
                //deserialize the json response
                BoxSignDisplaySettingMdtBuilder signDisplaySettings = (BoxSignDisplaySettingMdtBuilder)JSON.deserialize(boxSignSetting, BoxSignDisplaySettingMdtBuilder.class);
                
                //iterate over prefill data
                for(BoxSignDisplaySettingMdtBuilder.PrefillData pData: signDisplaySettings.prefillData){
                    if(String.isNotBlank((String)pData.prefillTagExternalValue)){
                        tagsMap.put((String)pData.prefillTagExternalValue, pData.prefilledTagTypeValue);
                    }
                }
            }
        }catch(QueryException e){
            throw new QueryException(e.getMessage());
        }
        return tagsMap;
    }
    
    /**
     * @description Dynamically queries the Opportunity record using fields from metadata.
     * @param fields List of fields to query.
     * @param oppId Opportunity Id.
     * @return Opportunity SObject with queried fields.
     */
    @TestVisible
    private static Opportunity getOpportunityValues(Set<String> fields, String oppId){
        Opportunity opp = new Opportunity();
        String query = 'SELECT ' + String.join(fields, ',') + ' FROM Opportunity WHERE Id = :oppId';
        try{
            opp = Database.query(query);
        }catch(QueryException e){
            throw new QueryException(e.getMessage());
        }
        return opp;
    }
    
    /**
     * @description Retrieves documents used in opportunity document association.
     * @param docIds List of document IDs.
     * @return List of Document__c records.
     */
    @TestVisible
    private static List<Document__c> getDocumentsByIds(List<Id> docIds){
        List<Document__c> docs = new List<Document__c>();
        try{
            docs = [ SELECT Id,Box_Template_Id_1__c FROM Document__c WHERE Id IN :docIds ];
        }catch(QueryException e){
            throw new QueryException(e.getMessage());
        }
        return docs;
    }
    
    /**
     * @description Wrapper class used to return results back to the Flow. It contains the list of updated
     * Opportunity_Document__c records and the Box Sign prepare URL.
     */
    public class ResultParams{
        @InvocableVariable
        public List<Opportunity_Document__c> oppDocs;
        @InvocableVariable
        public String prepareUrl;
        @InvocableVariable
        public Integer statusCode;
    }
}