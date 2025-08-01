@IsTest
public class BoxSignRequestParamsTest {
    @isTest
    static void testBoxSignRequestParamsInstantiation() {
        //create account
        Account acc = TestFactoryAccount.createAccount('BBSI TEST ACCOUNT','Client');
        //create opportunity
        Opportunity  opp = TestFactoryOpportunity.createClient('BBSI TEST OPP', acc.Id, System.today(), 'Prospecting' );
        
        //create an Document
        Document__c doc = TestFactoryDocument.createDocument_SupportDocumentRecordType('BBSI TEST DOCUMENT','NEW', 'PEO', 'ALL STATES', false);
        doc.Box_Template_Id_1__c = 'TemplatefileId1';
        insert doc;
        
        //create Opportunity Document__c
        Opportunity_Document__c oppDoc1 = TestFactoryOpportunity_Document.createOpportunityDocument(opp.Id, doc.Id, false);
        
        //Opportunity_Document__c oppDoc2 =  TestFactoryOpportunity_Document.createOpportunityDocument(opp.Id, doc.Id, false);
        
        insert new List<Opportunity_Document__c>{oppDoc1};
            
            
        // Create a BoxSignRequestParams instance
        BoxSignRequestParams param = new BoxSignRequestParams();
        param.oppId = '006XXXXXXXXXXXX';
        param.effectiveDate = ''+System.today()+'';
        param.parentFolder = '123456789';
        //signer
        box.Signer signer = new box.Signer();
        signer.email = 'test@mail.com';
        signer.order = 0;
        signer.level = 'Signer';
        param.signers = new List<box.Signer>{signer};
        param.fileIds = new List<String>{ 'file123', 'file456' };
        param.oppDocs = new List<Opportunity_Document__c>{ oppDoc1 };
        param.boxUserId = '987654321';
        param.emailSubject = 'TEST EMAIL SUBJECT';
        param.emailMessage = 'TEST EMAIL MESSAGE';
        
        // Assert values are set correctly
        System.assertEquals('006XXXXXXXXXXXX', param.oppId);
        System.assertEquals(''+System.today()+'', param.effectiveDate);
        System.assertEquals('123456789', param.parentFolder);
        System.assertEquals(1, param.signers.size());
        System.assertEquals(2, param.fileIds.size());
        System.assertEquals(1, param.oppDocs.size());
        System.assertEquals('987654321', param.boxUserId);
    }
}