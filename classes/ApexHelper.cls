/**This class serves as a helper for commonly used apex code
** @programer: Izay Ramos-Irizarry
** @version: 1.0
** @date: 4/6/2015
*/
global class ApexHelper{
    /**
    *** This variable and method are used to prevent triggers recursion on before insert/update
    */
    global static Boolean isFirstTriggerRun_Before = true;
    global static Boolean runTriggerOnce_Before(){
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
    global static Boolean isFirstTriggerRun_After = true;
    global static Boolean runTriggerOnce_After(){
        if(isFirstTriggerRun_After){
            isFirstTriggerRun_After = false;
            return true;
        }else{
            return isFirstTriggerRun_After;
        }
    }
    /**
    *** This variable and method are used to prevent triggers recursion on afterinsert/update
    */
    global static Boolean lastTriggerRun_Before = true;
    global static Boolean runTriggerStop_Before(){
        if(lastTriggerRun_Before){
            lastTriggerRun_Before = false;
            return true;
        }else{
            return lastTriggerRun_Before;
        }
    }
    /**
    *** This method returns an url query string given its name 
    */
    global static String getParam(String name){
        return ApexPages.currentPage().getParameters().get(name);
    } 
    public static String joinIds(Set<Id> ids){
        String joinedIds = '';
        for(String s :ids){
            joinedIds += '\''+s+'\',';
        }
        if(joinedIds.length() > 0){
            joinedIds = '(' + joinedIds.removeEnd(',') + ')';
        }
        return joinedIds;
    }
    public static String joinIds(List<Id> ids){
        String joinedIds = '';
        for(String s :ids){
            joinedIds += '\''+s+'\',';
        }
        if(joinedIds.length() > 0){
            joinedIds = '(' + joinedIds.removeEnd(',') + ')';
        }
        return joinedIds;
    }
    /**
    *** This method checks if a trigger is on or off based on trigger switch
    
    global static Boolean isTriggerOn(String name){
        List<Trigger_Switch__c> switches = [SELECT Id,Name,Trigger_Name__c,Switch_by_Profile__c,Master_Switch__c FROM Trigger_Switch__c WHERE Name = :name];
        Boolean active = true;
        if(switches.size() > 0){
            String pName = [SELECT Id,Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;
            for(Trigger_Switch__c s :switches){
                if(s.Master_Switch__c == 'OFF'){
                    active = false;
                }else if(s.Switch_by_Profile__c.contains(pName)){
                    active = false;
                }
            }
        }
        return active;
    }
    */ 
}