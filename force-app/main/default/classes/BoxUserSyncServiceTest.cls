@IsTest
public class BoxUserSyncServiceTest {
	@testSetUp
    static void testData(){
        User usr = TestFactoryUser.makeUser('BBSI','TEST USER','System Administrator','910', 'bbsitest@gmail.com','bbsitest@gmail.com');
		insert usr;
    }
    
    @IsTest
    public static void test_getBoxUserId(){
        
        User usr = [ SELECT Id,Email FROM User WHERE Email = 'bbsitest@gmail.com' ];
        
        //create mock response
        String jsonString = '{'+
            	'"entries": ['+
            	'{'+
            		'"type": "user",'+
            		'"id": "987654321",'+
            		'"name": "BBSI TEST USER"'+
            	'}'+
            ']'+
         '}';
        Integer statusCode = 200;
        String status = 'OK';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(jsonString,status,statusCode));
        
        System.runAs(usr){
            //call method
            Test.startTest();
            List<String> boxUserIds = BoxUserSyncService.getBoxUserId();
            Test.stopTest();
            
            //Assertions
        	Assert.isTrue(boxUserIds.size() > 0, 'We should get One BoxUserId');
            Assert.areEqual('987654321',boxUserIds[0], 'UserIds should match');
        }
        
        
    }
    
    @IsTest
    public static void test_getBoxUserId_nullResponse(){
        User usr = [ SELECT Id,Email FROM User WHERE Email = 'bbsitest@gmail.com' ];
        
        //create mock response
        String jsonString = '{'+
            	'"total_count":0,'+
            	'"entries": ['+
            ']'+
         '}';
        Integer statusCode = 200;
        String status = 'OK';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(jsonString,status,statusCode));
        
        System.runAs(usr){
            //call method
            Test.startTest();
            List<String> boxUserIds = BoxUserSyncService.getBoxUserId();
            Test.stopTest();
			
			System.debug('size :'+boxUserIds);            
            //Assertions
        	Assert.AreEqual(0, boxUserIds.size(), 'UserIds should be null');
            //Assert.areEqual('987654321',boxUserIds[0], '');
        }
    }
}