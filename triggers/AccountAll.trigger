trigger AccountAll on Account (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete) {

        if (Trigger.isBefore) {
            //set the isFirstTriggerRun_Before to false:
            if (Trigger.isDelete){
                
            }else if (Trigger.isInsert){
                AccountTriggerHandler.onBeforeInsert(Trigger.new);
            }else if (Trigger.isUpdate){
                //send our accounts to our handler method
                AccountTriggerHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
            }
        } else if (Trigger.isAfter) {
            //call handler.after method
            if (Trigger.isDelete){
                
            }else if (Trigger.isInsert){
                AccountTriggerHandler.onAfterInsert(Trigger.new);
            }else if (Trigger.isUpdate){
                AccountTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
            }
        }
        
}