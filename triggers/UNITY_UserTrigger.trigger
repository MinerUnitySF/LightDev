/*
 *   @programer:    Rodrigo Birriel
 *   @description:  handle the User trigger.
 *   @date:         12/??/2015            
 */
trigger UNITY_UserTrigger on User (after insert) {
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_UserTriggerHandler.class);
}