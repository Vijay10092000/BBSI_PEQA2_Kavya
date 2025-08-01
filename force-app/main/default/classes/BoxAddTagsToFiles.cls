/*
 * @description This Apex Class is invoked in Box_Uploader Flow and Opp_SupportDocSelectExistingFile Flow
*/
	public with sharing class BoxAddTagsToFiles {
    Private static String CONTENT_TYPE='content-type';
    Private static String CONTENT_TYPE_VALUE='application/json';
    Private static String CALLOUT_METHOD;
    Private Static String ENDPOINT;
	/*
     *@description This method makes API calls to Box to add tags to uploading file
    */   
    @InvocableMethod
    Public Static List<String> addTagsToFile(List<RequestParams> params){
        List<String> results  = new List<String>();
        
        //get the box api details
        Box_Callout_Endpoint__mdt mdtRec = [ SELECT Id,
                                            Box_Endpoint__c,
                                            Callout_Method__c
                                            FROM Box_Callout_Endpoint__mdt WHERE DeveloperName = 'File_PUT' ];
        CALLOUT_METHOD = mdtRec.Callout_Method__c;
        ENDPOINT =mdtRec.Box_Endpoint__c;
        Box.Toolkit toolkit = new Box.Toolkit();
        for(RequestParams param: params){
            String url = ENDPOINT+param.fileId ;
            Map<String,List<String>> reqBody = new Map<String,List<String>>();
            reqBody.put('tags',param.tagValues);
            String jsonBody = JSON.Serialize(reqBody);
            String requestBody = jsonBody; /*'{"tags": ["'+param.tagValues+'"]}'*/
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(CALLOUT_METHOD);
            req.setHeader(CONTENT_TYPE,CONTENT_TYPE_VALUE);
            req.setBody(requestBody);
            //response
            HttpResponse res;
            try{
                res = Test.isRunningTest() ? new Http().send(req) : toolkit.sendRequest(req);  
            }catch(CalloutException e){
                throw new CalloutException('Exception while adding tags to file :'+e.getMessage());
            }
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            String name = (String)responseMap.get('name');
            //String fileExtension = name?.substringAfterLast('.');
            System.debug('filename :'+name);
            results.add(name);
        }
        return results;
    }

    /*
     *@description This class provides inputs to Box_Uploader Flow and Opp_SupportDocSelectExistingFile Flow
    */   
    Public Class RequestParams{
        @InvocableVariable(label='FileId' description='FileId to add tags' required=true)
        Public String fileId;
        @InvocableVariable(label='Tag Values' description='The value that has to add as a tag' required=true)
        Public List<String> tagValues;
        
    }

}