/*
 * Story - 82490
 * Team - OSI DIGITAL
 * @description this class will retrieve the BoxSignLogFile Id for a given Sign Request Ids
 * It contains InvocableMethod to be called from flow : Opportunity Document: Copy File to Contracts Folder
*/
public class BoxGetSignLogFile {
    /*
     * @description Invocable method to be called from flow : Opportunity Document: Copy File to Contracts Folder
     * @param List<String> signRequestIds is the list of Box Sign Request Ids
     * @return List<String> results is the list of BoxSignLogFile Ids
    */
    
	@InvocableMethod(Label='Get BoxSignLogFileId')
    public static List<String> getSignLogFileId(List<String> signRequestIds){
        //results
        List<String> results = new List<String>();
        
        // Retrieve Box Metadata Configuration 
        Box_Callout_Endpoint__mdt mdtRec = [ SELECT Id, Box_Endpoint__c, Callout_Method__c FROM Box_Callout_Endpoint__mdt WHERE DeveloperName = 'Sign_GET' LIMIT 1 ];
        //create toolkit
        box.Toolkit toolkit = new box.Toolkit();
        
        //iterate over sign request ids
        for(String signRequestId:signRequestIds){
            try{
                // Construct the endpoint URL for the Box API call
                String endPoint = mdtRec.Box_Endpoint__c + signRequestId;
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endPoint);
                req.setMethod(mdtRec.Callout_Method__c);
                // Send the HTTP request to the Box API
                HttpResponse res  = Test.isRunningTest() ? new Http().send(req) : toolkit.sendRequest(req);
                // Check if the response is successful and contains the expected data
                if(res != null && res.getStatus() == 'OK' ){
                    // Deserialize the response body into a map
                    Map<String,Object> deserializedRes = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
                    System.debug('Deserialized Response :'+deserializedRes);
                    // Extract the signing log information from the response
                    Map<String,Object> deserializedSignLogFile = (Map<String,Object>) deserializedRes.get('signing_log');
                    // Add the signing log file ID to the results list
                    String signLogFile = (String)deserializedSignLogFile.get('id');
                    if(String.isNotBlank(signLogFile)){
                    	results.add(signLogFile);                        
                    }

                    System.debug('Results :'+results);
                } 
            }catch(Exception e){
                // Log any exceptions that occur during the API call
                System.debug('Exception Occured Get SignLog FileId :'+e.getMessage());
            }
        }
        // Return the list of signing log file IDs
        return results;
    }
}