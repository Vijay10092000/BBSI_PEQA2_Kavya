/**
* @description BoxConnectionEnterpriseAPI class is used to make API Calls to Box to fetch Access Token using Named Credentials.
* 
*/
public class BoxConnectionEnterpriseAPI {
    
    public final String HEADER_CONTENT_TYPE = 'Content-Type';
    public final String HEADER_APPLICATION_ENCODED = 'application/x-www-form-urlencoded';
    public final String METHOD_POST = 'POST';
    public final String CLIENT_ID_KEY = EncodingUtil.urlEncode('client_id', 'UTF-8');
    public final String CLIENT_ID_VALUE = '{!$Credential.BoxExternalCredential.client_id}';  //fetching from external credential
    public final String CLIENT_SECRET_KEY = EncodingUtil.urlEncode('client_secret', 'UTF-8');
    public final String CLIENT_SECRET_VALUE = '{!$Credential.BoxExternalCredential.client_secret}';  //fetching from external credential
    public final String GRANT_TYPE_KEY = EncodingUtil.urlEncode('grant_type', 'UTF-8');
    public final String GRANT_TYPE_VALUE = '{!$Credential.BoxExternalCredential.grant_type}';  //fetching from external credential
    public final String BOX_SUBJECTTYPE_KEY = EncodingUtil.urlEncode('box_subject_type', 'UTF-8');
    public final String BOX_SUBJECTTYPE_VALUE = '{!$Credential.BoxExternalCredential.box_subject_type}';  //fetching from external credential
    public final String BOX_SUBJECTID_KEY = EncodingUtil.urlEncode('box_subject_id', 'UTF-8');
    public final String BOX_SUBJECTID_VALUE = '{!$Credential.BoxExternalCredential.box_subject_id}';  //fetching from external credential
    
    public final String clientId;
    public final String clientSecret;
    
    public String accessToken { get; set; }
    public String tokenUrl { get; set; }
    
    public Long lastRefresh { get; set; }
    public Long expires { get; set; }
    
    public BoxConnectionEnterpriseAPI() { 
        this.setAccessToken(null);
        //this.setTokenUrl('');
        this.setLastRefresh(0);
        this.setExpires(0);
    }
    
    public void authenticate() {
        
        Map<String, String> clientCredentialsGrantMap = new Map<String, String>();
        clientCredentialsGrantMap.put(this.CLIENT_ID_KEY, this.CLIENT_ID_VALUE); 
        clientCredentialsGrantMap.put(this.CLIENT_SECRET_KEY, this.CLIENT_SECRET_VALUE); 
        clientCredentialsGrantMap.put(this.GRANT_TYPE_KEY, this.GRANT_TYPE_VALUE);
        clientCredentialsGrantMap.put(this.BOX_SUBJECTTYPE_KEY, this.BOX_SUBJECTTYPE_VALUE);  
        clientCredentialsGrantMap.put(this.BOX_SUBJECTID_KEY, this.BOX_SUBJECTID_VALUE); 
        
        String result = '';
        for(String key : clientCredentialsGrantMap.keySet()) {
            result += key + '=' + clientCredentialsGrantMap.get(key) + '&';
        }
        result = result.removeEnd('&');
        
        System.debug('Req Body :'+result);
        //making request to get access token
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('POST');
        httpRequest.setEndpoint('callout:Box_Token');
        httpRequest.setHeader(this.HEADER_CONTENT_TYPE, this.HEADER_APPLICATION_ENCODED);
        httpRequest.setBody(result);
        //response
        try{
            HttpResponse response = new Http().send(httpRequest);
            if(String.isNotBlank((String.valueOf(response)))){
                String token = ''; // Fetch 'access_token' from response
                // expiresIn is set to zero because, if the callout fails, leaving it as an empty string will cause an "invalid long" error in setExpires().
                String expiresIn = '0'; // Fetch 'expires_in' from response
                if (response.getStatus() == 'OK') { // Check if it OK or something else.
                    try{
                        Map<String,Object> rawObj = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());           
                        for(String key: rawObj.keySet()){
                            if(key == 'access_token'){			//retriveve access token
                                token = (String)rawObj.get(key);
                            }
                            if(key == 'expires_in'){		//retrieve expires
                                expiresIn = String.valueOf(rawObj.get(key));
                            }
                        }
                        
                        this.setAccessToken(token);
                        this.setLastRefresh(DateTime.now().getTime());
                        this.setExpires(Long.valueOf(expiresIn) * 1000);
                    }
                    catch(Exception e){
                        // Handle Exception - response.toString()
                        throw  new StringException(response.getBody());
                    }
                } 
                else {
                    // Handle Exception - response.toString()
                    throw  new CalloutException(response.getBody());
                }
            }
        }catch(Exception e){
            System.debug(e.getStackTraceString());
            throw  new CalloutException(e.getMessage());
        }
    }
    
    private Boolean needsRefresh() {
        Boolean needsRefresh;
        Long now = DateTime.now().getTime();
        Long tokenDuration = now - this.getLastRefresh();
        needsRefresh = (tokenDuration >= this.getExpires());
        return needsRefresh;
    }
    
    public void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }
    
    public String getAccessToken() {
        if (this.getLastRefresh() == 0  ||  this.needsRefresh()) {
            this.authenticate();
        }
        return this.accessToken;
    }
    
    public Long getLastRefresh() {
        return this.lastRefresh;
    }
    
    public void setLastRefresh(Long lastRefresh) {
        this.lastRefresh = lastRefresh;
    }
    
    public Long getExpires() {
        return this.expires;
    }
    
    public void setExpires(Long expires) {
        this.expires = expires;
    }
}