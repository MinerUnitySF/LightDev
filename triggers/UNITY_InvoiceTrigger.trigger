/*
 *   @programer:    Rodrigo Birriel
 *   @description:  handle the UNITY_Invoice__c trigger.
 *   @date:         01/14/2016            
 */
trigger UNITY_InvoiceTrigger on UNITY_Invoice__c (before insert, before update, after insert, after update, after delete) {
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_InvoiceTriggerHandler.class);
    //Izay: Added to call the Miner trigger handler
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_InvoiceTriggerHandler_Miner.class);
}