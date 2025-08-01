/**
 * Queueable class for handling Box folder operations related to Contracts.
 * This class implements the Queueable and Database.AllowsCallouts interfaces
 * to perform asynchronous operations that interact with external system Box.
 * As of now it will be called from Account_Services and Opportunity_Service
 */
public class ContractsBoxFolderServiceQueue implements Queueable, Database.AllowsCallouts{
	private Set<Id> externalIdChangedAccounts;
    private Set<Id> contractsFolderChangedAccounts;
    private Set<Id> newOppIds;
    private String contractsFolderId;
    
    
    /**
     * Constructor for ContractsBoxFolderServiceQueue.
     * Initializes the instance with sets of account IDs that have external IDs changed and contracts folder changed.
     * It is used in Account_Services
     * @param externalIdChangedAccounts Set of account IDs with external IDs changed.
     * @param contractsFolderChangedAccounts Set of account IDs with contracts folder changed.
     */
    public ContractsBoxFolderServiceQueue(Set<Id> externalIdChangedAccounts, Set<Id> contractsFolderChangedAccounts){
        this.externalIdChangedAccounts = externalIdChangedAccounts;
        this.contractsFolderChangedAccounts = contractsFolderChangedAccounts;
        this.newOppIds = null;
    }
    
    
    /**
     * Constructor for ContractsBoxFolderServiceQueue.
     * Initializes the instance with a set of new opportunity IDs.
     * It is used in Opportunity_Services
     * @param newOppIds Set of new opportunity IDs.
     */
    public ContractsBoxFolderServiceQueue(Set<Id> newOppIds){
        this.newOppIds = newOppIds;
        this.externalIdChangedAccounts = null;
        this.contractsFolderChangedAccounts = null;
    }
    
    
    /**
    * execute method
    * This method is called when the job is executed.
    * processes the accounts, opportunities and updates folder metadata and tags in Box.
    * @param context QueueableContext
    */
    public void execute(QueueableContext context){
        ContractsBoxFolderService contractsService = new ContractsBoxFolderService();
        List<Account> accountsToBeUpdated = new List<Account>();
        try{
            if(this.externalIdChangedAccounts != null && !this.externalIdChangedAccounts.isEmpty()){
                accountsToBeUpdated.addAll(contractsService.updateMetadataAndTagsToFolder(this.externalIdChangedAccounts));
                
            }
            if(this.contractsFolderChangedAccounts != null && !this.contractsFolderChangedAccounts.isEmpty()){
                contractsService.createContractWeblinkInOppOnAccountUpdate(this.contractsFolderChangedAccounts);
            }
            if(this.newOppIds != null && !this.newOppIds.isEmpty()){
                accountsToBeUpdated.addAll(contractsService.createWebLinkForNewOpportunities(this.newOppIds));
            }
            if(!accountsToBeUpdated.isEmpty()){
                update accountsToBeUpdated;
            }
            contractsService.commitChanges();
        }catch(Exception e){
            //create a Log__c record
            Log.write(Log.Severity.ERROR, 'ContractsBoxFolderServiceQueue Failed', e.getMessage(), e.getStackTraceString());
            //System.debug('ContractsBoxFolderServiceQueue failed: ' + e.getMessage());
        }
    }
}