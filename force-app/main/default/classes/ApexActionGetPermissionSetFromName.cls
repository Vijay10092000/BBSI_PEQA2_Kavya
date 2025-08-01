public class ApexActionGetPermissionSetFromName {

    @InvocableMethod(label='Get Permission Set From Name' description='Returns the list of Permission Set Ids corresponding to the specified permission set name.' category='PermissionSet')
    public static List<String> getPermissionSetIdFromName(List<RequestParams> params) {
        List<String> results  = new List<String>();
        for (RequestParams param: params) {
            List<PermissionSet> psList = [SELECT Id FROM PermissionSet WHERE Name = :param.psName];
            results.add(psList[0].Id);
        }
        return results;
    }
    
    /*
     *@description This class provides inputs to Box_Uploader Flow and Opp_SupportDocSelectExistingFile Flow
    */   
    public class RequestParams {
        @InvocableVariable(label='Permission Set Name' description='Name of the permission set' required=true)
        Public String psName;
    }
}