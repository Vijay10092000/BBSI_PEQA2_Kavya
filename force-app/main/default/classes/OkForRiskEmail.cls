/**
 * @description OkForRiskEmail - OK for Risk was changed to Underwriting
 */
public class OkForRiskEmail {
	private static final String EMAIL_SUBJECT_FORMAT = 'Underwriting Approval in Salesforce: {0}';

	private static final String EMAIL_BODY_FORMAT =
		'<style> p \'{color:#134597;}\' h4 \'{color:#134597;}\' hr \'{color:#6E95D6;}\' </style>' +
		'<hr/><h4><em>BBSI: Salesforce Automated Email </em></h4><hr/><br/>' +
		'<h4>***Approval Needed***</h4><p>' +
		'{0} has requested a record to be approved for Underwriting in Salesforce.</br>' +
		'<a href="http://bbsi.my.salesforce.com/{1}">Salesforce Link</a>' +
		'</p><font size="2"><hr/><p>This is an automated message from Salesforce</p></font>';

	/**
	 * @description riskEmail description
	 * @param  idRecord   Opporutnity Identifiers
	 * @param  requester  User making the request
	 */
	public static void riskEmail(Set<Id> idRecords, String requestor) {
		List<Opportunity> listOpportunities = [SELECT Id, Name FROM Opportunity WHERE Id IN :idRecords];

		riskEmail(listOpportunities, requestor);
	}

	/**
	 * @description riskEmail description
	 * @param  opps       List of Opporutnities
	 * @param  requester  User making the request
	 */
	public static void riskEmail(List<Opportunity> opps, String requestor) {
		Set<String> riskApproval = new Set<String>();
		for (Ok_For_Risk_Access__c approver : Ok_For_Risk_Access__c.getall().values()) {
			riskApproval.add(approver.Name);
		}

		List<String> toAddresses = new List<String>();
		for (User user : [SELECT Email FROM User WHERE Name IN :riskApproval]) {
			toAddresses.add(user.Email);
		}

		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

		for (Opportunity opp : opps) {
			emails.add(
				Email_Service.buildHtmlEmail(
					toAddresses,
					null,
					String.format(EMAIL_SUBJECT_FORMAT, new List<String>{ opp.Name }),
					String.format(EMAIL_BODY_FORMAT, new List<String>{ requestor, opp.Id })
				)
			);
		}

		Email_Service.send(emails);
	}
}