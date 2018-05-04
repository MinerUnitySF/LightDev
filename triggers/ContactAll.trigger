/**This is the trigger for contacts
 * @programer - Izay Ramos
 * @date - 10/23/2015
 * @version - 1.0
 */
trigger ContactAll on Contact (before update, before delete) {
    if(Trigger.isBefore){
        ContactTriggerHandler.before(Trigger.new,Trigger.oldMap);
    }
}