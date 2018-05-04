trigger MSPFS_ServiceEvents on CKSW_BASE__Service__c (before insert, before update ) {
    UNITY_TriggerFactory.createAndExecuteHandler(MSPFS_ServiceTriggerHandler.class);
}