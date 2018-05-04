trigger UNITY_ProposalTrigger on UNITY_Proposal__c (before insert,after insert, before update, after update) {
    
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_ProposalTriggerHandler.class);
    //Izay: Added line to call the Miner trigger handler
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_ProposalTriggerHandler_Miner.class);
    
}