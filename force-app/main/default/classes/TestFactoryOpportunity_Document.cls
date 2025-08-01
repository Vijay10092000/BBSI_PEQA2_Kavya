@IsTest
public class TestFactoryOpportunity_Document {
    public static Opportunity_Document__c createOpportunityDocument(Id oppId, Id docId, Boolean isInsert){
        Opportunity_Document__c oppDoc = new Opportunity_Document__c(Opportunity__c = oppId,
                                                                   Document__c = docId);
        if(isInsert){
            insert oppDoc;
        }
        return oppDoc;
    }
    /*
    public static Opportunity_Document__c makeOpportunityDocument(Id oppId, Id docId){
        Opportunity_Document__c oppDoc = new Opportunity_Document__c(Opportunity__c = oppId,
                                                                   Document__c = docId);
        return oppDoc;
    }
	*/
}