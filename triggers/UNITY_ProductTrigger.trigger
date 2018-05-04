trigger UNITY_ProductTrigger on Product2 (before insert, before update) {
     UNITY_TriggerFactory.createAndExecuteHandler(UNITY_ProductHandler.class);
}