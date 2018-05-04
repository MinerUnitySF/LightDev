trigger UNITY_ServiceContractLineItemTrigger on UNITY_Service_Contract_Line_Item__c (after insert, after update) {
    
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_ServiceContractLineItemHandler.class);
    
}