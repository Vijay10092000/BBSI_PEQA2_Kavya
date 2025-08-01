@IsTest
public class BoxSignResponseBuilderTest {
    @isTest
    static void testBoxSignResponseBuilderSerialization() {
        // Create FileVersion
        BoxSignResponseBuilder.FileVersion version = new BoxSignResponseBuilder.FileVersion();
        version.id = 'fv1';
        version.type = 'file_version';
        version.sha1 = 'abc123';
        
        // Create SignFile
        BoxSignResponseBuilder.SignFile signFile = new BoxSignResponseBuilder.SignFile();
        signFile.id = 'sf1';
        signFile.etag = 'etag1';
        signFile.type = 'file';
        signFile.sequence_id = 'seq1';
        signFile.name = 'SignedFile.pdf';
        signFile.sha1 = 'sha123';
        signFile.file_version = version;
        
        // Create SignFiles
        BoxSignResponseBuilder.SignFiles signFiles = new BoxSignResponseBuilder.SignFiles();
        signFiles.files = new List<BoxSignResponseBuilder.SignFile>{ signFile };
            signFiles.is_ready_for_download = true;
        
        // Create ParentFolder
        BoxSignResponseBuilder.ParentFolder folder = new BoxSignResponseBuilder.ParentFolder();
        folder.id = 'fld1';
        folder.etag = 'etagFolder';
        folder.type = 'folder';
        folder.sequence_id = 'seqF';
        folder.name = 'Documents';
        
        // Create SourceFile
        BoxSignResponseBuilder.SourceFile srcFile = new BoxSignResponseBuilder.SourceFile();
        srcFile.id = 'file1';
        srcFile.etag = 'etagFile';
        srcFile.type = 'file';
        srcFile.sequence_id = 'seqSrc';
        srcFile.name = 'Doc1.pdf';
        srcFile.sha1 = 'sha456';
        srcFile.file_version = version;
        
        // Create PrefillTag
        BoxSignResponseBuilder.PrefillTag tag = new BoxSignResponseBuilder.PrefillTag();
        tag.document_tag_id = 'tag_123';
        tag.text_value = 'Prefilled Text';
        tag.checkbox_value = true;
        tag.date_value = '2025-05-08';
        
        // Create Signer
        BoxSignResponseBuilder.Signer signer = new BoxSignResponseBuilder.Signer();
        signer.email = 'user@example.com';
        signer.role = 'Signer';
        signer.is_in_person = false;
        signer.order = 1;
        signer.verification_phone_number = '1234567890';
        signer.embed_url_external_user_id = 'ext_user_1';
        signer.redirect_url = 'https://redirect.com';
        signer.declined_redirect_url = 'https://declined.com';
        signer.login_required = true;
        signer.has_viewed_document = true;
        signer.signer_decision = 'signed';
        signer.signer_group_id = 'grp1';
        signer.inputs = new List<Object>{};
            signer.embed_url = 'https://embed.com';
        signer.iframeable_embed_url = 'https://iframe.com';
        signer.suppress_notifications = false;
        signer.smart_card_required_type = 'none';
        
        // Create main response object
        BoxSignResponseBuilder response = new BoxSignResponseBuilder();
        response.is_document_preparation_needed = true;
        response.redirect_url = 'https://signredirect.com';
        response.declined_redirect_url = 'https://declineredirect.com';
        response.are_text_signatures_enabled = true;
        response.signature_color = 'blue';
        response.email_subject = 'Sign this Document';
        response.email_message = 'Please sign it.';
        response.are_reminders_enabled = true;
        response.signers = new List<BoxSignResponseBuilder.Signer>{ signer };
            response.id = 'resp123';
        response.prefill_tags = new List<BoxSignResponseBuilder.PrefillTag>{ tag };
            response.days_valid = 7;
        response.prepare_url = 'https://prepare.com';
        response.source_files = new List<BoxSignResponseBuilder.SourceFile>{ srcFile };
            response.parent_folder = folder;
        response.name = 'Test Sign Request';
        response.external_id = 'ext123';
        response.type = 'sign-request';
        response.signing_log = 'log123';
        response.status = 'sent';
        response.sign_files = signFiles;
        response.auto_expire_at = '2025-06-01T00:00:00Z';
        response.template_id = 'tmpl123';
        response.external_system_name = 'Salesforce';
        response.collaborator_level = 'editor';
        response.sender_email = 'sender@example.com';
        response.sender_id = 'usr789';
        response.batch_send_id = 'batch001';
        
        // Test serialization
        String json = JSON.serialize(response);
        System.assertNotEquals(null, json, 'Serialized JSON should not be null');
        System.assert(json.contains('user@example.com'), 'JSON should contain signer email');
        System.assert(json.contains('Test Sign Request'), 'JSON should contain name');
        System.assert(json.contains('Salesforce'), 'JSON should contain external system name');
        
        /*
        // Test deserialization
        BoxSignResponseBuilder deserializedRes = (BoxSignResponseBuilder)JSON.deserialize(json,BoxSignResponseBuilder.class);
        System.assertEquals('resp123', deserializedRes.id, 'Deserialized ID should match original');
        System.assertEquals('Test Sign Request', deserializedRes.name, 'Deserialized name should match original');
		*/
    }
}