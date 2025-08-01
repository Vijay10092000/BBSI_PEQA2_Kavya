/**
 * @description SpotioPlatformEvents_Account handles the Account specific functionality for Spotio Platform Events.
 */
public without sharing class SpotioPlatformEvents_Account extends SpotioPlatformEvents {
	// List of Acount Customer Classes which can send a Platform Events.
	/* QUESTION: Is this list needed?
	private List<String> customerClasses = new List<String>{
		'1',    // Lead (no incentive) 
		'2',    // Lead (incentive)
		'10'    // No Comp
	};
	*/
	
	/**
	 * @description setContactSpotioIdsFromAccount sends Plastform Events for related Contacts without a Spotio Id
	 * when an Account has its Spotio Id initially set.
	 * @param  oldAccounts  Accounts before change
	 * @param  newAccounts  Accounts with change
	 */
	public static void setContactSpotioIdsFromAccount(Map<Id, Account> oldAccounts, List<Account> newAccounts) {
		Set<Id> updateContacts = determineContactsNeedSpotioId(oldAccounts, newAccounts);

		if (!updateContacts.isEmpty()) {
			SpotioPlatformEvents speContact = new SpotioPlatformEvents('Contact');

			for (id idContact : updateContacts) {
				speContact.addEvent(idContact, ActionType.CREATED);
			}

			speContact.publish();
		}
	}
	
	/**
	 * @description determineContactsNeedSpotioId
	 * @param  oldAccounts  Accounts before change
	 * @param  newAccounts  Accounts with change
	 * @return Set<Contact>
	 */
	@TestVisible
	private static Set<Id> determineContactsNeedSpotioId(Map<Id, Account> oldAccounts, List<Account> newAccounts) {
		Set<Id> changedAccountSpotioId = new Set<Id>();

		for (Account account : newAccounts) {
			if (account.Spotio_Id__c != null) {
				if (oldAccounts.get(account.Id).Spotio_Id__c == null) {
					changedAccountSpotioId.add(account.Id);
				}
			}
		}

		if (!changedAccountSpotioId.isEmpty()) {
			Map<Id, Contact> contacts = new Map<Id, Contact>([
				SELECT Id
				FROM Contact
				WHERE AccountId IN :changedAccountSpotioId
				AND Spotio_Id__c = NULL
			]);

			return contacts.keySet();
		}

		return new Set<Id>();
	}

	/**
	 * @description SpotioPlatformEvents_Account constructor
	 */
	public SpotioPlatformEvents_Account() {
		super('Account');
	}

	/**
	 * @description processRecord determines the Platform Event to send.
	 * @param  oldSObject  SObject before changes
	 * @param  newSObject  SObject with changes
	 */
	@TestVisible
	protected override void processRecord(SObject oldSObject, SObject newSObject) {
		String id = (String) newSObject.get('Id');
		String spotioId = (String) newSObject.get('Spotio_Id__c');
		String customerClass = (String) newSObject.get('Customer_Class__c');
		String recordTypeId = (String) newSObject.get('RecordTypeId');

		// QUESTION: How is this suppose to work?  Do I need to check for RecordType before Customer Class?
		//	if (!customerClasses.contains(customerClass)) {
		//		return;
		//	}

		if (oldSObject == null) {
			if (spotioId == null) {          
				addEvent(Id, ActionType.CREATED);
				textDebug += ' - CREATED in Salesforce';     
			} else {
				// Account is being created by Boomi/Spotio
				addEvent(Id, ActionType.UPDATED);
				textDebug += ' - CREATED by Boomi/Spotio';
			}
		} else {          
			if (spotioId == null) {
				String oldCustomerClass = (String) oldSObject.get('Customer_Class__c');
				String oldRecordTypeId = (String) oldSObject.get('RecordTypeId');

				// WARNING: If these tests are removed, then the Platform Events for new Accounts will
				// be fired twice because on create Accounts run triggers create and update.
				if (oldRecordTypeId != recordTypeId || 
					oldCustomerClass != customerClass) {
					addEvent(Id, ActionType.CREATED);
					textDebug += ' - CREATED because of RecordType and/or Customer Class change';   
				}
			} else {
				if (blockedUsers.contains(UserInfo.getName())) {
					if (overrideBlockedUsers(oldSObject, newSObject)) {
						addEvent(id, ActionType.UPDATED);
						textDebug += ' - UPDATED because of field change (Override Blocked Users)';
					} else {
						textDebug += ' - No Platform Event needed (Modified by blocked user ' + UserInfo.getName() + ')';
					}
				} else if (hasUpdatedField(oldSObject, newSObject)) {
					addEvent(Id, ActionType.UPDATED);
					textDebug += ' - UPDATED because of field change';
				} else {
					textDebug += ' - No Platform Event needed';
				}
			}
		}
	}
}