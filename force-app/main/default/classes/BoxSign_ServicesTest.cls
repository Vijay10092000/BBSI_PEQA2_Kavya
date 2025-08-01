@IsTest
public class BoxSign_ServicesTest {
	@testSetup
    static void setupTestData() {
        // Create a BoxSign record
        box__BoxSign__c boxSign1 = new box__BoxSign__c(box__Uuid__c = 'dded7611-641f-40bf-8044-02ee51f23746');
        box__BoxSign__c boxSign2 = new box__BoxSign__c(box__Uuid__c = 'dded7611-641f-40bf-8044-02ee51f23745');

        insert new List<box__BoxSign__c>{boxSign1,boxSign2} ;
        
        // Create Opportunity Documents
        Opportunity_Document__c oppDoc1 = TestFactoryOpportunity_Document.createOpportunityDocument(null, null, false);
        oppDoc1.Box_Sign_UUID__c = 'dded7611-641f-40bf-8044-02ee51f23746';
        

        Opportunity_Document__c oppDoc2 = TestFactoryOpportunity_Document.createOpportunityDocument(null, null, false);
        oppDoc2.Box_Sign_UUID__c = 'dded7611-641f-40bf-8044-02ee51f23746';

        Opportunity_Document__c oppDocWithSign = TestFactoryOpportunity_Document.createOpportunityDocument(null, null, false);
        oppDocWithSign.Box_Sign_UUID__c = 'dded7611-641f-40bf-8044-02ee51f23746';
        oppDocWithSign.Box_Sign__c = boxSign1.Id; // Already linked to a BoxSign

        insert new List<Opportunity_Document__c>{ oppDoc1, oppDoc2, oppDocWithSign };

    }
    
    @isTest
    static void testLinkOppDocWithBoxSign() {
        // Fetch test data
        box__BoxSign__c boxSign = [SELECT Id, box__Uuid__c FROM box__BoxSign__c WHERE box__Uuid__c='dded7611-641f-40bf-8044-02ee51f23746' LIMIT 1];
        System.debug('Box sign record :'+boxSign);
        
        // Create the input map
        Map<Id, box__BoxSign__c> boxSignMap = new Map<Id, box__BoxSign__c>();
        boxSignMap.put(boxSign.Id, boxSign);

        // Call method
        Test.startTest();
        BoxSign_Services.linkOppDocWithBoxSign(boxSignMap);
        Test.stopTest();

        // Verify that the Opportunity Document is updated correctly
        Opportunity_Document__c updatedOppDoc = [SELECT Id, Box_Sign__c FROM Opportunity_Document__c WHERE Box_Sign_UUID__c = :boxSign.box__Uuid__c LIMIT 1];
        System.assertNotEquals(null, updatedOppDoc.Box_Sign__c, 'Box_Sign__c should be populated');
        System.assertEquals(boxSign.Id, updatedOppDoc.Box_Sign__c, 'Box_Sign__c should match BoxSign Id');
    }
    
    @isTest
    static void testLinkOppDocWithBoxSign_NoMatchingUUID() {
        // Create a BoxSign record with a UUID that does not match any Opportunity Document
        // Fetch test data
        List<box__BoxSign__c> newBoxSigns = [SELECT Id, box__Uuid__c FROM box__BoxSign__c WHERE box__Uuid__c='dded7611-641f-40bf-8044-02ee51f23745'];
        System.debug('Box sign record :'+newBoxSigns);

        Map<Id, box__BoxSign__c> boxSignMap = new Map<Id, box__BoxSign__c>();
        for(box__BoxSign__c newBoxSign: newBoxSigns){
            boxSignMap.put(newBoxSign.Id, newBoxSign);
        }

        Test.startTest();
        BoxSign_Services.linkOppDocWithBoxSign(boxSignMap);
        Test.stopTest();

        // Verify that no Opportunity Document was updated
        List<Opportunity_Document__c> oppDocs = [SELECT Id, Box_Sign__c FROM Opportunity_Document__c WHERE Box_Sign_UUID__c = 'dded7611-641f-40bf-8044-02ee51f23745'];
        System.assertEquals(0, oppDocs.size(), 'No Opportunity Document Records updated');
    }
    
    @isTest
    static void testLinkOppDocWithBoxSign_LinkedDocs() {
        // Fetch test data
        List<box__BoxSign__c> boxSigns = [SELECT Id, box__Uuid__c FROM box__BoxSign__c WHERE box__Uuid__c = 'dded7611-641f-40bf-8044-02ee51f23746' ];

        Map<Id, box__BoxSign__c> boxSignMap = new Map<Id, box__BoxSign__c>();
        for(box__BoxSign__c boxSign:boxSigns){
            boxSignMap.put(boxSign.Id, boxSign);
        }

        Test.startTest();
        BoxSign_Services.linkOppDocWithBoxSign(boxSignMap);
        Test.stopTest();

        // Verify that the already linked document is not modified
        List<Opportunity_Document__c> alreadyLinkedDocs = [SELECT Id, Box_Sign__c FROM Opportunity_Document__c WHERE Box_Sign_UUID__c = 'dded7611-641f-40bf-8044-02ee51f23746' ];
        System.assertEquals(boxSigns[0].Id, alreadyLinkedDocs[0].Box_Sign__c, 'Already linked document should not be changed');
    }
}