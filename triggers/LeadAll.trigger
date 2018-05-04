/**This is the leads trigger. It routs leads to the LeadTriggerHandler class for processing
** @programer: Izay Ramos-Irizarry
** @version: 1.0
** @date: 8/26/2015
*/
trigger LeadAll on Lead (before insert, before update){
	//If the trigger is before...
    if (Trigger.isBefore ){
        //Call the before method in the LeadTriggerHandler class passing the new list and old map
        LeadTriggerHandler.before(Trigger.new, Trigger.oldMap);
    }//End if before
    
}