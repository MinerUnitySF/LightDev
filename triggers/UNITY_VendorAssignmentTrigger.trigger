/*
 *   @programer:    Rodrigo Birriel
 *   @description:  vendor assigment trigger.
 *   @date:         01/05/2016            
 */
trigger UNITY_VendorAssignmentTrigger on UNITY_Vendor_Assignment__c (before insert, after update) {

    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_VendorAssignmentTriggerHandler.class);
    
}