trigger UNITY_AssetHistoryTrigger on UNITY_Asset_History__c (After Insert, After Update ) {
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_AssetHistoryTriggerHandler.class);
}