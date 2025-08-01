/**
 * @description SpotioPlatformEvents handles publishing Platform Events for Spotio.
 * It may be extended to handle specific objects.
 */
public virtual without sharing class SpotioPlatformEvents {
	/**
	 * Action type for the Platform Event
	 */
	public enum ActionType {
		NOT_SET,		// Action not yet determined
		INSERTING,		// Object is being inserted
		UPDATING,		// Object is being updated
		DELETING,		// Object is being deleted
		CREATED,		// Platform Event object created
		UPDATED,		// Platform Event object updated
		DELETED			// Platvorm Event object deleted
	}
	
	@TestVisible
	private Integer numberPublished = 0;

	/**
	 * @description accountRecordTypes lists the Record Types which can send a Platform Event for
	 * the object name.  
	 * If there is not a list for an object, then all Record Types are allowed for that object.
	 */
	private static final Map<String, List<String>> recordTypes = new Map<String, List<String>>{
		'Account' => new List<String>{ 
			'Prospect', 
			'Client', 
			'Terminated', 
			'Referral Partner' 
		},
		'Contact' => new List<String>{ 
			'Client Contact', 
			'Other', 
			'Producer'
		},
		'Lead' => new List<String>{ 
			'Client Lead', 
			'Referral Partner Lead'
		}
	};

	@TestVisible
	protected String nameObject;
	@TestVisible
	protected ActionType action = ActionType.NOT_SET;
	@TestVisible
	protected List<String> blockedUsers = new List<String>();
	@TestVisible
	protected List<String> checkFields = new List<String>();
	@TestVisible
	protected List<Id> idrtObject;		
	@TestVisible
	protected List<Spotio_Event__e> events = new List<Spotio_Event__e>();

	protected String textDebug = '';

	/**
	 * @description SpotioPlatformEventBase constructor
	 * @param  nameObject  Name of the object
	 */
	public SpotioPlatformEvents(String nameObject) {
		this.nameObject = nameObject.toLowerCase();

		readUpdateFields(nameObject);
		readBlockedUsers();

		if (recordTypes.containsKey(nameObject)) {
			idrtObject = RecordTypeService.getIds(nameObject, recordTypes.get(nameObject)).values();
		}
	}

	/**
	 * @description execute determines if the SObject should have a Platform Event published
	 * and publishes the event if necessary.
	 * @param  oldSObjects  Map of SObjects before changes
	 * @param  newSObjects  List of SObjects with changes
	 */
	public void execute(Map<Id, SObject> oldSObjects, List<SObject> newSObjects) {
		action = (oldSObjects == null) ? ActionType.INSERTING : ActionType.UPDATING;

		perform(oldSObjects, newSObjects);
	}

	/**
	 * @description remove determines if the SObject being deleted should have a Platform Event
	 * published and publishes the event if necessary.
	 * @param  sobjects  List of SObjects being deleted
	 */
	public void remove(List<SObject> sobjects) {
		action = ActionType.DELETING;

		perform(null, sobjects);
	}

	private void perform(Map<Id, SObject> oldSObjects, List<SObject> newSObjects) {
		List<SObject> needProcessing = preprocess(newSObjects);

		if (needProcessing.isEmpty()) {
			return;
		}

		process(oldSObjects, needProcessing);
		publish();

		if (String.isNotBlank(textDebug)) {
			System.debug(LoggingLevel.INFO, 'Spotio Platform Events - ' + nameObject + '  ' + action.name() + textDebug);
		}
	}

	/**
	 * @description preprocess handles any pre-processing needed for the SObjects.
	 * For now, it only filters out SObjects that do not have a given Record Type.
	 * @param  newSObjects  List of SObjects with changes
	 * @return List of SObjects to process
	 */
	@TestVisible
	protected virtual List<SObject> preprocess(List<SObject> newSObjects) {
		List<SObject> result = new List<SObject>();

		for (SObject newSObject : newSObjects) {
			if (idrtObject == null || idrtObject.contains((String) newSObject.get('RecordTypeId'))) {
				result.add(newSObject);
			}
		}

		return result;
	}

	/**
	 * @description process runs through the list of SObjects and determines if a Platform Event.
	 * @param  oldSObjects  Map of SObjects before changes
	 * @param  newSObjects  List of SObjects with changes
	 */
	@testVisible
	protected void process(Map<Id, SObject> oldSObjects, List<SObject> newSObjects) {
		for (SObject newSObject : newSObjects) {
			processRecord(
				(oldSObjects == null) ? null : oldSObjects.get(newSObject.Id), 
				newSObject
			);
		}
	}

	/**
	 * @description processRecord determines the Platform Event to send.
	 * @param  oldSObject  SObject before changes
	 * @param  newSObject  SObject with changes
	 */
	@TestVisible
	protected virtual void processRecord(SObject oldSObject, SObject newSObject) {
		String id = (String) newSObject.get('Id');
		String spotioId = (String) newSObject.get('Spotio_Id__c');

		switch on action {
			when INSERTING {
				if (spotioId == null) {
					addEvent(id, ActionType.CREATED);
				} else {
					addEvent(id, ActionType.UPDATED);
				}				
			}
			when UPDATING {
				if (blockedUsers.contains(UserInfo.getName())) {
					if (overrideBlockedUsers(oldSObject, newSObject)) {
						addEvent(id, ActionType.UPDATED);
					}
				} else if (hasUpdatedField(oldSObject, newSObject)) {
					addEvent(id, ActionType.UPDATED);
				}
			}
			when DELETING {
				if (spotioId != null) {
					addEvent(id, ActionType.DELETED);
				}
			}
		}
	}

	/**
	 * @description overrideBlockedUsers allows a Platform event to occur event if the
	 * active user is blocked.
	 * @return  true if Platform Event should still be fired.
	 */
	protected virtual Boolean overrideBlockedUsers(SObject oldSObject, SObject newSObject) {
		return false;
	}

	/**
	 * @description addEvent adds an event to the list of events to be published.
	 * @param  id         Id of the object
	 * @param  typeEvent  Type of event
	 */
	@TestVisible
	protected void addEvent(String id, ActionType typeEvent) {
		events.add(
			new Spotio_Event__e(
				Object_Name__c = nameObject,
				Object_Id__c = id,
				Type__c = typeEvent.name()
			)
		);
	}

	/**
	 * @description hasUpdatedField determines if at least one of the Spotio_Update_Fields__mdt
	 * fields has been updated.
	 * @param  oldRecord     Record before changes
	 * @param  newRecord     Record with changes
	 * @return true if one or more fields have changed.
	 */
	@TestVisible
	protected Boolean hasUpdatedField(SObject oldRecord, SObject newRecord) {
		for (String field : checkFields) {
			try {
				if (oldRecord.get(field) != newRecord.get(field)) {
					return true;
				}
			} catch (Exception e) {
				System.debug(LoggingLevel.INFO, 'Field not found: ' + field);
			}
		}

		return false;
	}

	/**
	 * @description readBlockedUsers reads the names of the users do not send
	 * Platform Events into class field blockedUsers.
	 */
	@TestVisible
	private void readBlockedUsers() {
		for (Spotio_Blocked_User__mdt blockedUser : [		
			SELECT Label 
			FROM Spotio_Blocked_User__mdt
		]){
			blockedUsers.add(blockedUser.Label);
		}
	}

	/**
	 * @description readUpdateFields reads the names of the fields which when changed require
	 * a Spotio Event Platform Event to be published.
	 * @param  nameObject  Name of the object
	 */
	@TestVisible
	private void readUpdateFields(String nameObject) {
		for (Spotio_Update_Fields__mdt field : [
			SELECT Field_Name__c 
			FROM Spotio_Update_Fields__mdt
			WHERE Active__c = TRUE 
			AND Object__c = :nameObject
			ORDER BY Field_Name__c ASC
		]) {
			checkFields.add(field.Field_Name__c);
		}
	}

	/**
	 * @decription publish sends the Platform Events.
	 * @param  events       List of events
	 * @param  nameMethod   Name of the method calling publish()
	 * @return true if all  events were published, false if any failed or no events.
	 */
	protected void publish() {		
		if (!events.isEmpty()) {
			textDebug = '\nPUBLISH PLATFORM EVENTS: ' + events.size();
	
			for (Spotio_Event__e event : events) {
				textDebug += '\n  ' + event;				
			}

			numberPublished += events.size();

			List<Database.SaveResult> listSaves = EventBus.publish(events);
		
			Log.writeIfError(
				Log.Severity.ERROR, 
				'SpotioPlatformEvent', 
				'SpotioPlatformEvent Failed',
				'Sending a Platform Event failed for the following items.',
				listSaves
			);
		}
	}
}