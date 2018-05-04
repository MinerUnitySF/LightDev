trigger WorkOrderAll on SVMXC__Service_Order__c (after insert, after update, before insert, before update) {
    //Run if trigger is before
    if(Trigger.isBefore){
        if(WorkOrderTriggerUtil.runTriggerOnce_Before()){
            if(Trigger.isInsert){
                WorkOrderTriggerUtil.before(Trigger.new,null,Trigger.isInsert,Trigger.isUpdate,Trigger.isDelete);
            }else{
                WorkOrderTriggerUtil.before(Trigger.new,Trigger.oldMap,Trigger.isInsert,Trigger.isUpdate,Trigger.isDelete);
            }
        }
        //Run this portion after workflow rules have executed on before context
        if(Trigger.isInsert){
            WorkOrderTriggerUtil.beforeRecursive(Trigger.new,null);
        }else{
            WorkOrderTriggerUtil.beforeRecursive(Trigger.new,Trigger.oldMap);
        }
    //Run if trigger is after
    }else if(Trigger.isAfter){
        if(WorkOrderTriggerUtil.runTriggerOnce_After()){
            WorkOrderTriggerUtil.after(Trigger.new,Trigger.oldMap,Trigger.isInsert,Trigger.isUpdate,Trigger.isDelete);
        }
    }
    
}