/**This class serves as trigger handler for contact object
 * @programer - Izay Ramos
 * @date - 10/23/2015
 * @version - 1.0
 */
public class ContactTriggerHandler {
    /**This method is executed when the trigger is on before context
     * @param List<Contact> newList - The contacts being processed by the trigger
     * @param Map<Id,Contact> oldMap - Map of old record when updating and deleting contacts. It is null on insert.
     */
    public static void before(List<Contact> newList, Map<Id,Contact> oldMap){
        if(runTriggerOnce_Before()){
            //Run this if trigger is on delete context
            if(Trigger.isDelete){
                //Fetch the active residential accounts where the contact(s) is the primary contact
                List<Account> accounts = [SELECT Id,Name,MH_Primary_Contact__c,Account_Status__c,Residential__c 
                                          FROM Account WHERE MH_Primary_Contact__c IN :oldMap.keySet() 
                                          AND Residential__c = TRUE AND Account_Status__c = 'Active'];
                if(accounts.size() > 0){
                    for(Account a :accounts){
                        Trigger.oldMap.get(a.MH_Primary_Contact__c).addError(' This is the Primary Contact for an active residential customer and cannot be deleted.');
                    }//End for
                }//End if accounts
            }//End if delete
            //Run this if trigger is on update context
            if(Trigger.isUpdate){
                //Check if the contact first name or last name changed
                Set<Id> cids = new Set<Id>();
                //For each contact
                for(Contact c :newList){
                    //If the contact
                    if(c.FirstName != oldMap.get(c.Id).FirstName || c.LastName != oldMap.get(c.Id).LastName){
                        cids.add(c.Id);
                    }//End if
                }//End for contact
                if(cids.size() > 0){
                    //Fetch the active residential accounts where the contact(s) is the primary contact
                    List<Account> accounts = [SELECT Id,Name,MH_Primary_Contact__c,Account_Status__c,Residential__c 
                                              FROM Account WHERE MH_Primary_Contact__c IN :cids 
                                              AND Residential__c = TRUE AND Account_Status__c = 'Active'];
                    if(accounts.size() > 0){
                        for(Account a :accounts){
                            Trigger.new[0].addError(' This is the Primary Contact for an active residential customer. The First and Last Name cannot be changed.');
                        }//End for
                    }//End if accounts
                }//End if cids
            }//End if update
        }//End if run once
        
    }//End before
    
	/**
    *** This variable and method are used to prevent triggers recursion on before insert/update
    */
    public static Boolean isFirstTriggerRun_Before = true;
    public static Boolean runTriggerOnce_Before(){
        if(isFirstTriggerRun_Before){
            isFirstTriggerRun_Before = false;
            return true;
        }else{
            return isFirstTriggerRun_Before;
        }
    }
    /**
    *** This variable and method are used to prevent triggers recursion on afterinsert/update
    */
    public static Boolean isFirstTriggerRun_After = true;
    public static Boolean runTriggerOnce_After(){
        if(isFirstTriggerRun_After){
            isFirstTriggerRun_After = false;
            return true;
        }else{
            return isFirstTriggerRun_After;
        }
    }
}