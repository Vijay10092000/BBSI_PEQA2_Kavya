/**
 * @description
 * Handles encryption and metadata deployment of Box webhook secret keys (Primary and Secondary).
 * Encrypts secrets using AES-128 and stores the encrypted data along with the encryption key in Custom Metadata.
 * Implements Metadata.DeployCallback to track the result of asynchronous metadata deployment.
 * 
 * This class is used to update `Box_Webhook_Secret__mdt` metadata records with encrypted secrets via Apex.
 * 
 * if there is only one key to update, keep the other as null
 */
public class BoxEncryptedSecretHandler implements Metadata.DeployCallback {
    
    private static final String BOX_ENCRYPTED_SECRET_FIELD = 'Box_Encrypted_Secret__c';
    private static final String ENCRYPTION_KEY_FIELD = 'Encryption_Key__c';
    public static final String ENCRYPTING_ALGORITHM = 'AES128';
    
    /**
     * @description
     * Encrypts the provided primary and/or secondary Box secret keys and updates corresponding Custom Metadata records.
     * Uses Managed IV encryption and deploys the metadata using asynchronous Metadata API.
     *
     * @param primary_key The plain text value of the primary secret key of Box webhook .
     * @param secondary_key The plain text value of the secondary secret key of Box webhook .
     */
    public static void update_encrypted_keys(String primary_key, String secondary_key){
        // Create deploy container and enqueue deployment
        Metadata.DeployContainer md_container = new Metadata.DeployContainer();
        
        try{
            if(String.isNotBlank(primary_key)){
                //metadata details
                String full_name_primary_key = 'Box_Webhook_Secret__mdt.Box_Primary_Key';
                String label_primary_key = 'Box Primary Key';
                //to update primary key
                Metadata.CustomMetadata custom_metadata = get_updated_metadata(primary_key, full_name_primary_key, label_primary_key);
                md_container.addMetadata(custom_metadata);
            }
            
            if(String.isNotBlank(secondary_key)){
                String full_name_secondary_key = 'Box_Webhook_Secret__mdt.Box_Secondary_Key';
                String label_secondary_key = 'Box Secondary Key';
                //to update secondary key
                Metadata.CustomMetadata custom_metadata = get_updated_metadata(secondary_key, full_name_secondary_key, label_secondary_key);
                md_container.addMetadata(custom_metadata);
            }
            
            // Use this class as the callback
            BoxEncryptedSecretHandler callback = new BoxEncryptedSecretHandler();
            //deploy the updated metadata
            Id jobId = Metadata.Operations.enqueueDeployment(md_container, callback);
        }catch(Exception e){
            System.debug('Error while updating encrypted keys in metadata'+e.getMessage());
        }
    }
	
    /**
     * @description
     * Encrypts a single Box secret using AES128 and prepares a CustomMetadata instance with base64 encoded key and secret.
     *
     * @param box_secret The Box secret string to encrypt.
     * @param full_name The fullName of the Custom Metadata record to update (e.g., 'Box_Webhook_Secret__mdt.Box_Primary_Key').
     * @param label The label for the Custom Metadata record.
     * @return Metadata.CustomMetadata instance populated with encrypted values.
     */
	@TestVisible
    private static Metadata.CustomMetadata get_updated_metadata(String box_secret, String full_name, String label){
        //generate key and encrypt with ManagedIV
        Blob key = Crypto.generateAesKey(128);
        Blob secret_blob = Crypto.encryptWithManagedIV(ENCRYPTING_ALGORITHM, key, Blob.valueOf(box_secret));
        
        //encode with base64
        String encryption_key = EncodingUtil.base64Encode(key);
        String encrypted_secret = EncodingUtil.base64Encode(secret_blob);
        
        //add the fields to map
        Map<String,String> fields = new Map<String, String>();
        fields.put(BOX_ENCRYPTED_SECRET_FIELD, encrypted_secret);
        fields.put(ENCRYPTION_KEY_FIELD, encryption_key);
        //retun the updated metadata
        return create_update_metadata(full_name, label, fields);
    }
    
    /**
     * @description
     * Constructs and returns a CustomMetadata instance populated with field-value pairs.
     *
     * @param fullName The unique fullName of the Custom Metadata record.
     * @param label The label for the Custom Metadata record.
     * @param fields A map of field API names and their respective values to be added to the metadata.
     * @return Metadata.CustomMetadata record with the provided fields.
     */
	@TestVisible
    private static Metadata.CustomMetadata create_update_metadata(String full_name, String label,Map<String,String> fields){
        Metadata.CustomMetadata custom_metadata = new Metadata.CustomMetadata();
        try{
            custom_metadata.fullName = full_name;
            custom_metadata.label = label;
            for(String field:fields.keySet()){
                // Add or update fields
                Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                customField.field = field;
                customField.value = fields.get(field);
                custom_metadata.values.add(customField);
            }        
        }catch(Exception e){
            System.debug('Error while updating encrypted secret in metadata'+e.getMessage());
        }
        return custom_metadata;
    }
    
	/**
     * @description handleResult will handle the job created for updation of metadata
     */
    public void handleResult(Metadata.DeployResult result,Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            // Deployment was successful
            System.debug('Deployment successful');
        } else {
            // Deployment was not successful
            System.debug('Deployment unsuccessful: ' + result.errorMessage);
        }
    } 
}