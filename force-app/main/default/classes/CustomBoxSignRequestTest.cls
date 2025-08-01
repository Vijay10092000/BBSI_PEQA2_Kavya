@IsTest
public class CustomBoxSignRequestTest {
    @testSetup
    static void testSetup(){
        //create account
        Account acc = TestFactoryAccount.createAccount('BBSI TEST ACCOUNT','Client');
        //create opportunity
        Opportunity  opp = TestFactoryOpportunity.createClient('BBSI TEST OPP', acc.Id, System.today(), 'Prospecting' );
        
        //create an Document
        Document__c doc = TestFactoryDocument.createDocument_SupportDocumentRecordType('BBSI TEST DOCUMENT','NEW', 'PEO', 'ALL STATES', false);
        doc.Box_Template_Id_1__c = 'TemplatefileId1';
        insert doc;
        
        //create Opportunity Document__c
        Opportunity_Document__c oppDoc1 = TestFactoryOpportunity_Document.createOpportunityDocument(opp.Id, doc.Id, false);
        
        //Opportunity_Document__c oppDoc2 =  TestFactoryOpportunity_Document.createOpportunityDocument(opp.Id, doc.Id, false);
        
        insert new List<Opportunity_Document__c>{oppDoc1};
    }
    
    @IsTest
    public static void test_makeSignRequest(){
        Opportunity opp = [ SELECT Id,Name FROM Opportunity WHERE Name = 'BBSI TEST OPP' LIMIT 1];
        
        //fetch Opportunity_Document
        Opportunity_Document__c oppDoc = [ SELECT Id,Document_Name__c,Document__r.Box_Template_Id_1__c FROM Opportunity_Document__c WHERE Opportunity__c = :opp.Id LIMIT 1 ];
        
        //signers
        box.Signer signer = new box.Signer();
        signer.email = 'test@mail.com';
        signer.order = 1;
        signer.level = 'signer';
        List<box.Signer> signers = new List<box.Signer>{signer};
       	
        //fileids
        List<String> fileIds = new List<String>{oppDoc.Document__r.Box_Template_Id_1__c};
        
        //oppDocs
        List<Opportunity_Document__c> oppDocs = new List<Opportunity_Document__c>{oppDoc};
        
        //set the response
        BoxSignResponseBuilder.SourceFile sourceFile = new BoxSignResponseBuilder.SourceFile();
        sourceFile.id = 'TemplatefileId1';
        sourceFile.type='file';
        //sign files
        BoxSignResponseBuilder.SignFiles signFile = new BoxSignResponseBuilder.SignFiles();
        BoxSignResponseBuilder.SignFile sFile = new BoxSignResponseBuilder.SignFile();
        sFile.id='SignTemplatefileId1';
        sFile.type = 'file';
        signFile.files = new List<BoxSignResponseBuilder.SignFile>{sFile};
        
        //response body
        BoxSignResponseBuilder res = new BoxSignResponseBuilder();
        res.id = 'Testing-uuid';
        res.prepare_url='https://prepare_url.com';
        res.source_files = new List<BoxSignResponseBuilder.SourceFile>{sourceFile};
        res.sign_files = signFile ;
        
        //create mock response
        String jsonString = JSON.serialize(res);
        String requestBody = jsonString;
        Integer statusCode = 200;
        String status = 'OK';
        // Set up a mock response
        Test.setMock(HttpCalloutMock.class, new BoxMockHttpResponseGenerator(requestBody,status,statusCode));
        
        //create request params
        BoxSignRequestParams reqParam = new BoxSignRequestParams();
        reqParam.boxUserId='123456';
        reqParam.effectiveDate = '2025-05-9';
        reqParam.Signers = signers;
        reqParam.fileIds = fileIds;
        reqParam.oppDocs = oppDocs;
        reqparam.oppId = opp.Id;
        reqParam.parentFolder = 'Folder12345';
        
        Test.startTest();
        List<CustomBoxSignRequest.ResultParams> results = CustomBoxSignRequest.makeSignRequest(new List<BoxSignRequestParams>{reqParam});
        Test.stopTest();
        
        //Assertions
        Assert.isTrue(results.size() >0,'Result should not br null');
        Assert.isNotNull(results[0].prepareUrl, 'Prepare Url Should not be null');
        Assert.areEqual(res.prepare_url,results[0].prepareUrl, 'Both prepare Url should be Same');
        Assert.isNotNull(results[0].oppDocs, 'One Opportunity Document Should be updated');
        Assert.areEqual(sFile.id,results[0].oppDocs[0].Box_File_Id__c, 'Box file Id should be same');
        Assert.areEqual(res.id, results[0].oppDocs[0].Box_Sign_UUID__c, 'BoxSign UUID should be same' );
    }
    
    @IsTest
    public static void test_AssignSignersAndFilesAndFolder(){
        box.Signer signer1 = new box.Signer();
        signer1.email = 'test1@mail.com';
        signer1.order = 1;
        signer1.level = 'signer';
        
        box.Signer signer2 = new box.Signer();
        signer2.email = 'test2@mail.com';
        signer2.order = 2;
        signer2.level = 'signer';
        List<box.Signer> assignSigners = new List<box.Signer>{signer1, signer2};
        List<String> fileIds = new List<String>{'file1', 'file2'};
        String folderId = 'folder1';

        Test.startTest();
        List<BoxSignRequestBuilder.Signer> signers = CustomBoxSignRequest.assignSigners(assignSigners);
        List<BoxSignRequestBuilder.SourceFile> files = CustomBoxSignRequest.assignSourceFiles(fileIds);
        BoxSignRequestBuilder.ParentFolder folder = CustomBoxSignRequest.assignParentFolder(folderId);
        Test.stopTest();

        System.assertEquals(2, signers.size());
        System.assertEquals(2, files.size());
        System.assertEquals('folder1', folder.id);
    }
    
    @IsTest
    public static void test_updateSignFileIds(){
        Opportunity_Document__c oppDoc = [SELECT Id, Document__c FROM Opportunity_Document__c LIMIT 1];
        Document__c doc = [SELECT Id, Box_Template_Id_1__c FROM Document__c WHERE Id = :oppDoc.Document__c];

        List<BoxSignResponseBuilder.SourceFile> sourceFiles = new List<BoxSignResponseBuilder.SourceFile>();
        BoxSignResponseBuilder.SourceFile sourceFile = new BoxSignResponseBuilder.SourceFile();
        sourceFile.id = doc.Box_Template_Id_1__c;
        sourceFiles.add(sourceFile);
        
        List<BoxSignResponseBuilder.SignFile> signFiles = new List<BoxSignResponseBuilder.SignFile>();
        BoxSignResponseBuilder.SignFile signFile = new BoxSignResponseBuilder.SignFile();
        signFile.id = 'signed_file_1';
        signFiles.add(signFile);

        List<Opportunity_Document__c> updatedDocs = CustomBoxSignRequest.updateSignFileIds(
            new List<Opportunity_Document__c>{oppDoc},
            sourceFiles,
            signFiles,
            'uuid-123'
        );

        System.assertEquals(1, updatedDocs.size());
        System.assertEquals('signed_file_1', updatedDocs[0].Box_File_Id__c);
        System.assertEquals('uuid-123', updatedDocs[0].Box_Sign_UUID__c);
    }
    
    @IsTest
    public static void test_getOpportunityValues_Exception(){
        Set<String> fields = new Set<String>{'Name', 'Account.Name', 'Account.Industry'};
            
        try{
            Test.startTest();
            CustomBoxSignRequest.getOpportunityValues(fields, '006XXXXXXXXXXXX');
            Test.stopTest();
        }catch(QueryException e){
            System.assert(e.getMessage().contains('List has no rows for assignment to SObject'));
        }
    }
    
    @IsTest
    public static void test_getDocumentsByIds_Exception(){
        List<String> docIds = new List<String>{'a2WXXXXXXXXXXXX', 'a2WXXXXXXXXXXXX'};
        
        try{
          Test.startTest();
          CustomBoxSignRequest.getDocumentsByIds(docIds);
          Test.stopTest();
        }catch(Exception e){
          System.assert(e.getMessage().contains('Invalid id: a2WXXXXXXXXXXXX'));
        }    
    }
}