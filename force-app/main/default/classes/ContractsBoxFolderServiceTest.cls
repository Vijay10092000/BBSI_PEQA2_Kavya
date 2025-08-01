@IsTest
public class ContractsBoxFolderServiceTest {
	@testSetup
    public static void makeData(){
        Box_Contracts_Folder__c contractsFolder = new Box_Contracts_Folder__c(FolderId__c='1234567890',Folder_Name__c='Contracts');
        insert contractsFolder;
    }
    
	@IsTest
    public static void test_execute_newFolder(){
		
        Test.startTest();	
        String responseBody = '{'+
            '"name":"BBSITESTDOC.pdf"'+
            '}';
        setMock(responseBody);
        //insert branch account
        Account acc1 = TestFactoryAccount.createBranch('BBSI TEST ACCOUNT 1');
		//insert related account
        Account acc2 = TestFactoryAccount.makeAccount('BBSI TEST ACCOUNT 2', 'Client');
        acc2.Prospect_Branch__c = acc1.Id;
        insert acc2;
        Test.stopTest();
          
    }
	
    @IsTest
    private static void test_execute_udpateClientIdWithEmptyContractsFolderId(){

        Test.startTest();	
        String responseBody = '{'+
            '"name":"BBSITESTDOC.pdf"'+
            '}';
        setMock(responseBody);
        //insert account        
        Account acc1 = TestFactoryAccount.makeBranch('BBSI TEST ACCOUNT 1');
        insert acc1;
        
        //udpate client Id
        acc1.External_ID__c = '7654321';
        update acc1; 
        Test.stopTest();
        
        // Assert folder ID was updated
        Account updatedAccounts = [SELECT External_ID__c,Contracts_Accounts_SubFolder_Id__c FROM Account WHERE Id = :acc1.Id LIMIT 1];
		System.assertEquals('7654321', updatedAccounts.External_ID__c, 'External_ID__c should be updated');

    }
    
    @IsTest
    private static void test_execute_udpateClientIdWithContractsFolderId(){

        Test.startTest();	
        String responseBody = '{'+
            '"name":"BBSITESTDOC.pdf"'+
            '}';
        setMock(responseBody);
        //insert account        
        Account acc1 = TestFactoryAccount.makeBranch('BBSI TEST ACCOUNT 1');
        acc1.Contracts_Accounts_SubFolder_Id__c = '12345';
        insert acc1;
        
        //udpate client Id
        acc1.External_ID__c = '7654321';
        update acc1; 
        Test.stopTest();
        
        // Assert folder ID was updated
        Account updatedAccounts = [SELECT External_ID__c,Contracts_Accounts_SubFolder_Id__c FROM Account WHERE Id = :acc1.Id LIMIT 1];
		System.assertEquals('7654321', updatedAccounts.External_ID__c, 'External_ID__c should be updated');

    }
    
    @IsTest
    private static void test_execute_EmptyContractsFolder(){
        Test.startTest();
        String responseBody = '{'+
            	'"shared_link":{'+
            		'"url":"https://bbsisandbox.app.box.com/s/f2ld5kg402tf0xim3que"'+
            	'}'+
            '}';
        setMock(responseBody);
        //create account
        Account acc1 = TestFactoryAccount.makeBranch('BBSI TEST ACCOUNT 1');
        //insert account
        insert acc1;
        //create opportunity
        Opportunity opp1 = TestFactoryOpportunity.createClient('BBSI Test Opportunity', acc1.Id, System.today(), 'Proposal');
        //create frup
        box__FRUP__c frup = new box__FRUP__c();
        frup.box__Record_ID__c = opp1.Id;
        frup.box__Object_Name__c = 'Opportunity';
        frup.box__Folder_ID__c = '12345678';
        insert frup;
        /*
        //udpate account
        acc1.Contracts_Accounts_SubFolder_Id__c = '0987654321';
        update acc1;
        */
        Test.stopTest();
    }
    
    @IsTest
    private static void test_execute_UpdateContractsFolder(){
        Test.startTest();
        String responseBody = '{'+
            	'"shared_link":{'+
            		'"url":"https://bbsisandbox.app.box.com/s/f2ld5kg402tf0xim3que"'+
            	'}'+
            '}';
        setMock(responseBody);
        //create account
        Account acc1 = TestFactoryAccount.makeBranch('BBSI TEST ACCOUNT 1');
        //insert account
        insert acc1;
        //create opportunity
        Opportunity opp1 = TestFactoryOpportunity.createClient('BBSI Test Opportunity', acc1.Id, System.today(), 'Proposal');
        //create frup
        box__FRUP__c frup = new box__FRUP__c();
        frup.box__Record_ID__c = opp1.Id;
        frup.box__Object_Name__c = 'Opportunity';
        frup.box__Folder_ID__c = '12345678';
        insert frup;
        
        //udpate account
        acc1.Contracts_Accounts_SubFolder_Id__c = '0987654321';
        update acc1;
        
        Test.stopTest();
    }
    
    private static void setMock(String responseBody){
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(responseBody,'OK',200));
    }
}