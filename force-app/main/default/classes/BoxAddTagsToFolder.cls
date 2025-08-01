/*
 * @description This Apex Class is invoked in Box_Uploader Flow, Opp_SupportDocSelectExistingFile Flow and Opportunity_Document_Copy_File_to_Contracts_Folder
*/
public class BoxAddTagsToFolder {
    Private static String CONTENT_TYPE='content-type';
    Private static String CONTENT_TYPE_VALUE='application/json';
    Private static String CALLOUT_METHOD;
    Private Static String ENDPOINT;
	/*
     *@description This method makes API calls to Box to add tags to folder
    */ 
	@InvocableMethod
    public static List<String> addTagsToFolder(List<RequestParams> params){
        List<String> results  = new List<String>();
        
        //get the box api details
        Box_Callout_Endpoint__mdt mdtRec = [ SELECT Id,
                                            Box_Endpoint__c,
                                            Callout_Method__c
                                            FROM Box_Callout_Endpoint__mdt WHERE DeveloperName = 'Folder_PUT' ];

        CALLOUT_METHOD = mdtRec.Callout_Method__c;
        ENDPOINT =mdtRec.Box_Endpoint__c;
        Box.Toolkit toolkit = new Box.Toolkit();
        
        //iterate over requstParams
        for(RequestParams param: params){
            //url from metadata 
            String url = ENDPOINT+param.folderId;
            Map<String,List<String>> reqBody = new Map<String,List<String>>();
            //add list of values as tags
            reqBody.put('tags',param.tagValues);
            
            //serialize the reqBody Map
            String jsonBody = JSON.Serialize(reqBody);
            String requestBody = jsonBody;
            
            //request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(CALLOUT_METHOD);
            req.setHeader(CONTENT_TYPE,CONTENT_TYPE_VALUE);
            req.setBody(requestBody);
            //response
            HttpResponse res;
            
            //send the request
            try{
                res = Test.isRunningTest() ? new Http().send(req) : toolkit.sendRequest(req);  
            }catch(CalloutException e){
                throw new CalloutException('Exception while adding tags to folder :'+e.getMessage());
            }
            System.debug('Res body :'+res.getBody());
            
            //deserialize the response
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            String name = (String)responseMap.get('name');
            System.debug('Folder Name :'+name);
            
            //add the extracted file name to result
            results.add(name);
        }
        //return 
        return results;
    }
    /*
     *@description This class provides inputs to Box_Uploader Flow and Opp_SupportDocSelectExistingFile Flow
    */   
    Public Class RequestParams{
        @InvocableVariable(label='FolderId' description='FolderId to add tags' required=true)
        Public String folderId;
        @InvocableVariable(label='Tag Value' description='The value that has to add as a tag' required=true)
        Public List<String> tagValues;
        
    }
}