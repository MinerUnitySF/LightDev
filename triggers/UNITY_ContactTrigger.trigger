/*
 *   @programer:    Rodrigo Birriel
 *   @description:  handle the contact trigger.
 *   @date:         12/??/2015            
 */
trigger UNITY_ContactTrigger on Contact (before insert, before update, after insert, after update) {

    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_ContactTriggerHandler.class);
    
}