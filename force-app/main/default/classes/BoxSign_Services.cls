/**
 * @description BoxSign_Services
 */
public class BoxSign_Services {

    public static void linkOppDocWithBoxSign(Map<Id, box__BoxSign__c> newBoxSign) {
        
        Map<String, box__BoxSign__c> boxSignUuidList = new Map<String, box__BoxSign__c>();
        List<Opportunity_Document__c> oppDocTBU = new List<Opportunity_Document__c>();
        
        // Create map of UUID to BoxSign
        for (box__BoxSign__c bSign : newBoxSign.values()) {
            boxSignUuidList.put(bSign.box__Uuid__c, bSign);
        }
        
        // Fetch list of OppDocs that has Box_Sign_UUID__c same as the BoxSignUUID being saved. These OppDocs will not have Box_Sign already set
        List<Opportunity_Document__c> oppDocs = [
            SELECT Id, Box_Sign_UUID__c, Box_Sign__c 
            FROM Opportunity_Document__c 
            WHERE Box_Sign_UUID__c = :boxSignUuidList.keySet() 
            	AND Box_Sign__c = null
        ];
        
        // Iterate through OppDocs, find the matching BoxSign, and set BoxSign on OppDocs
        if (oppDocs.size() > 0) {
            for (Opportunity_Document__c oppDoc : oppDocs) {
                if (oppDoc.Box_Sign__c == null) {
                    if (boxSignUuidList.get(oppDoc.Box_Sign_UUID__c) != null) {
                        oppDoc.Box_Sign__c = boxSignUuidList.get(oppDoc.Box_Sign_UUID__c).Id;
                        oppDocTBU.add(oppDoc);
                    }
                }
            }
            
            // Update OppDocs to set the Box_Sign reference
            if (oppDocTBU.size() > 0) {
                update oppDocTBU;
            }
        }
    }
}