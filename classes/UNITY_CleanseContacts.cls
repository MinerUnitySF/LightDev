public class UNITY_CleanseContacts implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext context) {
         return Database.getQueryLocator([SELECT id, Email FROM Contact 
                  						WHERE Email != 'mns_uat@minercorp.com'
             ]);
    }
    
    public void execute(Database.BatchableContext context, List<Contact> scope) {
               
        List<Contact> cToUpdate = new List<Contact>();
        for (Contact c : scope){
                              string text= c.email;
                              c.description = text;
                              c.email =  'mns_uat@minercorp.com';                      
                              cToUpdate.add(c);
                          }
        update cToUpdate;
			 
    }
    
     public void finish(Database.BatchableContext context) {
    }
 
}