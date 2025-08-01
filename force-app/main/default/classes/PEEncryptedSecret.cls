/**
 * @description
 * Handles encryption of PE_AccOpp_ConnApp connected app consumer secret and updates PE Encrypted Secret metadata with encrypted secret  .
 * Encrypts secret using AES-128 and stores the encrypted data along with the encryption key in Custom Metadata.
 * Implements Metadata.DeployCallback to track the result of asynchronous metadata deployment.
 * 
 * This class is used to update `PE_Encrypted_Secret__mdt` metadata records with encrypted secrets via Apex.
 */
public class PEEncryptedSecret implements Metadata.DeployCallback {
    
    private static final String ENCRYPTED_SECRET_FIELD = 'Encrypted_Secret__c';
    private static final String ENCRYPTION_KEY_FIELD = 'Encryption_Key__c';
    public static final String ENCRYPTING_ALGORITHM = 'AES128';
    
    /**
     * @description updateEncryptedSecret will encrypt the consumer secret and store it in metadata:PE Encrypted Secret
     * @param consumerSecret that needs to be encrypted
     * 
     * If a new consumer secret is generated for PE_AccOpp_ConnApp connected app, then call this method with new generated consumer secret
     */
    Public static void updateEncryptedSecret(String consumerSecret){
        //custom metadata details
        String fullName = 'PE_Encrypted_Secret__mdt.PE_Consumer_Secret';
        String label = 'PE Consumer Secret';
        
        Blob key = Crypto.generateAesKey(128);
        String encryptionKey = EncodingUtil.base64Encode(key);
        Blob secretBlob = Crypto.encryptWithManagedIV(ENCRYPTING_ALGORITHM, key, Blob.valueOf(consumerSecret));
        String encryptedSecret = EncodingUtil.base64Encode(secretBlob);
        //add fields to map
        Map<String,String> fields = new Map<String,String>();
        fields.put(ENCRYPTED_SECRET_FIELD,encryptedSecret);
        fields.put(ENCRYPTION_KEY_FIELD,encryptionKey);
        createUpdateMetadata(fullName,label,fields);
    }
 	
    /**
     * @description createUpdateMetadata create or update the metadata records
     * @param fullName apiName of metadata and record
     * @param label record label
     * @param  fields custom fields that needs to update 
     */
    @TestVisible
    private static void createUpdateMetadata(String fullName, String label, Map<String,String> fields){
        try{
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = fullName;
            customMetadata.label = label;
            for(String field:fields.keySet()){
                // Add or update fields
                Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                customField.field = field;
                customField.value = fields.get(field);
                customMetadata.values.add(customField);
            }        
            // Create deploy container and enqueue deployment
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(customMetadata);
            // Use this class as the callback
            PEEncryptedSecret callback = new PEEncryptedSecret();
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }catch(Exception e){
            System.debug('Error while updating encrypted secret in metadata'+e.getMessage());
        }
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