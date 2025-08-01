/**
 * @description This Apex class syncs the Box User ID for the current Salesforce user.
 * It performs a callout to Box's Enterprise API using the user's email domain (before '@') 
 * to filter Box users and retrieve the corresponding Box User ID.
 *
 * The class is designed to be invoked from Salesforce Flows - "Box Signature Events Receiver: Update BoxSignStatus"
 * It uses a named credential (Box_UserId_SyncService) for secure API access.
 *
 * Dependencies:
 * - BoxConnectionEnterpriseAPI: Handles authentication and provides access tokens for Box API requests.
 */
public with sharing class BoxUserSyncService {
    private static String FILTER_TERM = '?filter_term=';
    private static String FILTER_ITEM_USER_TYPE = '&user_type=managed';
    private static String CALLOUT_METHOD = 'GET';
    private static String AUTHORIZATION_KEY_HEADER = 'authorization';
    private static String AUTHORIZATION_VALUE_HEADER = 'Bearer ';
    
     /**
     * @description Invocable method to fetch the Box User ID of the current user.
     * It splits the user's email to extract the domain name, sends a callout to Box API,
     * parses the response, and returns the matched Box User ID if found.
     *
     * @return List<String> - A list containing a single Box User ID if found, otherwise an empty list.
     */
    @InvocableMethod
    public static List<String> getBoxUserId(){
        List<String> results = new List<String>();
        
        //get user email
        String emailId = UserInfo.getUserEmail();
		List<String> emailSplit = emailId.split('@');
        String name = emailSplit.size() > 0 ? emailSplit[0] : '';

        //create request
        HttpRequest req = createRequest(name);
        
        try{
            //send request
            HttpResponse res = sendRequest(req);
            if(res.getStatusCode() == 200){
                //deserialize the response
                Map<String,Object> resMap = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
                Integer total_count = (Integer)resMap.get('total_count');
                //found user with name
                if(total_count != 0){
                    //get userId from Response map
                    String boxUserId = getId(resMap);
                    results.add(boxUserId);
                }
            }
        }catch(Exception e){
            System.debug('BoxUserSyncService Exception @@@:'+e.getMessage());
        }
        
        //return results
        return results;
    }
    
    /**
     * @description Creates the HttpRequest object to call the Box API to search for a user using the provided filter value.
     *
     * @param filterValue The email domain (e.g., 'example.com') to filter users in Box.
     * @return HttpRequest - Configured HttpRequest ready to be sent.
     */
    @TestVisible
    private static HttpRequest createRequest(String filterValue){
        //get accessToken
        BoxConnectionEnterpriseAPI obj = new BoxConnectionEnterpriseAPI();
        obj.authenticate();
        String box_access_token = obj.getAccessToken() ;
        
        //assign endpoint
        String endPoint = 'callout:Box_UserId_SyncService'+FILTER_TERM+filterValue+FILTER_ITEM_USER_TYPE;
        
        //request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod(CALLOUT_METHOD);
        req.setHeader(AUTHORIZATION_KEY_HEADER, AUTHORIZATION_VALUE_HEADER+box_access_token);
        
        //return request
        return req;
    }
    
    /**
     * @description Sends the HttpRequest to the Box API and returns the HttpResponse.
     *
     * @param req The HttpRequest to be sent.
     * @return HttpResponse - The response returned from Box API.
     */
    @TestVisible
    private static HttpResponse sendRequest(HttpRequest req){
        return new Http().send(req);
    }
    
    /**
     * @description Parses the Box API response map to extract the Box User ID from the 'entries' list.
     *
     * @param resMap The deserialized JSON response map from Box API.
     * @return String - The Box User ID if found, null otherwise.
     */
    @TestVisible
    private static String getId(Map<String,Object> resMap){
        String boxUserId;
        if(resMap.containsKey('entries')){
            List<Object> entries = (List<Object>)resMap.get('entries');
            for(Object entry : entries){
                Map<String,Object> entryMap = (Map<String,Object>)entry;
                if(entryMap.containsKey('id')){
                    //assign boxUserId to list
                    boxUserId =  (String)entryMap.get('id');
                }
            }
        }
        return boxUserId;
    } 
}