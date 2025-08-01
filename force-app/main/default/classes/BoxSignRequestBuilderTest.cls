@IsTest
public class BoxSignRequestBuilderTest {
    @isTest
    static void testBuildRequestBody() {
        // Prepare Signer list
        BoxSignRequestBuilder.Signer signer1 = new BoxSignRequestBuilder.Signer();
        signer1.role = 'Approver';
        signer1.email = 'approver@example.com';
        signer1.order = 1;
        
        BoxSignRequestBuilder.Signer signer2 = new BoxSignRequestBuilder.Signer();
        signer2.role = 'Signer';
        signer2.email = 'signer@example.com';
        signer2.order = 2;
        
        List<BoxSignRequestBuilder.Signer> signers = new List<BoxSignRequestBuilder.Signer>{ signer1, signer2 };
            
            // Prepare Source Files
            BoxSignRequestBuilder.SourceFile file1 = new BoxSignRequestBuilder.SourceFile();
        file1.type = 'file';
        file1.id = '12345';
        
        List<BoxSignRequestBuilder.SourceFile> sourceFiles = new List<BoxSignRequestBuilder.SourceFile>{ file1 };
            
            // Prepare Parent Folder
            BoxSignRequestBuilder.ParentFolder folder = new BoxSignRequestBuilder.ParentFolder();
        folder.type = 'folder';
        folder.id = 'folder_abc';
        
        // Prepare Prefill Tags
        BoxSignRequestBuilder.PrefillTags tag1 = new BoxSignRequestBuilder.PrefillTags();
        tag1.document_tag_id = 'tag_1';
        tag1.text_value = 'Value 1';
        
        List<BoxSignRequestBuilder.PrefillTags> tags = new List<BoxSignRequestBuilder.PrefillTags>{ tag1 };
            
            // Build SignRequest
            BoxSignRequestBuilder.SignRequest request = new BoxSignRequestBuilder.SignRequest();
        request.signers = signers;
        request.source_files = sourceFiles;
        request.parent_folder = folder;
        request.prefill_tags = tags;
        request.is_document_preparation_needed = true;
        
        // Serialize to JSON
        String jsonBody = BoxSignRequestBuilder.buildRequestBody(request);
        
        System.assertNotEquals(null, jsonBody, 'Serialized JSON should not be null');
        System.assert(jsonBody.contains('"email":"approver@example.com"'), 'JSON should contain signer email');
        System.assert(jsonBody.contains('"type":"file"'), 'JSON should contain source file type');
        System.assert(jsonBody.contains('"id":"folder_abc"'), 'JSON should contain folder id');
        System.assert(jsonBody.contains('"document_tag_id":"tag_1"'), 'JSON should contain tag ID');
        System.assert(jsonBody.contains('"is_document_preparation_needed":true'), 'JSON should include document preparation flag');
    }
}