/*
 * @description This Apex Class is invoked in Box_Uploader Flow and Opp_SupportDocSelectExistingFile Flow
*/
	public with sharing class BoxUploaderMoveFile {
    private static String CONTENT_TYPE='content-type';
    private static String CONTENT_TYPE_VALUE='application/json';
    private static String CALLOUT_METHOD;
    private static String ENDPOINT;

    /*
     *@description This method makes API calls to Box to move an existing/older file
     *to Archive Folder when an Opportunity_Document__c is already associated with a Box File
    */
    @InvocableMethod
    public static List<Integer> moveFileToArchive(List<BoxUploaderMoveFile.RequestParams> params) {
        // Retrieve Metadata Configuration 
        Box_Callout_Endpoint__mdt mdtRec = [
            SELECT Id, Box_Endpoint__c, Callout_Method__c
            FROM Box_Callout_Endpoint__mdt 
            WHERE DeveloperName = 'File_PUT'
        ];
        
        CALLOUT_METHOD = mdtRec.Callout_Method__c;
        ENDPOINT = mdtRec.Box_Endpoint__c;

        // Initialize result list
        List<Integer> statusCodes = new List<Integer>();
		//get box userId
		User usr = [ SELECT Id,Box_User_Id__c FROM User WHERE Id = :userInfo.getUserId() LIMIT 1];
        
        // Request toolkit for Box API Callout
        Box.Toolkit toolkit = new Box.Toolkit();
        
        // Process each file move request separately
        for (RequestParams param : params) {
            String url = ENDPOINT + param.fileId;
            String requestBody = '{'+
                	'"parent": {'+
                		'"id": "' + param.destinationFolderId + '"'+
                		'},'+
                	'"name": "'+ param.fileName+' - '+System.now()+' - '+usr.Box_User_Id__c+'.'+param.fileExtension+'"'+
                '}';

            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(CALLOUT_METHOD);
            req.setHeader(CONTENT_TYPE, CONTENT_TYPE_VALUE);
            req.setBody(requestBody);

            // Handle response
            HttpResponse res = new HttpResponse();
            try {
                res = Test.isRunningTest() ? new Http().send(req) : toolkit.sendRequest(req);
                System.debug('Body :' + res.getBody());
                System.debug('Status :' + res.getStatusCode());
            } catch (CalloutException e) {
                throw new CalloutException('Exception While making callout to Box: ' + e.getMessage());
            }
            
            // Store status code for each request
            statusCodes.add(res.getStatusCode());
        }
        
        return statusCodes; // Ensure output list matches input list size
    }

    /*
     *@description This class provides inputs to Box_Uploader Flow and Opp_SupportDocSelectExistingFile Flow
    */
    public class RequestParams {
        @InvocableVariable(label='File Id' description='File Id that has to move' required=true)
        public String fileId;

        @InvocableVariable(label='Parent Folder Id' description='Destination Folder Id' required=true)
        public String destinationFolderId;
        
        @InvocableVariable(label = 'FileName')
        public String fileName;
        
        @InvocableVariable(label='Extension')
        public String fileExtension;
    }
}