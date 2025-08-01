/**
 * @description CanvasLifeCycleHandler contains methods for excluding context and addding parameters into the Canvas App
 */
public class CanvasLifeCycleHandler implements Canvas.CanvasLifecycleHandler{
    /**
	 * @description excludeContextTypes excludes the Organization and User context data and returns the result.
	 * @return excluded
	 */
    public Set<Canvas.ContextTypeEnum> excludeContextTypes(){
        Set<Canvas.ContextTypeEnum> excluded = new Set<Canvas.ContextTypeEnum>();
        excluded.add(Canvas.ContextTypeEnum.ORGANIZATION);
        excluded.add(Canvas.ContextTypeEnum.USER);

        return excluded;
    }
    
    public void onRender(Canvas.RenderContext renderContext) {
        // Get the Environment context from the RenderContext
        Canvas.EnvironmentContext env = renderContext.getEnvironmentContext();  
        
        System.debug(env);

        /**Add a new custom param to the set of custom params
		 *First, get the current custom params
		 */
        //fetching the list of custom permissions
        Set<String> customPermissions = getCustomPermissions();
      
        Map<String, Object> previousParams =
            (Map<String, Object>) JSON.deserializeUntyped(env.getParametersAsJSON());
        try{
          Id recordId = (Id)previousParams.get('recordId'); 
            String objectType = recordId.getSobjectType().toString();
            if(objectType == 'Account') {
                //fetching account record based on recordId
                Account acc = getAccount(recordId);
                // Add a 'newCustomParam' to our Map
                if(acc != null){
                    previousParams.put('Name', acc.Name);
                    previousParams.put('Industry', acc.Custom_Industry__c);
                    previousParams.put('BBSI_Location__c', acc.BBSI_Location__c);
                    previousParams.put('Customer_Class', acc.Customer_Class__c);
                }
                
            } else if(objectType == 'Opportunity') {
                //fetching opportunity record based on recordId
                Opportunity oppty = getOpportunity(recordId);
                // Add a 'newCustomParam' to our Map
                If(oppty != null){
                    previousParams.put('Name', oppty.Name);
                    previousParams.put('Industry',oppty.Account.Custom_Industry__c);
                    previousParams.put('AccountId', oppty.AccountId);
                    previousParams.put('CloseDate', oppty.CloseDate);
                }
                
        	}  
        }catch(Exception e){
            System.debug('Excepption :'+e.getMessage());
        }
        //add custom permissions to our map
        previousParams.put('Custom Permissions',customPermissions);
       
        // Now, replace the parameters
        env.setParametersAsJSON(JSON.serialize(previousParams));
    }
    
    /**
	 * @description getPermissionSets fetches the list of PermissionSets assigned to logged in user and returns the result.
	 * @return List of permSetAssignments
	 */
    
    Private Static List<PermissionSetAssignment> getPermissionSets(){
        Id userid = UserInfo.getUserId();
        
        List<PermissionSetAssignment> permSetAssignments = [
            SELECT PermissionSetId,PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId =:userid AND PermissionSet.ProfileId =null
        ];
        
        return permSetAssignments;
    }
    
    /**
	 * @description getCustomPermissions fetches the list of custom permissions assigned to logged in user and returns the result.
	 * @return List of CustomPermission
	 */
    
    Public Static Set<String> getCustomPermissions(){
        Set<Id> permSetIds = new Set<Id>();
        for (PermissionSetAssignment permSetAssignment : getPermissionSets()) {
            permSetIds.add(permSetAssignment.PermissionSetId);
        }
        
        List<CustomPermission> customPermissions = [
            SELECT DeveloperName, Id
            FROM CustomPermission
            WHERE Id IN (
                SELECT SetupEntityId
                FROM SetupEntityAccess
                WHERE ParentId IN :permSetIds
            )
        ];
        
        Set<String> developerNames = new Set<String>();
        for(CustomPermission customPerm : customPermissions){
            developerNames.add(customPerm.DeveloperName);
        }        
        return developerNames;
    }
    
    /**
	 * @description getAccount fetches the Account record and returns the result.
	 * @return Account
	 */
    
    Private Static Account getAccount(Id recordId){
        Account acc = [SELECT Id, Name, Custom_Industry__c, BBSI_Location__c,Customer_Class__c FROM Account WHERE Id=:recordId LIMIT 1];
        return acc;
    }
    
    /**
	 * @description getOpportunity fetches the Opportunity record and returns the result.
	 * @return Opportunity
	 */
    
    Public Static Opportunity getOpportunity(Id recordId){
        Opportunity oppty = [SELECT Id, Name, Account.Name, Account.Custom_Industry__c, CloseDate FROM Opportunity WHERE Id=:recordId LIMIT 1];
        return oppty;
    }
}