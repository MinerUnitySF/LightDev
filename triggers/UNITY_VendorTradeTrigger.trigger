trigger UNITY_VendorTradeTrigger on UNITY_Vendor_Trade__c (before insert, before delete) {
    
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_VendorTradeTriggerHandler.class);
    
}