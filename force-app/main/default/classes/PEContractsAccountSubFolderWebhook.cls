/**
 * @description
 * REST resource class to handle HTTP POST requests for creating "Contracts Accounts Subfolder"
 * under the Box Contracts folder based on the Account ID provided in the request URI.
 * 
 * If a subfolder already exists on the Account, it returns the existing folder ID.
 * Otherwise, it creates a new folder using the Box integration, updates the Account record,
 * and returns the new folder ID.
 * 
 * Endpoint: /services/apexrest/create-contracts-subfolder/{AccountId}
 */
@RestResource(urlMapping='/createContractsSubfolder')
global class PEContractsAccountSubFolderWebhook {
    private static final String SCOPE = 'enterprise';
    private static final String TEMPLATE_NAME = 'contracts';
     /**
     * @description
     * Handles HTTP POST request to create a Contracts subfolder for the specified Account in Box.
     * Uses the Account's FEIN and Name for naming the folder.
     * 
     * @example
     * POST /services/apexrest/create-contracts-subfolder/
     */
	@HttpPost
    global static void createFolder() {
        //get request
        RestRequest req = RestContext.request;
        //assign response 
        RestResponse res = RestContext.response;
        //validate request body
        if(req.requestBody.toString()  == ''){
            res = createErrorResponse(400, 'Request body is required and cannot be null or empty.');
            return;
        }
        //to fetch accountId from Request body
        Map<String,object> reqMap = (Map<String,object>)JSON.deserializeUntyped(req.requestBody.toString());
        String accountId='';
        if(reqMap.containsKey('accountId')){
            accountId = (String)reqMap.get('accountId');
        }
        //response
        Map<String,String> resMap = new Map<String,String>();
        // Validate accountId
        if (String.isBlank(accountId)) {
            res = createErrorResponse(400, 'Account Id is Required to Create Contract Account Subfolder.');
            return;
        }

        try{
            
            //get account by Id
            Account account = [SELECT Id, Name, FEIN__c, Contracts_Accounts_SubFolder_Id__c, Status__c,External_ID__c,Prospect_Branch__r.Name, Prospect_Branch__r.External_ID__c
                               FROM Account WHERE Id = :accountId LIMIT 1];
            //get contracts folder from Custom Settings
            Box_Contracts_Folder__c contractsCustomSetting = [SELECT Id, FolderId__c FROM Box_Contracts_Folder__c WHERE Folder_Name__c = 'Contracts' LIMIT 1];
            //check parent contract folder in custom setting
            if(String.isBlank(contractsCustomSetting.FolderId__c)){
                res = createErrorResponse(404, 'Contracts Parent Folder not found in Salesforce.');
                return;
            }
            //check Contracts_Accounts_Subfolder_Id__c in account
            if (String.isBlank(account.Contracts_Accounts_SubFolder_Id__c)){
                String folderName = account.FEIN__c + ' - ' + account.Name;
                String parentFolderId = contractsCustomSetting.FolderId__c;

                //store folder Id
                String newFolderId = createNewFolder(folderName, parentFolderId, account);
                
                //update the new Contracts Accounts Subfolder in account
                Account acc = new Account(Id = account.Id, Contracts_Accounts_SubFolder_Id__c = newFolderId);
                update acc;
				
                res = createSuccessResponse(200, newFolderId);
                return;
            }else{
                res = createSuccessResponse(200, account.Contracts_Accounts_SubFolder_Id__c);
                return;
            }
        }catch(QueryException e){
            res = createErrorResponse(404, 'data not found');
            return;
        }
        catch(Exception e) {
            res = createErrorResponse(500, e.getMessage());
            return;
        }   
    }

    
    /**
     * Creates a new folder in Box under the given parent folder, and if successful:
     * - Creates metadata on the folder for the given Account.
     * - Adds tags to the folder based on the Account's External_ID__c.
     *
     * @param folderName     The name of the folder to be created.
     * @param parentFolderId The ID of the parent folder under which the new folder will be created.
     * @param acc            The Account record used to generate metadata and tags.
     * @return The ID of the newly created folder, or null if folder creation failed.
     */
    @TestVisible
    private static String createNewFolder(String folderName, String parentFolderId, Account acc){
        //return new BoxService().createFolder(folderName, parentFolderId);
        BoxService boxService = new BoxService();
        String folderId = boxService.createFolder(folderName, parentFolderId);
        if(String.isNotBlank(folderId)){
            //create metadata on new contracts folder
            boxService.createMetadataOnFolder(acc, folderId, SCOPE, TEMPLATE_NAME);
            List<String> tags = acc.External_ID__c?.split(',');
            boxService.addTagsToFolder(folderId, tags);		//add tags to folder
        }
        return folderId;
    }

    
    /**
     * @description
     * Builds a standardized error response with the given HTTP status code and message.
     *
     * @param statusCode The HTTP status code to be returned (e.g., 400, 404, 500)
     * @param responseBody The error message to be returned in the response body
     * @return RestResponse The constructed REST response with error details
     */
    private static RestResponse createErrorResponse(Integer statusCode, String responseBody){
        Map<String,String> resMap = new Map<String,String>();
        resMap.put('Error Message', responseBody);
        String jsonRes = JSON.serialize(resMap);
        //create response
        RestResponse res = RestContext.response;
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(jsonRes);
        
        //return 
        return res;
    }
    
    
    /**
     * @description
     * Builds a standardized success response with the given HTTP status code and folder ID.
     *
     * @param statusCode The HTTP status code to be returned (typically 200)
     * @param responseBody The folder ID or success message to include in the response body
     * @return RestResponse The constructed REST response with success details
     */
    private static RestResponse createSuccessResponse(Integer statusCode, String responseBody){
        Map<String,String> resMap = new Map<String,String>();
        resMap.put('folderId', responseBody);
        String jsonRes = JSON.serialize(resMap);
        //create response
        RestResponse res = RestContext.response;
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(jsonRes);
        
        //return 
        return res;
    }
     
}