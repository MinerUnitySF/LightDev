/**This triggers the handler for cases and CTI integration purposes
 * @programmer: Izay Ramos-Irizarry
 * @date: 2/22/2016
 * @version: 0.1
 */
trigger UNITY_CaseTrigger_Miner on Case (before insert, before update) {
    
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_CaseTriggerHandler_Miner.class);
    
}