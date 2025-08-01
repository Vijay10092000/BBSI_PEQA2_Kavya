/*
 * @description This class is responsible for handling API requests to the Box platform.
 *  and retrieving information such as sign requests and user lists 
 * 
*/
public class BoxCustomAPIRequest {
    //constants used
    private static final String CONTENT_TYPE_KEY = 'content-type';
    private static final String CONTENT_TYPE_VALUE = 'application/json';
    private static final String AUTHORIZATION_KEY = 'Authorization';
    private static final String BEARER_VALUE = 'Bearer ';
    private static final String AS_USER_KEY = 'As-User';
    
    private static String getBoxUserId(){
        String boxUserId = '';
        String userId = UserInfo.getUserId();
        User user = [ SELECT Id,Box_User_Id__c FROM User WHERE Id = :userId ];
        if(user.Box_User_Id__c != null){
            boxUserId = user.Box_User_Id__c;
        }
        return boxUserId;
    }
    
    /**
     * @description Retrieves the details of sign requests from the Box API.
     * @return A JSON-formatted string containing the sign request details.
     */
    public static String getSignRequests(){
        String boxUserId = getBoxUserId();
        BoxConnectionEnterpriseAPI obj = new BoxConnectionEnterpriseAPI();
        obj.authenticate();
        String adminAccessToken = obj.getAccessToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Box_Sign_Requests');
        req.setMethod('GET');
        req.setHeader(CONTENT_TYPE_KEY,CONTENT_TYPE_VALUE);
        req.setHeader(AUTHORIZATION_KEY, BEARER_VALUE + adminAccessToken);
        req.setHeader(AS_USER_KEY, boxUserId); // Box User Id. Should be picked from User record.
        
        return makeRequest(req);
    }
    
    
    /**
     * @description This method fetches the list of users from the Box API.
     * It authenticates using the BoxConnectionEnterpriseAPI class to retrieve the access token,
     * then makes a GET request to the Box API with the `limit` parameter set to 1000(max).
     * @return String - The JSON response body containing the list of users from the Box API.
 	*/
    
    public static String getBoxUsers(Integer offSet, Integer fetchingLimit){
        BoxConnectionEnterpriseAPI obj = new BoxConnectionEnterpriseAPI();
        obj.authenticate();
        String adminAccessToken = obj.getAccessToken();
        //System.debug('Access Token :'+adminAccessToken);
        String url = 'callout:Box_Users'+'?limit='+fetchingLimit+'&offset='+offSet;
        //api call to get users list from box
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('content-type','application/json');
        req.setHeader('authorization', 'Bearer ' + adminAccessToken);
        //req.setHeader('As-User', '35730294263'); // Box User Id. Should be picked from User record.
        return makeRequest(req);
    }
    
    /**
     * @description this method make HttpRequest and return response
     * @param req - The HttpRequest object containing the API endpoint, headers, and other details.
     * @return String - The response body from the HTTP callout.
     * @throws CalloutException - Thrown when an error occurs during the HTTP callout.
     */
    @TestVisible
    private static String makeRequest(HttpRequest req){
        String responseBody= '';
        try{
            Http http = new Http();
            //response
            HttpResponse res = http.send(req);
            System.debug('User Request Body :'+res.getBody());
            System.debug('User Request Status :'+res.getStatusCode());
            if(res.getStatus() == 'OK'){
                responseBody = res.getBody();
            }
        }catch(CalloutException e){
            throw new CalloutException(e.getMessage());
        }
        return responseBody;
    }
}