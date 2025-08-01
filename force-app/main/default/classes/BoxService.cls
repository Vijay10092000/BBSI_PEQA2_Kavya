/**
 * @description
 * BoxService provides a reusable service layer to interact with the Box.com API
 * through the Box Toolkit. It handles common file and folder operations like:
 * - Retrieving file IDs from a folder
 * - Copying files to a folder
 * - Creating Box folders for Salesforce records
 * - Uploading files from Attachments
 */
public without sharing class BoxService {
    private String CONTENT_TYPE='content-type';
    private String CONTENT_TYPE_VALUE='application/json';
    private Box.Toolkit toolkit;
    private static List<Box_Create_Metadata_Fields__mdt> createMetadataFields;
    private static List<Box_Update_Metadata_Fields__mdt> updateMetadataFields;

    
    /**
     * @description
     * Constructor initializes the Box.Toolkit instance used across all service calls.
     */
    public BoxService() {
        toolkit = new Box.Toolkit();
    }

    
    /**Used for User Story 77661: Box for Salesforce- Copy files from a Closed-Won Additional Product Opp for Auto-created Cases
     * @description
     * Retrieves a list of file IDs from the given Box folder.
     * 
     * @param folderId The Box folder ID to retrieve file entries from.
     * @return A list of Box file IDs contained within the folder.
     * @throws BoxServiceException if the API response is unsuccessful.
     */
    public List<String> getFilesInFolder(String folderId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Box_Callout_Endpoint__mdt.getInstance('Folder_GET').Box_Endpoint__c + folderId + '/items');
        req.setMethod('GET');
        
        HttpResponse res = new HttpResponse();
        if (Test.isRunningTest()) {
            Http h = new Http();
            res = h.send(req);
        } else {
            res = toolkit.sendRequest(req);
        }
        
        if (res.getStatusCode() != 200) {
            throw new BoxServiceException(parseError(res));
        }

        List<String> fileIds = new List<String>();
        Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        for (Object entry : (List<Object>) json.get('entries')) {
            Map<String, Object> file = (Map<String, Object>) entry;
            if ((String) file.get('type') == 'file') {
                fileIds.add((String) file.get('id'));
            }
        }
        return fileIds;
    }

    
    /**Used for User Story 77661: Box for Salesforce- Copy files from a Closed-Won Additional Product Opp for Auto-created Cases
     * @description
     * Copies a file in Box to another target folder.
     * 
     * @param fileId         The ID of the file to be copied.
     * @param targetFolderId The ID of the destination Box folder.
     * @throws BoxServiceException if the copy operation fails.
     */
    public void copyFile(String fileId, String targetFolderId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Box_Callout_Endpoint__mdt.getInstance('File_POST').Box_Endpoint__c + fileId + '/copy');
        req.setMethod('POST');
        req.setBody(JSON.serialize(new Map<String, Object>{
            'parent' => new Map<String, Object>{ 'id' => targetFolderId }
        }));

        HttpResponse res = new HttpResponse();
        if (Test.isRunningTest()) {
            Http h = new Http();
            res = h.send(req);
        } else {
            res = toolkit.sendRequest(req);
        }
        
        if (res.getStatusCode() != 201) {
            throw new BoxServiceException('Copy failed → ' + parseError(res));
        }
    }

    
    /**Used for User Story 77661: Box for Salesforce- Copy files from a Closed-Won Additional Product Opp for Auto-created Cases
     * @description
     * Creates a Box folder for the given Salesforce record ID using Box Toolkit.
     * 
     * @param recordId The Salesforce record ID to associate the folder with.
     * @return The newly created folder ID.
     * @throws BoxServiceException if the folder creation fails.
     */
    public String createFolderForRecord(Id recordId) {
        String folderId = toolkit.createFolderForRecordId(recordId, null, true);
        if (Test.isRunningTest()) {
            folderId = '99999';
        }
        if (String.isEmpty(folderId)) {
            throw new BoxServiceException('Folder creation failed → ' + toolkit.mostRecentError);
        }
        return folderId;
    }

    
    /**Used for User Story 77661: Box for Salesforce- Copy files from a Closed-Won Additional Product Opp for Auto-created Cases
     * @description
     * Uploads a file to Box from a given Salesforce Attachment.
     * Uses the Attachment's ParentId to determine folder placement.
     * 
     * @param attachment The in-memory Attachment to upload.
     * @return The Box file ID of the uploaded file.
     * @throws BoxServiceException if the upload fails.
     */
    public String uploadAttachmentToBox(Attachment attachment) {
        String fileId = toolkit.createFileFromAttachment(attachment, null, null, null);
        if (Test.isRunningTest()) {
            fileId = '999999';
        }
        if (String.isEmpty(fileId)) {
            throw new BoxServiceException('File upload failed → ' + toolkit.mostRecentError);
        }
        return fileId;
    }

    
    /**Used for User Story 77661: Box for Salesforce- Copy files from a Closed-Won Additional Product Opp for Auto-created Cases
     * @description
     * Uploads a file blob to Box by internally creating an Attachment.
     * This method is useful when you have raw PDF or file data to upload directly.
     *
     * @param fileBlob       The binary file content.
     * @param fileName       The name of the file (e.g., "MyDoc.pdf").
     * @param parentFolderRecordId The Salesforce record ID to associate with.
     * @param contentType    The MIME type (e.g., "application/pdf").
     * @return The Box file ID of the uploaded file.
     */
    public String uploadFileToBox(Blob fileBlob, String fileName, String parentFolderRecordId, String contentType) {
        Attachment attachment = new Attachment();
        attachment.Body = fileBlob;
        attachment.Name = fileName;
        attachment.ParentId = parentFolderRecordId;
        attachment.ContentType = contentType;

        return uploadAttachmentToBox(attachment);
    }
    
    
    /**
     * Used for User Story 75726: Update Contracts folder on edit to External_Id__c on Account
     * Adds tags to a folder.
     * @param folderId The ID of the folder to which tags will be added.
     * @param tagValues A list of tag values to be added.
     * @return The response body from the Box API.
     */
    public String addTagsToFolder(String folderId, List<String> tagValues){
        //get the endpoint
        String endPoint = Box_Callout_Endpoint__mdt.getInstance('Folder_PUT').Box_Endpoint__c + folderId;
        //create request body
        Map<String,List<String>> reqBody = new Map<String,List<String>>();
        reqBody.put('tags',tagValues);
        String jsonReqBody = JSON.Serialize(reqBody);
        
        //request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('PUT');
        req.setHeader(this.CONTENT_TYPE,this.CONTENT_TYPE_VALUE);
        req.setBody(jsonReqBody);
        
        //send request
        HttpResponse res = sendRequest(req);
		//200
        if(res.getStatusCode() == 200){
            return res.getBody();
        }
        else if(res.getStatusCode() != 200) {
            throw new BoxServiceException('Add Tags to folder failed → ' + parseError(res));
        }
        return null;
    }
    
    
    /**
     * Used for User Story 75726: Update Contracts folder on edit to External_Id__c on Account
     * Creates a folder in Box.
     * @param folderName The name of the folder to be created.
     * @param parentFolderId The ID of the parent folder.
     * @return The response body from the Box API.
     */
    public String createFolder(String folderName, String parentFolderId){
        //create folder request
        box.CreateFolder_v2.Request folderReq = new box.CreateFolder_v2.Request();
        folderReq.folderName = folderName;
        folderReq.parentFolderId= parentFolderId;
        
        List<box.CreateFolder_v2.Response> folderRes = box.CreateFolder_v2.tkCreateFolder(new List<box.CreateFolder_v2.Request>{folderReq});
        return folderRes[0].folderId;
    }
    
    
    /**
     * Used for User Story 75726: Update Contracts folder on edit to External_Id__c on Account
     * Creates metadata on a folder.
     * @param sObjectRecord The SObject record from which the values were taken to create the metadata
     * @param folderId The ID of the folder where metadata is created.
     * @param scope scope of box('enterprise' or 'global').
     * @param templateName name of the metadata template in box.
     * @return The response from the Box API.
     */
    public box.CreateBoxMetadataByFolderId.Response createMetadataOnFolder(Sobject sObjectRecord, String folderId, String scope, String templateName){
        try{
            if(sObjectRecord != null){
                List<box.CreateBoxMetadataByFolderId.Request> createMetadataRequests = new List<box.CreateBoxMetadataByFolderId.Request>();
                String objectApiName = (sObjectRecord.Id).getSobjectType().getDescribe().getName();
                
                List<Box_Create_Metadata_Fields__mdt> createMetadataRecords = new List<Box_Create_Metadata_Fields__mdt>();
                if(createMetadataFields == null){
                    createMetadataFields = [ SELECT Source_Field_API__c,Box_Field_API__c,Source_Object_API__c
                                            FROM Box_Create_Metadata_Fields__mdt ];
                }
                //filter metadata records by objectApiName
                for(Box_Create_Metadata_Fields__mdt mdtRecord: createMetadataFields){
                    if(mdtRecord.Source_Object_API__c == objectApiName){
                        createMetadataRecords.add(mdtRecord);
                    }
                }
                Map<String,Object> fieldMap = sObjectRecord.getPopulatedFieldsAsMap();
                //keyValue pair
                List<box.KeyValuePair> metadataKeyValuePairs = new List<box.KeyValuePair>();
                for(Box_Create_Metadata_Fields__mdt mdtTemplate : createMetadataRecords){
                    String sourceField = mdtTemplate.Source_Field_API__c;
                    if(sourceField.contains('.')){
                        List<String> fieldDetails = sourceField.split('\\.');
                    	Map<String,Object> childFieldMap = ((SObject)fieldMap.get(fieldDetails[0]))?.getPopulatedFieldsAsMap();
                        metadataKeyValuePairs.add(createMetadataKeyValuePair(mdtTemplate.Box_Field_API__c, (String)childFieldMap?.get(fieldDetails[1])));
                    }else{
                        metadataKeyValuePairs.add(createMetadataKeyValuePair(mdtTemplate.Box_Field_API__c, (String)fieldMap.get(mdtTemplate.Source_Field_API__c)));
                    }
                }
                
                //create request
                box.CreateBoxMetadataByFolderId.Request req = new box.CreateBoxMetadataByFolderId.Request();
                req.folderId=folderId;
                req.keyValuePairs = metadataKeyValuePairs;
                req.scope = scope;
                req.template_key = templateName;
                createMetadataRequests.add(req);		//add metadata request to list
                
                /*
                 * Used Test.isRunningTest() because when this method is executed from a test class, 
                 * box.CreateBoxMetadataByFolderId (which is inside the package) is invoked, and 
                 * it doesn't consider the mock response defined in the test method. As a result, 
                 * it throws the error:"Methods defined as TestMethod do not support Web service callouts."
                 */
                if(!createMetadataRequests.isEmpty() && !Test.isRunningTest()){
                    //call box method
                    List<box.CreateBoxMetadataByFolderId.Response> createFolderMetadataRes = box.CreateBoxMetadataByFolderId.tkCreateBoxMetadataByFolderId(createMetadataRequests);
                    return createFolderMetadataRes[0];
                }
            }
        }catch(Exception e){
            throw new BoxServiceException('Create Metadata on folder failed → ' +e.getMessage());
        }
        return null;
    }
    
    
    /**
     * Used for User Story 75726: Update Contracts folder on edit to External_Id__c on Account
     * createMetadataKeyValuePair method
     * This method creates a key-value pair for Box metadata.
     * @param key Key for the metadata
     * @param value Value for the metadata
     * @return box.KeyValuePair instance
     */
    private box.KeyValuePair createMetadataKeyValuePair(String key, String value){
        //create key value pair
        box.KeyValuePair keyValuePair = new box.KeyValuePair();
        keyValuePair.key = key;
        keyValuePair.value = value;
        return keyValuePair;
    }
    
    
    /**
     * Used for User Story 75726: Update Contracts folder on edit to External_Id__c on Account
     * Creates metadata on a folder.
     * @param sObjectRecord The SObject record from which the values were taken to create the metadata.
     * @param folderId The ID of the folder where metadata is created.
     * @param scope scope of box('enterprise' or 'global').
     * @param templateName name of the metadata template in box.
     * @return The response from the Box API.
     */
    public box.UpdateBoxMetadataByFolderId.Response updateMetadataOnFolder(Sobject sObjectRecord, String folderId, String scope, String templateName){
        try{
            if(sObjectRecord != null ){
                List<box.UpdateBoxMetadataByFolderId.Request> updateMetadataRequests = new List<box.UpdateBoxMetadataByFolderId.Request>();
                List<box.FolderMetadataUpdate> folderMetadataUpdates = new List<box.FolderMetadataUpdate>();
                String objectApiName = (sObjectRecord.Id).getSobjectType().getDescribe().getName();
                
                List<Box_Update_Metadata_Fields__mdt> updateMdtRecords = new List<Box_Update_Metadata_Fields__mdt>();
                
                if(updateMetadataFields == null){
                    updateMetadataFields = [ SELECT Box_Target_Field__c,Source_Field_API__c,Box_Update_Operation__c,Source_Object_API__c
                                            FROM Box_Update_Metadata_Fields__mdt ];
                }
                
                for(Box_Update_Metadata_Fields__mdt mdtRecord:updateMetadataFields){
                    if(mdtRecord.Source_Object_API__c == objectApiName){
                        updateMdtRecords.add(mdtRecord);
                    }
                }
                
                Map<String,Object> fieldMap = sObjectRecord.getPopulatedFieldsAsMap();
                for(Box_Update_Metadata_Fields__mdt mdtRec: updateMdtRecords){ 
                    String sourceField = mdtRec.Source_Field_API__c;
                    if(sourceField.contains('.')){
                        List<String> fieldDetails = sourceField.split('\\.');
                    	Map<String,Object> childFieldMap = ((SObject)fieldMap.get(fieldDetails[0]))?.getPopulatedFieldsAsMap();
                        folderMetadataUpdates.add(createMetadataUpdate(mdtRec.Box_Update_Operation__c, mdtRec.Box_Target_Field__c, (String)childFieldMap?.get(fieldDetails[1])));
                    }else{
                        //create metadata update
                    	folderMetadataUpdates.add(createMetadataUpdate(mdtRec.Box_Update_Operation__c, mdtRec.Box_Target_Field__c, (String)fieldMap.get(mdtRec.Source_Field_API__c)));
                    } 
                }
                //create request
                box.UpdateBoxMetadataByFolderId.Request updateMetadataReq = new box.UpdateBoxMetadataByFolderId.Request();
                updateMetadataReq.folderId= folderId;
                updateMetadataReq.scope = scope;
                updateMetadataReq.template_key = templateName;
                updateMetadataReq.updates = folderMetadataUpdates;
                updateMetadataRequests.add(updateMetadataReq);
                 /*
                 * Used Test.isRunningTest() because when this method is executed from a test class, 
                 * box.UpdateBoxMetadataByFolderId (which is inside the package) is invoked, and 
                 * it doesn't consider the mock response defined in the test method. As a result, 
                 * it throws the error:"Methods defined as TestMethod do not support Web service callouts."
                 */
                if(!Test.isRunningTest() && !updateMetadataRequests.isEmpty()){
                    List<box.UpdateBoxMetadataByFolderId.Response> udpateMetadataFolderResponse = box.UpdateBoxMetadataByFolderId.tkUpdateBoxMetadataByFolderId(updateMetadataRequests);
                	return udpateMetadataFolderResponse[0];
                } 
            }
        }catch(Exception e){
            throw new BoxServiceException('Update Metadata on folder failed → ' +e.getMessage());
        }
        return null;
    }
    
    
    /**
     * Used for User Story 75726: Update Contracts folder on edit to External_Id__c on Account
     * Creates a metadata update.
     * @param operation The operation for the metadata update. (Operations: add, replace, test, remove)
     * @param targetField The field that need to be update in metadata.
     * @param value The value for the metadata update.
     * 
     * @return The response from the Box API.
     */
    private box.FolderMetadataUpdate createMetadataUpdate(String operation, String targetField, String value){
        box.FolderMetadataUpdate folderMetadataUpdate = new box.FolderMetadataUpdate();
        if(operation == 'add' || operation == 'replace' || operation == 'test' ){
            folderMetadataUpdate.op = operation;
            folderMetadataUpdate.path = '/'+targetField;
            folderMetadataUpdate.value = value;
        }else if(operation == 'remove'){
            folderMetadataUpdate.op = operation;
            folderMetadataUpdate.path = '/'+targetField;
        }
        return folderMetadataUpdate;
    }
    
    
    /**
     * Used for User Story 82491: SF | Add Bookmark When Contracts Folder Created
     * Creates or gets a shared link for a folder.
     * @param folderId The ID of the folder for which the shared link is created or retrieved.
     * @return The URL of the shared link.
     */
    public String createOrGetSharedLinkForFolder(String folderId){
        //get the endpoint
        String endPoint = Box_Callout_Endpoint__mdt.getInstance('Folder_PUT').Box_Endpoint__c + folderId+'?fields=shared_link';
        //create request body 
        Map<String,Object> requestBody = new Map<String,Object>();
        Map<String,Object> sharedLink = new Map<String,Object>();
        Map<String,Object> permissions = new Map<String,Object>();
        permissions.put('can_preview', true);
        sharedLink.put('permissions',permissions);
        requestBody.put('shared_link',sharedLink);
        String jsonString = JSON.serialize(requestBody);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('PUT');
        req.setHeader(this.CONTENT_TYPE,this.CONTENT_TYPE_VALUE);
        req.setBody(jsonString);
        
        //send request
        HttpResponse res = sendRequest(req);
        
        if(res.getStatusCode() == 200){
            Map<String,Object> deserializedRes = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
            Map<String,Object> sharedLinkMap = (Map<String,Object>)deserializedRes.get('shared_link');
            return (String)sharedLinkMap?.get('url');
        }
        else if(res.getStatusCode() != 200) {
            throw new BoxServiceException('Create shared link for folder failed → ' + parseError(res));
        }
        return null;
    }
    
    
    /**
     * Used for User Story 82491: SF | Add Bookmark When Contracts Folder Created
     * Creates a weblink in Box.
     * @param link The URL for the weblink.
     * @param destinationFolderId The ID of the folder where the weblink is created.
     * @param weblinkFolderName the name of weblink.
     * @return The response from the Box API.
     */
    public String createWeblink(String link, String destinationFolderId, String weblinkFolderName){
        //get the endpoint
        String endPoint = Box_Callout_Endpoint__mdt.getInstance('WebLink_POST').Box_Endpoint__c;
        
        //prepare request body
        Map<String,Object> requestBody = new Map<String,Object>();
        requestBody.put('name',weblinkFolderName);	//name
        requestBody.put('url',link);
        Map<String,String> parent = new Map<String,String>();
        parent.put('id',destinationFolderId);
        requestBody.put('parent',parent);
        String jsonBody = JSON.serialize(requestBody);
        //request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        req.setBody(jsonBody);
        req.setHeader(this.CONTENT_TYPE,this.CONTENT_TYPE_VALUE);
        //send request
        HttpResponse res = sendRequest(req);
        if(res.getStatusCode() == 201){
            return res.getBody();
        }
        else if(res.getStatusCode() != 201) {
            throw new BoxServiceException('Create weblink link for folder failed → ' + parseError(res));
        }
        return null;       
    }
   
    
    /**
     * Sends an HTTP request to the Box using toolkit.
     * @param req The HTTP request to be sent.
     * @return The HTTP response from the Box API.
     */
    private HttpResponse sendRequest(HttpRequest req){
        HttpResponse res = new HttpResponse();
        if (Test.isRunningTest()) {
            Http h = new Http();
            res = h.send(req);
        } else {
            res = toolkit.sendRequest(req);
        }
        return res;
    }
    
    
    /**Used for User Story 77661: Box for Salesforce- Copy files from a Closed-Won Additional Product Opp for Auto-created Cases
     * @description
     * Commits any pending changes made by the toolkit (e.g., FRUP inserts).
     */
    public void commitChanges() {
        toolkit.commitChanges();
    }

    
    /**
     * @description
     * Helper method to parse and format errors from Box Toolkit responses.
     * 
     * @param res The HttpResponse from a Box API call.
     * @return A formatted error message for logging or throwing.
     */
    private String parseError(HttpResponse res) {
        String err = 'Status: ' + res.getStatusCode();
        if (toolkit.mostRecentError != null) {
            err += ' Error: ' + toolkit.mostRecentError;
        } else {
            err += ' Body: ' + res.getBody();
        }
        return err;
    }

    
    /**
     * @description
     * Custom exception class used for wrapping Box service-related errors.
     */
    public class BoxServiceException extends Exception {}
}