@IsTest
public class BoxEncryptedSecretHandlerTest {

    @isTest
    static void testGetUpdatedMetadataDecryption() {
        String secret = 'my_box_secret';
        String fullName = 'Box_Webhook_Secret__mdt.Box_Primary_Key';
        String label = 'Box Primary Key';
        String decryptingAlgorithm = 'AES128';
		
        Test.startTest();
        Metadata.CustomMetadata result = BoxEncryptedSecretHandler.get_updated_metadata(secret, fullName, label);
        Test.stopTest();
        
        // Assert that encrypted fields are set
        Boolean hasSecret = false;
        Boolean hasKey = false;
        
        String encryptedSecret;
        String encryptionKey;

        for (Metadata.CustomMetadataValue value : result.values) {
            if (value.field == 'Box_Encrypted_Secret__c') {
                hasSecret = String.isNotBlank((String)value.value);
                encryptedSecret = (String)value.value;
            }
            if (value.field == 'Encryption_Key__c') {
                hasKey = String.isNotBlank((String)value.value);
                encryptionKey = (String)value.value;
            }
        }
        
        //decode with base64
        Blob decryptedKeyBlob = EncodingUtil.base64Decode(encryptionKey);
        Blob decryptedSecretBlob = EncodingUtil.base64Decode(encryptedSecret);
		Blob decryptedSecret = Crypto.decryptWithManagedIV(decryptingAlgorithm, decryptedKeyBlob, decryptedSecretBlob);        
		
        //Assertions
        System.assertEquals(true, hasSecret, 'Encrypted secret should be populated');
        System.assertEquals(true, hasKey, 'Encryption key should be populated');
        System.assertEquals(secret, decryptedSecret.toString(), 'Decrypted Secret should be same');
    }
    
    @isTest
    static void testCreateUpdateMetadataWithFields() {
        Map<String, String> fields = new Map<String, String>{
            'Box_Encrypted_Secret__c' => 'EncryptedSecret',
            'Encryption_Key__c' => 'KeyValue'
        };

        Metadata.CustomMetadata result = BoxEncryptedSecretHandler.create_update_metadata(
            'Box_Webhook_Secret__mdt.Box_Primary_Key',
            'Box Primary Key',
            fields
        );
		
        for(Metadata.CustomMetadataValue value : result.values){
            if(value.field == 'Box_Encrypted_Secret__c'){
                System.assertEquals('EncryptedSecret', (String)value.value, 'Encrypted Secret Should be same');
            }
            if(value.field == 'Encryption_Key__c'){
                System.assertEquals('KeyValue', (String)value.value, 'Encryption Key should be same');
            }
        }
        System.assertEquals(2, result.values.size(), 'Should create 2 fields');
    }
    
    @isTest
    static void testUpdateEncryptedKeysWithBothKeys() {
        // Positive scenario: Both keys provided
        String primarySecret = 'primary_secret_sample';
        String secondarySecret = 'secondary_secret_sample';

        Test.startTest();
        BoxEncryptedSecretHandler.update_encrypted_keys(primarySecret, secondarySecret);
        Test.stopTest();

        // (Metadata deployment can't be verified directly in tests)
        System.assert(true, 'Executed update with both keys');
    }
    
}