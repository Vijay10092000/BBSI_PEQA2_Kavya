/**
 * @name BoxWebhookHandler
 * @description 
 *  This Apex REST service handles incoming webhook payload from Box Sign.
 *  It validates the webhook using timestamp and HMAC-based headers, updates
 *  related Opportunity_Document__c records based on the Box sign request Id,
 *  and logs errors using a custom Log utility class.
 */
@RestResource(urlMapping='/boxSignStatusWebhook')
global class BoxWebhookHandler {
    
    private static final String PRIMARY_KEY_DEVELOPER_NAME = 'Box_Primary_Key';
    private static final String SECONDARY_KEY_DEVELOPER_NAME = 'Box_Secondary_Key';
    private static final String BOX_KEY_ENCRYPTING_ALGORITHM = 'HmacSHA256';
    private static final String DECRYPTION_ALGORITHM = 'AES128';
    
    /**
     * @description 
     *  REST POST method that receives the Box Sign webhook payload, validates it using
     *  HMAC signature and timestamp, and updates Opportunity Document records
     *  accordingly. Logs any errors using the custom Log utility.
     */
    @HttpPost
    global static void do_post() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.Response;
        try {
            if( validate_headers(req.headers, req.requestBody) ){
                //to update Opportunity Document Status
                update_oppdocs_status(req.requestBody.toString());
                //send response
                res.statusCode = 200;
                res.responseBody = Blob.valueOf('Webhook From Box Received Successfully');
            }else{
                res.statusCode = 401;
                res.responseBody = Blob.valueOf('Authorisation Failed');
               
            }
            
        }
        catch(Exception e) {
            //create a Log__c record
            Log.write(Log.Severity.ERROR, 'Box E-Sign Webhook Status Update', e.getMessage(), e.getStackTraceString());
            
            //send error in response
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
    
    /**
     * @description 
     *  Validates the timestamp and the HMAC signatures (primary and secondary) provided in headers.
     *  Ensures payload integrity and authenticity based on the Box webhook signing mechanism.
     *
     * @param headers HTTP headers received in the webhook request
     * @param request_body Raw request body blob of the webhook
     * @return Boolean indicating if the webhook is valid
     */
    @TestVisible
    private static Boolean validate_headers(Map<String,String> headers, Blob request_body){
        //validate time stamp
        String time_stamp = headers.get('box-delivery-timestamp');
        Boolean valid_timestamp = validate_time_stamp(time_stamp);
        
        //get keys from metadata
        Map<String,String> mdt_record_map = get_keys_from_mdt();
        
        //validate primary key
        String box_encoded_primary_key = headers.get('box-signature-primary');
        Boolean valid_primary_key = validate_keys(box_encoded_primary_key, mdt_record_map.get(PRIMARY_KEY_DEVELOPER_NAME), request_body, time_stamp);
        
        //validate secondary key
        String box_encoded_secondary_key = headers.get('box-signature-secondary');
        Boolean valid_secondary_key = validate_keys(box_encoded_secondary_key, mdt_record_map.get(SECONDARY_KEY_DEVELOPER_NAME), request_body, time_stamp);
        
        if( valid_timestamp && (valid_primary_key || valid_secondary_key)){
            return true;
        }
        
        return false;
    }
    
    /**
     * @description 
     *  Validates the timestamp in the webhook to ensure it's recent and within the 10-minute tolerance limit.
     *
     * @param time_stamp ISO8601 formatted timestamp string
     * @return Boolean indicating if timestamp is valid
     */
    @TestVisible 
    public static Boolean validate_time_stamp(String time_stamp){
        // Convert timestamp string to Datetime
		DateTime date_time_stamp = (DateTime)Json.deserialize('"'+time_stamp+'"', DateTime.class);
        // Calculate the difference in milliseconds
        Long time_difference_millis = DateTime.now().getTime() - date_time_stamp.getTime();
        // Check if difference is less than 10 minutes (600,000 ms) as per box documentation
		return ( time_difference_millis <= (10 * 60 * 1000) ) ;
    }
    
    /**
     * @description 
     *  Validates an HMAC key by generating a digest using the request body and timestamp,
     *  then comparing it with the encoded key from headers.
     *
     * @param box_encoded_header_key HMAC key from request header (Base64 encoded)
     * @param key_from_mdt The secret key retrieved from Custom Metadata
     * @param request_body Webhook body as Blob
     * @param time_stamp Timestamp from headers
     * @return Boolean indicating if the key is valid
     */
    @TestVisible
    private static Boolean validate_keys(String box_encoded_header_key, String key_from_mdt, Blob request_body, String time_stamp ){
        //Blob value of time_stamp
        Blob time_stamp_blob = Blob.valueOf(time_stamp);
        
        // Combine request_body + timestamp
        String combined_data_as_hex = EncodingUtil.convertToHex(request_body) + EncodingUtil.convertToHex(time_stamp_blob);
        Blob data_to_sign = EncodingUtil.convertFromHex(combined_data_as_hex);
        
        // Generate HMAC-SHA256 with Key
        Blob hmac_key = Crypto.generateMac(BOX_KEY_ENCRYPTING_ALGORITHM, data_to_sign, Blob.valueOf(key_from_mdt));
        String encoded_key = EncodingUtil.base64Encode(hmac_key);
		
		Boolean validated_key = ( encoded_key == box_encoded_header_key );   
        return validated_key;
    }
    
    /**
     * @description 
     *  Retrieves and decrypts webhook secret keys from Custom Metadata records.
     *
     * @return Map of DeveloperName to decrypted secret value
     */
    @TestVisible
    private static Map<String,String> get_keys_from_mdt(){
        //record developer name as key, decoded box key as value
        Map<String,String> mdt_record_map = new Map<String, String>();
        try{
            List<String> mdt_developer_names = new List<String>{PRIMARY_KEY_DEVELOPER_NAME,SECONDARY_KEY_DEVELOPER_NAME };
                for(Box_Webhook_Secret__mdt mdt_record: [SELECT 
                                                         Box_Encrypted_Secret__c,
                                                         Encryption_Key__c, 
                                                         developerName 
                                                         FROM Box_Webhook_Secret__mdt WHERE DeveloperName = :mdt_developer_names]){
                //decode with base64
                Blob encrypted_secret_blob = EncodingUtil.base64Decode(mdt_record?.Box_Encrypted_Secret__c);
                Blob encrypted_key_blob = EncodingUtil.base64Decode(mdt_record?.Encryption_Key__c); 
                //decrypt the key with ManagedIV
                Blob decrypted_data = Crypto.decryptWithManagedIV(DECRYPTION_ALGORITHM, encrypted_key_blob, encrypted_secret_blob);
                //add decrypted key to map
           		mdt_record_map.put(mdt_record?.developerName, decrypted_data.toString());
          }
        }catch(QueryException e){
            throw new QueryException(e.getMessage());
        }
        return mdt_record_map;
    }
    
    /**
     * @description 
     *  Parses the webhook JSON payload and determines the trigger event.
     *  Updates the corresponding Opportunity Document records status based on the Box_Sign_UUID and trigger event.
     *
     * @param jsonString Raw JSON string from the webhook payload
     */
    @TestVisible
    private static void update_oppdocs_status(String jsonString){
        //deserialize the response
        Map<String,Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        if(jsonMap != null){
            
            //get event from webhook
            String webhook_trigger_event = (String) jsonMap.get('trigger'); 											//SIGN_REQUEST.COMPLETED
            String trigger_event = (webhook_trigger_event!= null) ? (webhook_trigger_event.split('\\.'))[1] :'';		//taking COMPLETED from above value
            
            //check for additional_info
            Map<String,Object> additional_info_map = (Map<String,Object>)jsonMap.get('additional_info');
            if(additional_info_map != null){
                //get sign request id from Additional info
                String sign_request_id = (String)additional_info_map.get('sign_request_id');
                update_oppDocs_by_UUID(sign_request_id, trigger_event);
            }
        }
    }
    
    /**
     * @description 
     *  Finds Opportunity_Document__c records by Box Sign request UUID and updates their
     *  status based on the mapping from Box_Sign_Status__mdt metadata.
     *
     * @param sign_request_id Unique UUID of the Box Sign request
     * @param trigger_event Trigger event string from webhook (e.g., COMPLETED, SIGNATURE_REQUESTED, SIGNER_SIGNED)
     */
    @TestVisible
    private static void update_oppdocs_by_UUID(String sign_request_id , String trigger_event){
        List<Opportunity_Document__c> oppdocs_to_update =  new List<Opportunity_Document__c>();
        try{
            //get status from metadata
            Box_Sign_Status__mdt mdt_record = [ SELECT Id, 
                                        DeveloperName, 
                                        Webhook_Event__c, 
                                        Opportunity_Document_Status__c 
                                        FROM Box_Sign_Status__mdt 
                                        WHERE Webhook_Event__c = :trigger_event ];
 
            for(Opportunity_Document__c oppDoc: [ SELECT Id,
                                                 Status__c,
                                                 Box_Sign_UUID__c 
                                                 FROM Opportunity_Document__c WHERE Box_Sign_UUID__c = :sign_request_id ]){
                oppDoc.Status__c = mdt_record.Opportunity_Document_Status__c;
                oppdocs_to_update.add(oppDoc);
            }
            if(!oppdocs_to_update.isEmpty()){
                update oppdocs_to_update;
            }
        }catch(QueryException e){
            throw new QueryException(e.getMessage());
        }catch(DMLException e){
            throw new DMLException(e.getMessage());
        }
    }
    
    /*
	@HttpGet
    global static String doGet() {
    	return 'Service Called successfully';
    }*/
}
// URL: https://bbsi--pricingbox.sandbox.my.salesforce-sites.com/box/services/apexrest/boxSignWebhook