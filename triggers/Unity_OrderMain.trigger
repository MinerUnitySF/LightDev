trigger Unity_OrderMain on Order (after insert,after update,after delete) {

     if(Trigger.isAfter){
        if(Trigger.isInsert)
        {
            UNITY_OrderUtilities.onAfterInsert(Trigger.new);
        } 
        else if(Trigger.isUpdate)
        {
            UNITY_OrderUtilities.onAfterUpdate(Trigger.new,Trigger.oldMap);
        }
        else if(Trigger.isDelete)
        {
            UNITY_OrderUtilities.onAfterDelete(Trigger.old);
        }

      }

}