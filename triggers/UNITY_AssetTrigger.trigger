trigger UNITY_AssetTrigger on Asset (before insert, after insert, before update, after update, after delete) {
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_AssetTriggerHandler.class);
}