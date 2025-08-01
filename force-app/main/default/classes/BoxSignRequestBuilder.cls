/**
 * @description This class constructs the request body for a Box Sign API call.
 * It defines nested classes that represent the structure required by the Box Sign request,
 * such as signers, source files, parent folder, and prefill tags.
 *
 * The class also provides a utility method to serialize the full request into JSON format,
 * suitable for HTTP callouts to the Box Sign API.
 */
public with sharing class BoxSignRequestBuilder {
	
    /**
     * @description Represents a signer in the Box Sign request.
     * Includes signer role, email address, and signing order.
     */
    public class Signer{
        @AuraEnabled
        public String role;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public Integer order;
    }
    
    /**
     * @description Represents a source file in the Box Sign request.
     * Includes file type and file ID.
     */
    public class SourceFile{
        public String type;
        public String id;
    }
    
    /**
     * @description Represents the parent folder where the signed document will be stored.
     * Includes folder type and folder ID.
     */
    public class ParentFolder{
        public String type;
        public String id;
    }
    
    /**
     * @description Represents a prefill tag in the document that can be filled before sending for signature.
     * Includes the tag ID and the value to prefill.
     */
    public class PrefillTags{
        public String document_tag_id;
        public String text_value;
    }
    
    
    /**
     * @description Represents the complete Box Sign request body.
     * Contains signers, source files, destination folder, prefill tags, and preparation flag.
     */
    public class SignRequest{
        public List<Signer> signers;
        public List<SourceFile> source_files;
        public ParentFolder parent_folder;
        public List<PrefillTags> prefill_tags;
        public Boolean is_document_preparation_needed;
        public String email_subject;
        public String email_message;
        public Boolean are_reminders_enabled;
        public Integer days_valid;
    }
    
    /**
     * @description Serializes the SignRequest object into a JSON string for use in Box Sign API callouts.
     * @param req The SignRequest object representing the payload.
     * @return JSON string of the serialized request body.
     */
    public static string buildRequestBody(SignRequest req){
        return JSON.serialize(req);
    }
}