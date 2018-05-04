trigger UNITY_ProposalLineItemTrigger on UNITY_Proposal_Line_Item__c (after insert, before insert, after update, before update) {
    
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_ProposalLineItemHandler.class);
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_ProposalLineTriggerHandler_Miner.class);
}