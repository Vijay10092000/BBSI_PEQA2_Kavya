@IsTest
public class ApexActionIsPSetAssignedToUserTest {
	@testSetup
    static void setupTestData(){
        // Create a Permission Set
        PermissionSet ps1 = new PermissionSet(Name = 'BBSI_Test_Permission_Set', Label='BBSI Test Permission Set');
        PermissionSet ps2 = new PermissionSet(Name = 'BBSI_Test_Permission_Set2', Label='BBSI Test Permission Set 2');
        
        insert new List<PermissionSet>{ps1,ps2};
        
        User testUser = TestFactoryUser.createUser('BBSI firstname','BBSI lastname','BBSI Standard','910');
        
        PermissionSetAssignment pSetAssignment = TestFactoryPermissionSetAssignment.createPermissionSetAssignment(ps1.Id,testUser.Id);
    }
    
    @isTest
    static void testUserHasPermissionSet() {
        PermissionSet ps = [ SELECT Id,Name,Label FROM PermissionSet WHERE Name = 'BBSI_Test_Permission_Set' LIMIT 1];
        
        User testUser = [ SELECT Id FROM User WHERE firstname = 'BBSI firstname' LIMIT 1];
        
        List<PermissionSetAssignment> psetAssignment = [ SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id AND PermissionSetId = :ps.Id ];
        
        ApexActionIsPermissionSetAssignedToUser.RequestParams param = new ApexActionIsPermissionSetAssignedToUser.RequestParams();
        param.psName = ps.Name;
        param.userId = testUser.Id;
        
        List<ApexActionIsPermissionSetAssignedToUser.RequestParams> params = new List<ApexActionIsPermissionSetAssignedToUser.RequestParams>();
        params.add(param);
        
        Test.startTest();
        List<STring> result = ApexActionIsPermissionSetAssignedToUser.getPermissionSetIdFromName(params);
        Test.stopTest();
        
        System.assertEquals(1,result.size(),'Result list should contain one element');
        System.assertEquals('TRUE',result[0],'User should have Permission Set Assigned');
    }
    
    @isTest
    static void testUserDoesNotHavePermissionSet() {
        // Fetch test data
        User testUser = [ SELECT Id FROM User WHERE firstname = 'BBSI firstname' LIMIT 1];

        // Create input parameters with a non-existing permission set
        ApexActionIsPermissionSetAssignedToUser.RequestParams param = new ApexActionIsPermissionSetAssignedToUser.RequestParams();
        param.psName = 'BBSI_Test_Permission_Set2';
        param.userId = testUser.Id;

        List<ApexActionIsPermissionSetAssignedToUser.RequestParams> paramList = new List<ApexActionIsPermissionSetAssignedToUser.RequestParams>{ param };

        // Call method
        Test.startTest();
        List<String> results = ApexActionIsPermissionSetAssignedToUser.getPermissionSetIdFromName(paramList);
        Test.stopTest();

        // Verify that the user does not have the permission set
        System.assertEquals(1, results.size(), 'Result list should contain one element');
        System.assertEquals('FALSE', results[0], 'User should NOT have permission set assigned');
    }
    
    @isTest
    static void testEmptyInputList() {
        // Call method with empty list
        Test.startTest();
        List<String> results = ApexActionIsPermissionSetAssignedToUser.getPermissionSetIdFromName(new List<ApexActionIsPermissionSetAssignedToUser.RequestParams>());
        Test.stopTest();

        // Verify that the result list is empty
        System.assertEquals(1, results.size(), 'Result list should have one when input list is empty');
        System.assertEquals('FALSE', results[0], 'Result list should have FALSE value when input list is empty');

    }
}