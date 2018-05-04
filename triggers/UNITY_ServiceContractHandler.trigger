trigger UNITY_ServiceContractHandler on UNITY_Service_Contract__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_ServiceContractHandler.class);

}