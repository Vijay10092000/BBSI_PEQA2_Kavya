@IsTest
public class ContactOpportunityDocumentHandlerTest {
	@testSetup
    static void testDataSetup(){
        //Create test account
        Account acc = TestFactoryAccount.createAccount('BBSI TEST ACCOUNT','Client');
		//create test contact
        Contact contact1 = TestFactoryContact.createContact('TESTCONTACT','BBSI','Client_Contact',acc.Id);
		//create test opportunities
        Opportunity opp1 = TestFactoryOpportunity.makeClient('BBSI TEST OPPORTUNITY 1', acc.Id, Date.valueOf('2025-04-03'), 'Proposal');
        opp1.States_of_Operation__c = 'Alabama;Arizona';
        opp1.Markup_Type__c='Bundled';
        opp1.Comp_Option__c='Lease (incentive)';
        
        Opportunity opp2 = TestFactoryOpportunity.makeClient('BBSI TEST OPPORTUNITY 2', acc.Id, Date.valueOf('2025-04-03'), 'Proposal');
        opp2.States_of_Operation__c = 'Alabama';
        opp2.Markup_Type__c='Bundled';
        opp2.Comp_Option__c='Lease (no incentive)';
        
        Opportunity opp3 = TestFactoryOpportunity.makeClient('BBSI TEST OPPORTUNITY 2', acc.Id, Date.valueOf('2025-04-03'), 'Proposal');
        opp3.States_of_Operation__c = 'Alabama';
        opp3.Markup_Type__c='Bundled';
        opp3.Comp_Option__c='No Comp';
        
        //insert list of opportunities
        insert new List<Opportunity>{opp1,opp2,opp3};
        
        //Create test Documents
        Document__c document1 = TestFactoryDocument.createDocument_SupportDocumentRecordType('BBSI TEST DOCUMENT 1','New','PEO','Alabama',false);
        document1.Deprecated__c = false;
        document1.Contact_Based__c = true;
        Document__c document2 = TestFactoryDocument.createDocument_SupportDocumentRecordType('BBSI TEST DOCUMENT 2','New','PEO','Alabama',false);
        document2.Deprecated__c = false;
        document2.Contact_Based__c = true;
        Document__c document3 = TestFactoryDocument.createDocument_SupportDocumentRecordType('BBSI TEST DOCUMENT 3','New','PEO','All States',false);
        document3.Deprecated__c = false;
        document3.Contact_Based__c = false;
        Document__c document4 = TestFactoryDocument.createDocument_SupportDocumentRecordType('BBSI TEST DOCUMENT 4','New','PEO','All States',false);
        document4.Deprecated__c = false;
        document4.Contact_Based__c = true;
        document4.Comp_Option__c = 'No Comp';
        
        List<Document__c> docsToCreate = new List<Document__c>{document1, document2, document3,document4};
        insert docsToCreate;
    }
    
    @IsTest
    public static void testgetOpportunityDocuments(){
        Contact con = [SELECT Id,Name,AccountId FROM Contact WHERE FirstName = 'TESTCONTACT'];
        List<Opportunity> opportunities = [ SELECT Id,States_of_Operation__c,Markup_Type__c,Comp_Option__c FROM Opportunity WHERE AccountId = :con.AccountId ];
        ContactOpportunityDocumentHandler.RequestParams param = new ContactOpportunityDocumentHandler.RequestParams();
        param.contact= con;
        param.opportunities = opportunities;
        
        Test.startTest();
        List<List<Opportunity_Document__c>> oppDocs = ContactOpportunityDocumentHandler.getOpportunityDocuments(new List<ContactOpportunityDocumentHandler.RequestParams>{param});
        Test.stopTest();
        
        //Assertions
        System.AssertEquals(9, oppDocs[0].size(), 'Four Opportunity Document Records Should be Created');
        for(Opportunity_Document__c oppDoc:oppDocs[0]){
            System.AssertEquals(con.Id,oppDoc.Contact_Signer__c,'Contact Singer for Created Opportunity Documents Should be Equal to Contact Id');
        }
    }
    
    @IsTest
    public static void testgetOpportunityDocumentsWithNoValues(){
        ContactOpportunityDocumentHandler.RequestParams param = new ContactOpportunityDocumentHandler.RequestParams();
        param.contact= null;
        param.opportunities = null;
        
        Test.startTest();
        List<List<Opportunity_Document__c>> oppDocs = ContactOpportunityDocumentHandler.getOpportunityDocuments(new List<ContactOpportunityDocumentHandler.RequestParams>{param});
        Test.stopTest();
        //Assertions
        System.AssertEquals(0, oppDocs[0].size(), 'No Opportunity Document Should Create');
    }
}