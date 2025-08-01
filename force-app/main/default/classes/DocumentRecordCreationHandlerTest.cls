@IsTest
public class DocumentRecordCreationHandlerTest {

    @testSetup
    static void setupData() {
        List <Document__c> insertDocumnets = new List<Document__c>();
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity oldOpp = new Opportunity(
            Name = 'Old Opportunity',
            RecordTypeId = '01250000000NBi7AAG',
            States_of_Operation__c = 'CA;NY',
            Comp_Option__c = 'No Comp',
            Markup_Type__c = 'Bundled',
            CloseDate = Date.today().addDays(30),
            StageName = 'Qualification'
        );
        oppList.add(oldOpp);

        Opportunity newOpp1 = new Opportunity(
            Name = 'New Opportunity',
            RecordTypeId = '01250000000NBi7AAG',
            Comp_Option__c = 'Lease(Incentive)',
            States_of_Operation__c = 'CA',
            Markup_Type__c = 'Unbundled',
            CloseDate = Date.today().addDays(60),
            StageName = 'Prospecting'
        );
        oppList.add(newOpp1);
        
        Opportunity newOpp2 = new Opportunity(
            Name = 'New Opportunity2',
            RecordTypeId = '01250000000NBi8AAG',
            States_of_Operation__c = 'CA',
            Comp_Option__c = '',
            Markup_Type__c = '',
            CloseDate = Date.today().addDays(60),
            StageName = 'Prospecting'
        );
        oppList.add(newOpp2);
		Insert oppList;
        
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
        insertDocumnets.add(doc1);
		
        
        Document__c doc2 = new Document__c(
            Document_Name__c = 'Test1',
            State__c = 'Texas',
            Customer_Type__c = 'New',
            Product_Type__c = 'PEO',
            Comp_Option__c = 'With Comp',
            Type__c = 'Upload',
            Box_Template_Id_1__c = 'Test',
            Markup_Type__c = 'Unbundled'
        );
        insertDocumnets.add(doc2);
        insert insertDocumnets;
    }


    @isTest
    static void testGetRecords() {
        Opportunity oldOpp = [SELECT Id, RecordTypeId, States_of_Operation__c, Markup_Type__c,Comp_Option__c FROM Opportunity WHERE Name = 'Old Opportunity'];
        Opportunity newOpp = [SELECT Id, RecordTypeId, States_of_Operation__c, Markup_Type__c,Comp_Option__c FROM Opportunity WHERE Name = 'New Opportunity'];
        List<String> recordTypeIds = new List<String>{oldOpp.RecordTypeId};
        
        
        DocumentRecordCreationHandler.RequestParams params = new DocumentRecordCreationHandler.RequestParams();
        params.addedStateNames = new List<String>{'TX'};
        params.removedStateNames = new List<String>{'NY'};
        params.oldOpp = oldOpp;
        params.newOpp = newOpp;
        params.recordTypeIds = recordTypeIds;
        params.notAllStatesHandler = true;
        params.allStates = false;

        List<DocumentRecordCreationHandler.RequestParams> requestParamsList = new List<DocumentRecordCreationHandler.RequestParams>{params};
        Test.startTest();
        List<List<Document__c>> result = DocumentRecordCreationHandler.getRecords(requestParamsList);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testGetRecords2() {
        Opportunity oldOpp = [SELECT Id, RecordTypeId, States_of_Operation__c, Markup_Type__c,Comp_Option__c FROM Opportunity WHERE Name = 'Old Opportunity'];
        Opportunity newOpp = [SELECT Id, RecordTypeId, States_of_Operation__c, Markup_Type__c,Comp_Option__c FROM Opportunity WHERE Name = 'New Opportunity'];
        List<String> recordTypeIds = new List<String>{oldOpp.RecordTypeId};
        
        DocumentRecordCreationHandler.RequestParams params = new DocumentRecordCreationHandler.RequestParams();
        params.addedStateNames = new List<String>{null};
        params.removedStateNames = new List<String>{};
        params.oldOpp = oldOpp;
        params.newOpp = newOpp;
        params.recordTypeIds = recordTypeIds;
        params.notAllStatesHandler = true;
        params.allStates = false;

        List<DocumentRecordCreationHandler.RequestParams> requestParamsList = new List<DocumentRecordCreationHandler.RequestParams>{params};
        Test.startTest();
        List<List<Document__c>> result = DocumentRecordCreationHandler.getRecords(requestParamsList);
        Test.stopTest();
    }
    
    @isTest
    static void testGetRecords3() {
        Opportunity oldOpp = [SELECT Id, RecordTypeId, States_of_Operation__c, Markup_Type__c,Comp_Option__c FROM Opportunity WHERE Name = 'Old Opportunity'];
        Opportunity newOpp = [SELECT Id, RecordTypeId, States_of_Operation__c, Markup_Type__c,Comp_Option__c FROM Opportunity WHERE Name = 'New Opportunity2'];
		List<String> recordTypeIds = new List<String>{oldOpp.RecordTypeId};        
        
        DocumentRecordCreationHandler.RequestParams params = new DocumentRecordCreationHandler.RequestParams();
        params.addedStateNames = new List<String>{null};
        params.removedStateNames = new List<String>{};
        params.oldOpp = oldOpp;
        params.newOpp = newOpp;
        params.recordTypeIds = recordTypeIds;
        params.notAllStatesHandler = true;
        params.allStates = false;

        List<DocumentRecordCreationHandler.RequestParams> requestParamsList = new List<DocumentRecordCreationHandler.RequestParams>{params};
        Test.startTest();
        List<List<Document__c>> result = DocumentRecordCreationHandler.getRecords(requestParamsList);
        Test.stopTest();
    }
}