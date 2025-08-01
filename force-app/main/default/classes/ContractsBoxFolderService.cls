/**
* ContractsBoxFolderService class
* This class is responsible for syncing folder metadata with Box for a list of accounts.
* It implements the Queueable and Database.AllowsCallouts interfaces to enable asynchronous execution and callouts.
* As of now , it is called from the ContractsBoxFolderServiceQueue class
*/
public class ContractsBoxFolderService{
    private final String SCOPE = 'enterprise';
    private final String TEMPLATE_NAME = 'contracts';
    private final String CONTRACTS_FOLDER_NAME = 'Contracts Team Folder';
    private BoxService boxServiceObj;
    
  
    /*
     * Constructor creates new BoxService object
     */
    public ContractsBoxFolderService(){
        boxServiceObj = new BoxService();
    }
    
    
    /**
     * * For each Account: If no Contracts_Accounts_SubFolder_Id__c is present, a new folder is created in Box and metadata,tags is added.
     * If the folder already exists, metadata and tags on the existing folder is updated.
     * @param externalIdChangedAccounts Set of Account Ids whose External_ID__c values have changed.
     * @return List of Account records that had a new Contract Account Subfolder created.     
     */
    public List<Account> updateMetadataAndTagsToFolder(Set<Id> externalIdChangedAccounts){

        Map<Id,Account> accountsMap = new Map<Id,Account>([SELECT Id,
                Name,
                FEIN__c,
                Status__c,
                External_ID__c,
                Contracts_Accounts_SubFolder_Id__c,
                Prospect_Branch__r.Name,  
                Prospect_Branch__r.External_ID__c 
                FROM Account WHERE Id IN :externalIdChangedAccounts]);
        //list to store Account for newly created Contract Account Subfolder Id
        List<Account> newContractsFolderAccounts = new List<Account>();
        
        //list to store Accounts to update existing metadata instance
        List<Account> existingContractsFolderAccounts = new List<Account>();
        
        for(Account acc: accountsMap.values()){
            if(String.isBlank(acc.Contracts_Accounts_SubFolder_Id__c)){
                newContractsFolderAccounts.add(acc);	//add the updated account to list
            }else{
                existingContractsFolderAccounts.add(acc);		//update metadata on existing contracts folder
            }
        } 
        
        //update metata for existing contracts foder
        if(!existingContractsFolderAccounts.isEmpty()){
            updateMetadataInstanceOnFolder(existingContractsFolderAccounts);
            addTagsToFolder(accountsMap.values());
        }
        
        List<Account> updatedAccounts = new List<Account>();
        //create metadata for new contracts folder
        if(!newContractsFolderAccounts.isEmpty()){
            //create metadata instance and tags on new contracts account sub folder
            updatedAccounts = createNewContractFolderAndAddMetadataTags(newContractsFolderAccounts);
        }
        //return accounts
        return updatedAccounts;
    }

	
    /**
     * Creates a new "Contracts" subfolder in Box for each given Account and updates the Account with the new folder ID.
     * Also creates metadata instances and adds tags to the newly created folders.
     *
     * @param accounts List of Account records that require new Contracts subfolders in Box.
     * @return List of Account records with updated Contracts_Accounts_SubFolder_Id__c values.
     */
    private List<Account> createNewContractFolderAndAddMetadataTags(List<Account> accounts){
        List<Account> updatedAccounts = new List<Account>();
        //get contracts folder Id
        Box_Contracts_Folder__c  contractsParentFolderId = [ SELECT FolderId__c FROM Box_Contracts_Folder__c 
                                                                WHERE Folder_Name__c = 'Contracts' LIMIT 1];
        for(Account acc:accounts){
            //create new contracts accounts subfolder in box
            String folderName = String.isNotBlank(acc.FEIN__c) ? (acc.FEIN__c+' - '+acc.Name) : ('null - '+acc.Name);
            String newContractsFolderId = this.boxServiceObj.createFolder(folderName, contractsParentFolderId.FolderId__c);			//create new contracts folder
            acc.Contracts_Accounts_SubFolder_Id__c = newContractsFolderId;		//update new contracts folderId in Account
            updatedAccounts.add(acc);
        }
        
        if(!updatedAccounts.isEmpty()){
            //create metadata instance on new contracts account sub folder
            createMetadataInstanceOnFolder(accounts);
            //add tags to folder
            addTagsToFolder(accounts);
        }
        return updatedAccounts;
    }
    
    
    /**
    * This method creates metadata on a folder in Box for a list of accounts.
    * @param accs List of Account records
    */
    private void createMetadataInstanceOnFolder(List<Account> accs){
        List<box.CreateBoxMetadataByFolderId.Request> createMetadataRequests = new List<box.CreateBoxMetadataByFolderId.Request>();
        if(!accs.isEmpty()){
            for(Account acc: accs){
                this.boxServiceObj.createMetadataOnFolder(acc, acc.Contracts_Accounts_SubFolder_Id__c,this.SCOPE, this.TEMPLATE_NAME);
            }
        }
    }
    
    
    /**
    * This method updates metadata on a folder in Box for a list of accounts.
    * @param accounts List of Account records
    */
    private void updateMetadataInstanceOnFolder(List<Account> accounts){
        List<box.UpdateBoxMetadataByFolderId.Request> updateMetadataRequests = new List<box.UpdateBoxMetadataByFolderId.Request>();
        if(!accounts.isEmpty()){
            for(Account acc: accounts){
                this.boxServiceObj.updateMetadataOnFolder(acc, acc.Contracts_Accounts_SubFolder_Id__c, this.SCOPE, this.TEMPLATE_NAME);
            }
        }
    }

    
    /**
    * This method adds tags to folders in Box for a list of accounts.
    * @param accountsToUpdateTags List of Account records to update tags
    */
    private void addTagsToFolder(List<Account> accountsToUpdateTags){
        for(Account acc: accountsToUpdateTags){
            //create tag list
            if(String.isNotBlank(acc.External_ID__c)){
                List<String> tagsList = acc.External_ID__c.split(',');
				this.boxServiceObj.addTagsToFolder(acc.Contracts_Accounts_SubFolder_Id__c, tagsList);
            }
        }
    }
    
    
    /**
     * Creates a web link in the Box folder associated with the given opportunity.
     * @param contractsFolderChangedAccounts list of account ids those Contracts_Accounts_Folder__c field gets udpated
     */
    public void createContractWeblinkInOppOnAccountUpdate(Set<Id> contractsFolderChangedAccounts){
        List<Account> accountsList = [ SELECT Contracts_Accounts_SubFolder_Id__c FROM Account WHERE Id IN :contractsFolderChangedAccounts ];
        Map<String,Set<String>> accIdFolderIdsMap = getOppBoxFolderIdsByAccountIds(contractsFolderChangedAccounts);
        if(!accountsList?.isEmpty() && !accIdFolderIdsMap?.isEmpty()){
            for(Account acc: accountsList){
                //get contracts folder sharedlink
                String sharedLinkUrl = this.boxServiceObj.createOrGetSharedLinkForFolder(acc.Contracts_Accounts_SubFolder_Id__c);
                if(String.isNotBlank(sharedLinkUrl)){
                    for(String folderId:accIdFolderIdsMap.get(acc.Id)){
                        this.boxServiceObj.createWeblink(sharedLinkUrl, folderId, CONTRACTS_FOLDER_NAME);
                    }
                }
            }
        }
    }
    
    
    /**
     * Retrieves a map of folder IDs by their corresponding Salesforce record IDs.
     * @param accountIds A set of record record IDs for which folder IDs are to be retrieved.
     * @return A map where the key is the account record ID and the value is the corresponding folder ID.
     */
    private Map<String,Set<String>> getOppBoxFolderIdsByAccountIds(Set<Id> accountIds){
        //map to store recordId as key and its corresponding folder Ids as value
        Map<String,Set<String>> accountFolderIdsMap = new Map<String,Set<String>>();
        Map<Id,Opportunity> oppsMap = new Map<Id,Opportunity>([ SELECT Id,AccountId FROM Opportunity WHERE AccountId IN :accountIds ]);
        if(!oppsMap.isEmpty()){
            List<box__FRUP__c > boxFrupRecs = [ SELECT box__Folder_ID__c,box__Record_ID__c FROM box__FRUP__c WHERE box__Record_ID__c IN :oppsMap.keySet() AND box__Object_Name__c = 'Opportunity' ];
            Map<Id, String> oppIdToFolderIdMap = new Map<Id, String>();
            
            for(box__FRUP__c frup: boxFrupRecs){
                oppIdToFolderIdMap.put(frup.box__Record_ID__c, frup.box__Folder_ID__c);
            }
            
            for(Opportunity opp:oppsMap.values()){
                String folderId;
                if(oppIdToFolderIdMap.containsKey(opp.Id)){
                    folderId = oppIdToFolderIdMap.get(opp.Id);
                }else{
                    //no folderId in frup, then create new folders
                    folderId = this.boxServiceObj.createFolderForRecord(opp.Id);
                }
                
                if(String.isNotBlank(folderId) && !accountFolderIdsMap.containsKey(opp.AccountId)){
                    accountFolderIdsMap.put(opp.AccountId, new Set<String>());
                }
                accountFolderIdsMap.get(opp.AccountId).add(folderId);
            }
        }
        return accountFolderIdsMap;
    }
    
    
    /**
     * Creates a web link for new opportunities within the specified set of opportunity IDs.
     * This method retrieves the associated account information, creates a folder for each opportunity,
     * and generates a shared link for the Contracts Account Subfolder if it exists, if contracts folder not exist will create new contracts folder.
     *
     * @param newOppIds A set of IDs representing the new opportunities for which web links need to be created.
     */
    public List<Account> createWebLinkForNewOpportunities(Set<Id> newOppIds){
        List<Opportunity> opps = new List<Opportunity>([ SELECT AccountId FROM Opportunity
                                                        WHERE Id IN :newOppIds ]);
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp: opps){
            accountIds.add(opp.AccountId);
        }
        Map<Id,Account> accountMap = new Map<Id,Account>([ SELECT Name,
                FEIN__c,
                Status__c,
                External_ID__c,
                Contracts_Accounts_SubFolder_Id__c,
                Prospect_Branch__r.Name,  
                Prospect_Branch__r.External_ID__c FROM Account WHERE Id IN :accountIds ]);
        
        //list of account need to update with new contracts folder
        List<Account> accountsToBeUpdated = new List<Account>();

        for(Opportunity opp:opps){
            //create folder for new opportunity record
            String folderId = this.boxServiceObj.createFolderForRecord(opp.Id);
            //get contracts folder sharedlink
            Account acc = accountMap.get(opp.AccountId);
            String contractsAccountSubfolderId = acc.Contracts_Accounts_SubFolder_Id__c;
            if(String.isBlank(contractsAccountSubfolderId)){
                accountsToBeUpdated.add(acc);
            }else{
                String sharedLinkUrl = this.boxServiceObj.createOrGetSharedLinkForFolder(contractsAccountSubfolderId);
                if(String.isNotBlank(sharedLinkUrl)){
                   this.boxServiceObj.createWeblink(sharedLinkUrl, folderId, CONTRACTS_FOLDER_NAME); 
                }
            }
        }
        List<Account> updatedAccounts = new List<Account>();
        if(!accountsToBeUpdated.isEmpty()){
            updatedAccounts = createNewContractFolderAndAddMetadataTags(accountsToBeUpdated);
        }
        return updatedAccounts;				//return accounts that need to be updated
    }
    

    /**
     * Commits all pending changes made to Box folders and metadata.
     * This method finalizes the creation of folders, metadata updates, and web links.
     * It should be called after all folder operations are completed.
     */
    public void commitChanges(){
        this.boxServiceObj.commitChanges();
    }
}