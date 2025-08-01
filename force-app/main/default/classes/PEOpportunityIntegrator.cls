public with sharing class PEOpportunityIntegrator {
    
    Private static final String PE_WEBHOOK_URL = 'callout:Pricing_Engine';
    Private static final String USER_ID = 'user_id';
    Private static final String ACCOUNT_ID = 'acc_id';
    Private static final String STATE = 'state';
    Private static final String ALGORITHM = 'algorithm';
    Private static final String ALGORITHM_NAME = 'HMACSHA256';
    Private static final String DECRYPTION_ALGORITHM = PEEncryptedSecret.ENCRYPTING_ALGORITHM;
    
    /**
     * @description makeHttpCallToPricingEngine makes an HTTP call to Pricing Engine Webhook
     * @param  statesList list of states
     * @param  accountId 
     */
    @future(callout=true)
    public static void makeHttpCallToPricingEngine(List<String> statesList,String accountId){
        statesList = statesList == null ? new List<String>() : statesList;
        //payload data
        Map<String, Object> payloadData = new Map<String, Object>();
        payloadData.put(USER_ID, UserInfo.getUserId());
        payloadData.put(ACCOUNT_ID, accountId);
        payloadData.put(STATE, statesList);
        payloadData.put(ALGORITHM,ALGORITHM_NAME);
        // Convert Map to JSON
        String payload = JSON.serialize(payloadData);  
        // Base64 encode the JSON payload
        String encodedPayload = EncodingUtil.base64Encode(Blob.valueOf(payload));
        String consumerSecret = getConsumerSecret();
        // Compute the HMAC-SHA256 signature
        Blob signatureBlob = Crypto.generateMac(ALGORITHM_NAME, Blob.valueOf(encodedPayload), Blob.valueOf(consumerSecret));
        //encode the signature 
        String signature = EncodingUtil.base64Encode(signatureBlob);
        // Combine the encoded payload and the signature
        String signedRequest = signature+ '.' + encodedPayload;
        Map<String,String> reqBody = new Map<String,String>();
        reqBody.put('Signed_Request',signedRequest);
        String jsonBody = JSON.serialize(reqBody);
        System.debug('JSON body:'+jsonBody);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(PE_WEBHOOK_URL);
        req.setMethod('PUT');
        req.setHeader('Content-Type','application/json');
        req.setBody(jsonBody);
        
        Http http = new Http(); 
        try{
            HttpResponse res = http.send(req);
            System.debug('Response :'+res.getBody());
            if(res.getStatusCode() == 200){
                System.debug('Successfully updated pricing for opportunity: ');
            } else {
                System.debug('Error updating pricing for opportunity: '+res.getBody());
            }
        }catch(Exception e){
            System.debug('Exception Error updating pricing for opportunity: '+e.getMessage());
        }   
    }
    
    private static String getConsumerSecret(){
        PE_Encrypted_Secret__mdt mdtRecord = [ SELECT Id,Encrypted_Secret__c,Encryption_Key__c FROM PE_Encrypted_Secret__mdt WHERE DeveloperName = 'PE_Consumer_Secret' ];
        String originalConsumerSecret;
        if(mdtRecord != null){
            Blob encryptedSecretBlob = EncodingUtil.base64Decode(mdtRecord?.Encrypted_Secret__c);
            Blob encryptedKeyBlob = EncodingUtil.base64Decode(mdtRecord?.Encryption_Key__c);  
            Blob decryptedData = Crypto.decryptWithManagedIV(DECRYPTION_ALGORITHM, encryptedKeyBlob, encryptedSecretBlob);
            originalConsumerSecret = decryptedData.toString();
        }
       return originalConsumerSecret;
    }
}