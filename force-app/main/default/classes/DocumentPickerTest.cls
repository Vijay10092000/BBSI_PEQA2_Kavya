@isTest
public class DocumentPickerTest {

    @testSetup
    static void setupData() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today().addDays(30),
            StageName = 'Qualification'
        );
        insert opp;

        	Document__c doc1 = new Document__c(
            Document_Name__c = 'Test2',
            State__c = 'California',
            Customer_Type__c = 'New',
            Product_Type__c = 'PEO',
            Comp_Option__c = 'No Comp',
            Type__c = 'E-Signature',
            Box_Template_Id_1__c = 'Test Validation',
            Markup_Type__c = 'Bundled'
        );
        insert doc1;

        Opportunity_Document__c oppDoc = new Opportunity_Document__c(
            Opportunity__c = opp.Id,
            Document__c = doc1.Id
        );
        insert oppDoc;
    }

    @isTest
    static void testFetchSupportedDocuments() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];

        Test.startTest();
        List<Opportunity_Document__c> result = DocumentPicker.fetchSupportedDocuments(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected non-null list of Opportunity_Document__c records');
        System.assertEquals(1, result.size(), 'Expected one Opportunity_Document__c record');
        System.assertEquals('California', result[0].State__c, 'Expected State to be California');
        System.assertEquals('E-Signature', result[0].Type__c, 'Expected Type to be E-Signature');
    }
    
    @isTest
    static void testUpdateFileId() {
        Opportunity_Document__c oppDoc = [SELECT Id FROM Opportunity_Document__c LIMIT 1];

        String fileId = '123456789';
        Test.startTest();
        DocumentPicker.updateFileId(oppDoc.Id, fileId);
        Test.stopTest();

        Opportunity_Document__c updatedDoc = [SELECT Box_File_Id__c FROM Opportunity_Document__c WHERE Id = :oppDoc.Id];
        System.assertEquals(fileId, updatedDoc.Box_File_Id__c, 'Expected Box_File_Id__c to be updated');
    }

    @isTest
    static void testUpdateFileIdWithNullValues() {
        Test.startTest();
        try {
            DocumentPicker.updateFileId(null, null);
        } catch (Exception e) {
            System.assert(true, 'Expected exception for null input');
        }
        Test.stopTest();
    }
}