/**
 * @description BoxSign_TriggerHandler controls trigger events for box__BoxSign__c objects.
 */
public class BoxSign_TriggerHandler extends TriggerHandlerInvoker.TriggerHandler_Abstract {

    override public void afterInsert(Map<Id, SObject> mapNew) {
		Map<Id, box__BoxSign__c> newBoxSign = (Map<Id, box__BoxSign__c>) mapNew;
        BoxSign_Services.linkOppDocWithBoxSign(newBoxSign);
	}

}