/**
* @description BoxUserIdCreationHandler class for updating Box user IDs from Box for Salesforce Users.
* It fetches Box users via API, maps their email to Box User IDs, and updates Salesforce User records accordingly.
*/
public class BoxUserIdCreationHandler {
    /**
* @description Fetches Box users, maps their email to Salesforce Users, and updates the Box_User_Id__c field.
*/
    public static void updateBoxFileIdForUsers(){
        Integer offSet = 0, fetchingLimit = 1000; Boolean moreUsers = true;
        //List to update users
        Set<User> usersToUpdate = new Set<User>();
        while(moreUsers){
            String responseBody = BoxCustomAPIRequest.getBoxUsers(offSet,fetchingLimit);
            System.debug('Response :'+responseBody);
            if(String.isEmpty(responseBody) || responseBody == ''){
                break;
            }
            //mailId as key, Box user Id as value
            Map<String,String> mailUserIdMap = new Map<String,String>();
            // Parse API response
            Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(responseBody);
            if(responseMap == null || responseMap.isEmpty()){
                break;
            }
            // Extract user entries
            List<Object> entries = (List<Object>)responseMap.get('entries');
            //extract total count
            Integer totalCount = responseMap.containsKey('total_count') ? Integer.valueOf(responseMap.get('total_count')) : 0;
            //extract limit
            fetchingLimit = responseMap.containsKey('limit') ? Integer.valueOf(responseMap.get('limit')) : 0;
            // Extract Box user IDs and map to emails
            for(Object entry: entries){
                Map<String,Object> entryMap = (Map<String,Object>)entry;
                String emailId = entryMap.containsKey('login') ? ((String) entryMap.get('login')).toLowerCase() : '';
                String boxUserId = entryMap.containsKey('id') ? (String) entryMap.get('id') : '';
                if(emailId != null && emailId != ''){
                    mailUserIdMap.put(emailId,boxUserId);
                }
            }
            // Fetch corresponding Salesforce User records by email
            List<User> users = getUsersByEmail(mailUserIdMap.keySet());
            
            
            // Update Salesforce Users with Box User ID
            if(!users.isEmpty() && users != null){
                for(User usr:users){
                    String email = usr.Email.toLowerCase();
                    if(mailUserIdMap.containsKey(email)){
                        if (usr.Box_User_Id__c != mailUserIdMap.get(email)) { // Set it only if it is not set already
                        	usr.Box_User_Id__c = mailUserIdMap.get(email);
                        	usersToUpdate.add(usr);
                        }
                    }
                }
            }
            System.debug('Fetching limit :'+fetchingLimit);
            System.debug('OffSet :'+offSet);
            System.debug('total Count :'+totalCount);
            //dml update limit 10000
            if( totalCount < (offSet+fetchingLimit) || usersToUpdate.size() >= 10000 ){		//need to check for more than 10000 users update
                moreUsers = false;
            }
            else{ //if(usersToUpdate.size() < 10000 && totalCount == fetchingLimit){       //max limit of users list is 1000 per call as per documentation
                System.debug('Making another call to get users list :');            //if we got 1000 users in first api call, then we need to make second api call to get next 1000 users
                offSet += fetchingLimit;                                                //dml update limit is 10000 per transaction in salesforce
            } 
            System.debug('More Users :'+moreUsers);
        }
        if(!usersToUpdate.isEmpty()){
            try{
                List<User> updateUsers = new List<User>(usersToUpdate);
                update updateUsers;
            }
            catch(DMLException e){
                throw new DMLException(e.getMessage());
            }
        }
        
    }
    
    /**
* @description Retrieves Salesforce Users by their email addresses.
* @param emailList Set of email addresses to look up.
* @return List of User records matching the provided emails.
*/
    @TestVisible
    private static List<User> getUsersByEmail(Set<String> emailList){
        System.debug('Email List :'+emailList);
        return [ SELECT Id,Email,Box_User_Id__c FROM User WHERE Email IN :emailList AND Box_User_Id__c = NULL ];
    }
}