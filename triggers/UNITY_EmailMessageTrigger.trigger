/*
 *   @programer:    Rodrigo Birriel
 *   @description:  email message trigger.
 *   @date:         01/05/2016            
 */
trigger UNITY_EmailMessageTrigger on EmailMessage (before insert, after insert) {
    List<Id> emailMessageIds =new List<Id>();
        
    UNITY_TriggerFactory.createAndExecuteHandler(UNITY_EmailMessageTriggerHandler.class);
    
    /*
    if(Trigger.isAfter){
        if(Trigger.isInsert){ 
           for (EmailMessage em:trigger.new) {
               emailMessageIds.add(em.Id);
           }
           List<Attachment> attachments =[SELECT Id,Name
                                         FROM Attachment
                                         WHERE ParentId in :emailMessageIds
                                         AND Name LIKE 'Customer Signature%' 
                                         ];
           delete attachments;
    
        }
    }
    */
}