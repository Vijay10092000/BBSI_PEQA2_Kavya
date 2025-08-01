public class ApexActionIsPermissionSetAssignedToUser {
    
    @InvocableMethod(label='Is Permission Set Assigned To User' description='Returns whether user has access to permission set.' category='PermissionSet')
    public static List<String> getPermissionSetIdFromName(List<RequestParams> params) {
        List<String> results  = new List<String>();
        Map<String,Id> pSetIdMap = new Map<String,Id>();
        Set<String> psNames = new Set<String>();
        Set<Id> userIds = new Set<Id>();
        for (RequestParams param: params) {
            psNames.add(param.psName);
            userIds.add(param.userId);
        }
        List<PermissionSet> psList = [SELECT Id,Name FROM PermissionSet WHERE Name = :psNames];
        for(PermissionSet pSet: psList){
            pSetIdMap.put(pSet.Name,pSet.Id);
        }
        List<PermissionSetAssignment> pSetAssignment = [ SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :pSetIdMap.values() AND AssigneeId = :userIds ];
        System.debug('PsetAssignmet :'+pSetAssignment);
        if(pSetAssignment != null ){
            if(pSetAssignment.size() > 0){
                results.add('TRUE');
            }else{
                results.add('FALSE');
            }
        }
        return results;
    }
    
    /*
     *@description This class provides inputs to Box_Uploader Flow and Opp_SupportDocSelectExistingFile Flow
    */   
    public class RequestParams {
        @InvocableVariable(label='Permission Set Name' description='Name of the permission set' required=true)
        Public String psName;
        
        @InvocableVariable(label='User Id' description='Id of User record' required=true)
        Public String userId;
    }
}