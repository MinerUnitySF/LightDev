trigger UNITY_AttachmentMain on UNITY_Attachment__c (after insert,after update,after delete, before insert){
     if(Trigger.isAfter){
        if(Trigger.isInsert)
        {
            UNITY_AttachmentUtilities.onAfterInsert(Trigger.new);
        } 
        else if(Trigger.isUpdate)
        {
            UNITY_AttachmentUtilities.onAfterUpdate(Trigger.new,Trigger.oldMap);
        }

        else if(Trigger.isDelete)
        {
            UNITY_AttachmentUtilities.onAfterDelete(Trigger.old);
        }
    }
    if (Trigger.isBefore){
        if (Trigger.isInsert){
            UNITY_AttachmentUtilities.onBeforeInsert(Trigger.new);
        }
    }

}