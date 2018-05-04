trigger UNITY_InvoiceLineTrigger on UNITY_Invoice_Line_Item__c (before insert, before update, after insert, after update) {
	//Izay: Added to call the Miner trigger handler
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_InvoiceLineTriggerHandler_Miner.class);
}