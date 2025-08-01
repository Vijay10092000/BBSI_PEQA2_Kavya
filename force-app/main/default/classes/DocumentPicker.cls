/*
 * @description This Apex Class is invoked by boxBaseComp Component 
 * It also updates Box File Id on Opportunity_Document__c records
*/
public class DocumentPicker {
    /*
     * @description this method retrieves Opportunity_Document__c records 
 	 * based on States_of_Operation__c,MarkupType__c, ProductType__c,CustomerType__c,CompOption__c of Opportunity
 	 * @param oppId is Opportunity Record Id
 	 * @return List of Opportunity_Document__c records
	*/
    @AuraEnabled()
    public static List<Opportunity_Document__c> fetchSupportedDocuments(String oppId) {
        System.debug('Opp Id :'+oppId);
        List<Opportunity_Document__c> oppDocs = new List<Opportunity_Document__c>();
        try{
            if(oppId != null){
                oppDocs = [ SELECT Id, Type__c, State__c, Status__c, Document_Name__c, Box_File_Id__c, Document__r.RecordType.DeveloperName FROM Opportunity_Document__c WHERE Opportunity__c = :oppId ];
            }
        }catch(DmlException e){
            System.debug('Exception while fetching Opportunity Document records :'+e.getMessage());
        }
        return oppDocs;
    }
	
    /*
     * @description this method udpated Box File Id on Opportunity_Document__c records
     * @param oppDocdId is Opportunity_Document__c record Id, fileId is BoxFileId that is going to be updated in Opportunity_Document__c record
	*/
    
    @AuraEnabled
    public static void updateFileId(String oppDocId, String fileId) {
        try {
            if(oppDocId != null && fileId != null){
                Opportunity_Document__c oppDocument = new Opportunity_Document__c();
                oppDocument.Id = oppDocId;
                oppDocument.Box_File_Id__c = fileId;
                if(oppDocument != null ){
                    update oppDocument;
                }
            } 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}