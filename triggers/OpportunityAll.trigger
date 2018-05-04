trigger OpportunityAll on Opportunity (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete){
        //instantiate our trigger handler
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler(Trigger.isExecuting, Trigger.size);
        //If trigger is on Before context
        if (Trigger.isBefore) {
            if (Trigger.isDelete){
                
            }else if (Trigger.isInsert){
                handler.onBeforeInsert(Trigger.new);
            }else if (Trigger.isUpdate){
                handler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
            }//end of is before context
        //If trigger is on after context
        }else if(Trigger.isAfter){            
            if (Trigger.isDelete){
                
            }else if (Trigger.isInsert){
                handler.onAfterInsert(Trigger.newMap);
            }else if (Trigger.isUpdate){
                handler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
            }
        }//end of is after context
    }