/**
 * @description A parameter wrapper class used for sending inputs from a Salesforce Flow to an Apex Invocable method
 * that initiates a Box Sign request. 
 * This class uses @AuraEnabled to make it available in Flows as an Apex-defined data type,
 * and @InvocableVariable to expose individual fields to the Flow.
 * Used in flow - Support Document E-Signature
 */
public class BoxSignRequestParams {
    //to make it available in Invocable methods, used @Invocable annotation
    //to make it availabe in flow as apex-defined data type , used @AuraEnabled annotation
    @AuraEnabled
    @InvocableVariable(required=true)
    public String oppId;
    @AuraEnabled
    @InvocableVariable
    public String effectiveDate;
    @AuraEnabled
    @InvocableVariable(required=true)
    public String parentFolder;
    @AuraEnabled
    @InvocableVariable(Label='Signers' required=true)
    public List<box.Signer> signers;
    @AuraEnabled
    @InvocableVariable(required=true)
    public List<String> fileIds;
    @AuraEnabled
    @InvocableVariable(required=true)
    public List<Opportunity_Document__c> oppDocs;
    @AuraEnabled
    @InvocableVariable(required=true)
    public String boxUserId;
    @AuraEnabled
    @InvocableVariable
    public String emailSubject;
    @AuraEnabled
    @InvocableVariable
    public String emailMessage;
    @AuraEnabled
    @InvocableVariable(label = 'Reminders Enabled' required=true)
    public Boolean areRemindersEnabled;
    @AuraEnabled
    @InvocableVariable(label = 'Days Valid' required=true)
    public Integer daysValid;
}