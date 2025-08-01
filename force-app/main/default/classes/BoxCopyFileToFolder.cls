/*
 * @description this class make Http call to box to copy file to another folder
 * 
*/
	public with sharing class BoxCopyFileToFolder {

    Private static String CONTENT_TYPE='content-type';
    Private static String CONTENT_TYPE_VALUE='application/json';
    Private static String CALLOUT_METHOD;
    Private Static String ENDPOINT;

    /*
     * @description this method will copy file to another folder in Box
     * @param params used to make Http call
     * @return statusCode of Http call
	*/
    @InvocableMethod
    	Public Static List<Integer> copyFileToFolder(List<RequestParams> params){
        List<Integer> results = new List<Integer>();
        
        //box api details
        Box_Callout_Endpoint__mdt mdtRec = [ SELECT Id,
                                            Box_Endpoint__c,
                                            Callout_Method__c 
                                            FROM Box_Callout_Endpoint__mdt WHERE DeveloperName = 'File_POST' ];
        CALLOUT_METHOD = mdtRec.Callout_Method__c;
        ENDPOINT =mdtRec.Box_Endpoint__c;
		//toolkit object
        Box.Toolkit toolkit = new Box.Toolkit();
        for(RequestParams param: params){
            String url = ENDPOINT + param.fileId+'/copy';
            String reqBody = '{'+
                                '"parent":{'+
                                '"id":"'+ params[0].destinationFolderId +'"'+
                                '},'+
                                '"name":"'+params[0].fein+' - '+params[0].accountName+' - '+params[0].documentName+'.'+params[0].fileExtension+'"'+
                            '}';
            //request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(CALLOUT_METHOD);
            req.setHeader(CONTENT_TYPE,CONTENT_TYPE_VALUE);
            req.setBody(reqBody);
            //response
            HttpResponse res = new HttpResponse();
            try{
                res = Test.isRunningTest() ? new Http().send(req) : toolkit.sendRequest(req);
				results.add(res.getStatusCode());
            }catch(CalloutException e){
                System.debug('Exception While copying file to folder :'+e.getMessage());
            }
            
        }
        return results;
    }
	/*
	 * @description parameters that need to be passed from the flow 
	*/
    Public Class RequestParams{
        @InvocableVariable(label='File Id' description='File ID to be copied' required=true)
        Public String fileId;

        @InvocableVariable(label='FolderId' description='The folder Id that file need to be copied' required=true)
        Public String destinationFolderId;
        
        @InvocableVariable(label='Account FEIN' description='The Fein field in Account')
        Public String fein;

        @InvocableVariable(label='Account Name' description='Name of Account')
        Public String accountName;

        @InvocableVariable(label='Document Name' description='Name of Document')
        Public String documentName;

        @InvocableVariable(label='File Extension' description='Extension to add End of File')
        Public String fileExtension;
    }
}