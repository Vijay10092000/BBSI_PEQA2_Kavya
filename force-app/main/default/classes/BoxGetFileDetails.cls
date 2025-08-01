/*
 * @description this class will make Http call to Box to get File Details
*/
	public with sharing class BoxGetFileDetails {
    
    Private static final String CONTENT_TYPE='content-type';
    Private static final String CONTENT_TYPE_VALUE='application/json';
    Private static String CALLOUT_METHOD;
    Private Static String ENDPOINT;
    Private Static final String mdt_developerName = 'File_GET';
    /*
     * @description this method will make callout to Box to get file details based on fileId
     * @param boxFileId is box file Id
     * @return file extension
	*/
    @InvocableMethod
    public static List<ResultParams> getFileDetail(List<String> boxFileId){
        List<ResultParams> results = new List<ResultParams>();
        
        //request
        Box_Callout_Endpoint__mdt mdtRec = [ SELECT Id,
                                            Box_Endpoint__c,
                                            Callout_Method__c 
                                            FROM Box_Callout_Endpoint__mdt WHERE DeveloperName = :mdt_developerName ];
        CALLOUT_METHOD = mdtRec.Callout_Method__c;
        ENDPOINT =mdtRec.Box_Endpoint__c;
        Box.Toolkit toolkit = new Box.Toolkit();
        for(String fileId : boxFileId){
            String url = ENDPOINT + fileId;
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(CALLOUT_METHOD);
            req.setHeader(CONTENT_TYPE,CONTENT_TYPE_VALUE);
            //response
            HttpResponse res = new HttpResponse();
            try{
                res = Test.isRunningTest() ? new Http().send(req) : toolkit.sendRequest(req);
            }catch(calloutException e){
                throw new CalloutException('Exception while Getting file details from Box :'+e.getMessage());
            }
            System.debug('Response :'+res.getBody());
            //retrieve extension of file from response
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            String name = (String)responseMap.get('name');
            String fileName = name?.substringBeforeLast('.');
            String fileExtension = name?.substringAfterLast('.');
            System.debug('File Name :'+name);
            
            //add to result
            ResultParams result = new ResultParams();
            result.filename =fileName;
            result.fileExtension = fileExtension;
            results.add(result);
        }
        return results;
    }
        
        //Result to return to flow
        public class ResultParams{
            @InvocableVariable
            public String filename;
            @INvocableVariable
            public String fileExtension;
       }
}