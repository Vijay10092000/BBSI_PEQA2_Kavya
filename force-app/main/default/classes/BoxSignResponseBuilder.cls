/**
 * @description Represents the structure of the response returned by the Box Sign API.
 * This class contains all possible fields included in a sign request response,
 * including signer details, document metadata, prefill tags, signing status, and configuration options.
 */
public with sharing class BoxSignResponseBuilder {
	public Boolean is_document_preparation_needed;
    public String redirect_url;
    public String declined_redirect_url;
    public Boolean are_text_signatures_enabled;
    public String signature_color;
    public String email_subject;
    public String email_message;
    public Boolean are_reminders_enabled;
    public List<Signer> signers;
    public String id;
    public List<PrefillTag> prefill_tags;
    public Integer days_valid;
    public String prepare_url;
    public List<SourceFile> source_files;
    public ParentFolder parent_folder;
    public String name;
    public String external_id;
    public String type;
    public String signing_log;
    public String status;
    public SignFiles sign_files;
    public String auto_expire_at;
    public String template_id;
    public String external_system_name;
    public String collaborator_level;
    public String sender_email;
    public String sender_id;
    public String batch_send_id;

    /**
     * @description Represents the signer details in the Box Sign response.
     * Includes contact info, signing order, URLs for redirection, 
     * and various flags related to verification, login, and notification preferences.
     */
    public class Signer {
        public String email;
        public String role;
        public Boolean is_in_person;
        public Integer order;
        public String verification_phone_number;
        public String embed_url_external_user_id;
        public String redirect_url;
        public String declined_redirect_url;
        public Boolean login_required;
        public Boolean has_viewed_document;
        public String signer_decision;
        public String signer_group_id;
        public List<Object> inputs;
        public String embed_url;
        public String iframeable_embed_url;
        public Boolean suppress_notifications;
        public String smart_card_required_type;
    }

    /**
     * @description Represents the prefill tags present in the document.
     * Can include text, checkbox, and date values prefilled before sending for signing.
     */
    public class PrefillTag {
        public String document_tag_id;
        public String text_value;
        public Boolean checkbox_value;
        public String date_value;
    }

    /**
     * @description Represents a file used as a source in the Box Sign response.
     * Includes metadata like file ID, name, sha1 hash, and version info.
     */
    public class SourceFile {
        public String id;
        public String etag;
        public String type;
        public String sequence_id;
        public String name;
        public String sha1;
        public FileVersion file_version;
    }

    /**
     * @description Represents the file version metadata such as version ID, type, and SHA1 hash.
     */
    public class FileVersion {
        public String id;
        public String type;
        public String sha1;
    }

    /**
     * @description Represents the folder where the signed document is stored.
     * Includes folder identification details and metadata.
     */
    public class ParentFolder {
        public String id;
        public String etag;
        public String type;
        public String sequence_id;
        public String name;
    }

    /**
     * @description Represents the container holding signed files and a readiness flag.
     */
    public class SignFiles {
        public List<SignFile> files;
        public Boolean is_ready_for_download;

    }
    
    /**
     * @description Represents a single signed file included in the `SignFiles` list.
     * Contains metadata like ID, name, and file version.
     */
    public class SignFile {
            public String id;
            public String etag;
            public String type;
            public String sequence_id;
            public String name;
            public String sha1;
            public FileVersion file_version;
    }
}