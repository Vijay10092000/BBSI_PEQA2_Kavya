/**
 * @description AreaManagerEmail class
 */
public without sharing class AreaManagerEmail {
	/**
	 * @description areaManagerApprovalEmail description
	 * @param  idRecords     Identifier of the record being approved
	 * @param  userName     Name of user requesting approval
	 * @param  branchNames  Set of Branch names to retrieve Branch Admin User
	 * @param  approvalType Type of approval: Lead, Prospect, Cancellation
	 */
	public static void areaManagerApprovalEmail(
		Set<Id> idRecords,
		String userName,
		Set<String> branchNames,
		String approvalType
	) {
		Map<Id, String> recordName = new Map<Id, String>();
		map<String, String> areaManagerEmail = new Map<String, String>();
		Set<String> branchManager = new Set<String>();

		List<String> toAddresses = new List<String>();

		Set<String> areaManagerApprovalSetting = new Set<String>();
		Set<String> users = new Set<String>();

		for (Opportunity o : [SELECT Name FROM Opportunity WHERE Id IN :idRecords]) {
			recordName.put(o.Id, o.Name);
		}

		for (Lead l : [SELECT Name FROM Lead WHERE Id IN :idRecords]) {
			recordName.put(l.Id, l.Name);
		}

		for (Account a : [SELECT Name FROM Account WHERE Id IN :idRecords]) {
			recordName.put(a.Id, a.Name);
		}

		for (Client_Cancellation__c c : [
			SELECT Client__r.Name, Client__r.Prospect_Branch__r.Branch_Manager__c
			FROM Client_Cancellation__c
			WHERE Id IN :idRecords
			LIMIT 1
		]) {
			recordName.put(c.Id, c.Client__r.Name);
			branchManager.add(c.Client__r.Prospect_Branch__r.Branch_Manager__c);
		}

		for (Admin_Branch__c a : [SELECT Admin_User__c FROM Admin_Branch__c WHERE Name IN :branchNames]) {
			areaManagerApprovalSetting.add(a.Admin_User__c);
		}

		for (Account a : [
			SELECT Prospect_Branch__r.Branch_Manager_Email__c
			FROM Account
			WHERE Id IN :idRecords
			LIMIT 1
		]) {
			toAddresses.add(a.Prospect_Branch__r.Branch_Manager_Email__c);
		}

		for (Lead l : [SELECT Branch__r.Branch_Manager_Email__c FROM Lead WHERE Id IN :idRecords LIMIT 1]) {
			toAddresses.add(l.Branch__r.Branch_Manager_Email__c);
		}

		for (String s : areaManagerApprovalSetting) {
			if (s.contains('\'')) {
				s = s.substring(0, s.indexOf('\'')) + '\'' + s.substring(s.indexOf('\''), s.length());
			}
		}

		for (User u : [SELECT Email FROM User WHERE Name IN :areaManagerApprovalSetting]) {
			toAddresses.add(u.email);
		}

		for (Id id : idRecords) {
			Email_Service.sendHtmlEmail(toAddresses, null, getSubject(approvalType, id), getBody(userName, id));
		}
	}

	/**
	 * @description getSubject determines the email's subject
	 * @param  type Type of the subject
	 * @param  id   Identifier added to subject
	 * @return      The email's subject
	 */
	@TestVisible
	private static String getSubject(String type, Id id) {
		String format = 'Area Manager Approval in Salesforce: {0}';

		if (type == 'Prospect') {
			format = '{0} - Prospect Approval in Salesforce';
		} else if (type == 'Lead') {
			format = '{0} - Lead Approval in Salesforce';
		} else if (type == 'Cancellation') {
			format = '{0} - Cancellation Approval in Salesforce';
		}

		return String.format(format, new List<String>{ String.valueof(id) });
	}

	@TestVisible
	private static String getBody(String username, Id id) {
		return
		'<style> p { color:#134597;} h4 { color:#134597;} hr { color:#6E95D6;} </style>' +
		'<hr/><h4><em>BBSI: Salesforce Automated Email </em></h4><hr/><br/>' +
		'<h4>***Approval Needed***</h4><p>' +
		username + ' has requested a record for Area Manager Approval in Salesforce. </br><a href="http://bbsi.my.salesforce.com/' + id + '">Salesforce Link</a>' +
		'</p><font size="2"><hr/><p>This is an automated message from Salesforce</p></font>';
	}
}