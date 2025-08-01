/**
 * @description Represents the display configuration and metadata settings used for the Box Sign UI.
 * This class is typically used to store and transfer information needed to dynamically fetch
 * the BoxSignSignDisplaySetting_mdt component configuration, prefilled values, and template selections.
 */
public with sharing class BoxSignDisplaySettingMdtBuilder {
    public Boolean senderNeedsSign;
    public Boolean showFromEmail;
    public Boolean showSignerPassword;
    public Boolean showSignerPhonenumber;
    public Boolean showEmailTemplate;
    public String landingPageSuccess;
    public String landingPageDeclined;
    public Boolean showLandingPageDeclined;
    public Boolean showLandingPageSucces;
    public Boolean showEmailSettings;
    public List<ContactField> contactFields;
    public List<TemplateData> templateData;
    public List<SignerData> signerData;
    public List<PrefillData> prefillData;
    public Boolean showAutoReminder;
    public Boolean setAutoReminder;
    public Boolean showEmailSubject;
    public Boolean showEmailBody;
    
    /**
     * @description Placeholder class for future use of contact-specific fields in the UI.
     */
    public class ContactField {
        // Define properties if contact fields are expected to contain data in the future
    }
    
    /**
     * @description Represents a document template with its label and URL.
     */
    public class TemplateData {
        public String label;
        public String url;
        //public Integer number;
    }
    
    /**
     * @description Represents signer-specific data, such as email, order, and role level.
     */
    public class SignerData {
        public Boolean isSender;
        public String prefilledSignerEmail;
        public String prefilledSignerLevel;
        public String prefilledSignerOrder;
        //public Integer number;
    }
    
     /**
     * @description Represents data used to prefill tags within a document.
     */
    public class PrefillData {
        public String externalId;
        public String prefilledTagType;
        public String prefilledTagTypeValue;
        public String prefillTagExternalValue;
        //public Integer number;
    }
}