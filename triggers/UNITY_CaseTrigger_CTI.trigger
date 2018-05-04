/**This triggers the handler for cases and CTI integration purposes
 * @programmer: Izay Ramos-Irizarry
 * @date: 2/22/2016
 * @version: 0.1
 */
trigger UNITY_CaseTrigger_CTI on Case (before insert, before update) {
    //If the trigger is in the before context...
    if(Trigger.isBefore){
        //Call the before method in the CaseTriggerhandler_CTI
        //UNITY_CaseTriggerHandler_CTI.before(Trigger.new,Trigger.oldMap);
    }
}