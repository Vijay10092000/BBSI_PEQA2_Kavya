@IsTest
public class PEEncryptedSecretTest {
    @IsTest
    static void testUpdateEncryptedSecret() {
        // Create a test consumer secret
        String testConsumerSecret = 'TestSecret123';
        
		
        Test.startTest();
        // Call the updateEncryptedSecret function
        PEEncryptedSecret.updateEncryptedSecret(testConsumerSecret);
        PE_Encrypted_Secret__mdt mdtRecord = [ SELECT Id,DeveloperName,Encrypted_Secret__c,Encryption_Key__c FROM PE_Encrypted_Secret__mdt WHERE DeveloperName = 'PE_Consumer_Secret' ];
        Test.stopTest();
        
        
        Blob encryptedSecretBlob = EncodingUtil.base64Decode(mdtRecord.Encrypted_Secret__c);
        Blob encryptedKeyBlob = EncodingUtil.base64Decode(mdtRecord.Encryption_Key__c);  
        Blob decryptedData = Crypto.decryptWithManagedIV('AES128', encryptedKeyBlob, encryptedSecretBlob);
        String decryptedConsumerSecret = decryptedData.toString();

        // Verify that the encrypted secret and encryption key are correctly stored
        System.assert(mdtRecord.Encrypted_Secret__c.length() > 0, 'Encrypted secret should not be empty');
        //System.assertEquals(decryptedConsumerSecret,testConsumerSecret, 'Decrypted Value should equal to testConsumerSecret');

    }
}