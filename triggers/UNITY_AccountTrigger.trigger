trigger UNITY_AccountTrigger on Account (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_AccountHandler.class);
}