@IsTest
public class BoxSignDisplaySettingMdtBuilderTest {
	@isTest
    static void testBuilderInstantiation() {
        // Instantiate nested classes
        BoxSignDisplaySettingMdtBuilder.TemplateData templateData = new BoxSignDisplaySettingMdtBuilder.TemplateData();
        templateData.label = 'Test Template';
        templateData.url = 'https://example.com/template';

        BoxSignDisplaySettingMdtBuilder.SignerData signerData = new BoxSignDisplaySettingMdtBuilder.SignerData();
        signerData.isSender = true;
        signerData.prefilledSignerEmail = 'signer@example.com';
        signerData.prefilledSignerLevel = 'Viewer';
        signerData.prefilledSignerOrder = '1';

        BoxSignDisplaySettingMdtBuilder.PrefillData prefillData = new BoxSignDisplaySettingMdtBuilder.PrefillData();
        prefillData.externalId = 'tag1';
        prefillData.prefilledTagType = 'Text';
        prefillData.prefilledTagTypeValue = 'Agreement';
        prefillData.prefillTagExternalValue = 'Yes';

        // Instantiate the main class and set values
        BoxSignDisplaySettingMdtBuilder settings = new BoxSignDisplaySettingMdtBuilder();
        settings.senderNeedsSign = true;
        settings.showFromEmail = true;
        settings.showSignerPassword = false;
        settings.showSignerPhonenumber = true;
        settings.showEmailTemplate = true;
        settings.landingPageSuccess = 'https://example.com/success';
        settings.landingPageDeclined = 'https://example.com/declined';
        settings.showLandingPageDeclined = true;
        settings.showLandingPageSucces = true;
        settings.showEmailSettings = true;
        settings.contactFields = new List<BoxSignDisplaySettingMdtBuilder.ContactField>(); // no fields, empty list
        settings.templateData = new List<BoxSignDisplaySettingMdtBuilder.TemplateData>{ templateData };
        settings.signerData = new List<BoxSignDisplaySettingMdtBuilder.SignerData>{ signerData };
        settings.prefillData = new List<BoxSignDisplaySettingMdtBuilder.PrefillData>{ prefillData };
        settings.showAutoReminder = true;
        settings.setAutoReminder = true;
        settings.showEmailSubject = true;
        settings.showEmailBody = true;

        System.assertEquals(true, settings.senderNeedsSign);
        System.assertEquals('https://example.com/success', settings.landingPageSuccess);
        System.assertEquals(1, settings.templateData.size());
        System.assertEquals('signer@example.com', settings.signerData[0].prefilledSignerEmail);
        System.assertEquals('Yes', settings.prefillData[0].prefillTagExternalValue);
    }
}