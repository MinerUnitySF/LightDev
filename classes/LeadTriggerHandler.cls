/**This class serves as handler for lead triggers
** @programer: Izay Ramos-Irizarry
** @version: 1.0
** @date: 7/16/2015
*/
public class LeadTriggerHandler{
    //Method to be executed on the before context
    //@param newList - List<Lead>. The Leads in the Trigger.new
    //@param oldMap - Map<Id,Lead>. The leads in the Trigger.oldMap
    public static void before(List<Lead> newList, Map<Id,Lead> oldMap){
        
        if ( UserInfo.getName() == 'Invoca Admin' ) {
            Set<Id> leadIds = new Set<Id>();
            for ( Lead l : newList ) {
                leadIds.add( l.Id );
			}
            if ( hasRunAssignment!= null && !hasRunAssignment ) initiateUpdateToFireAssignmentRules( leadIds );
            return;
        }
        
        if((runTriggerOnce_Before() && Trigger.isUpdate) || Trigger.isInsert){
                        //Get the Miner Corp Lead record type id
            String rtid = [SELECT Id FROM recordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Miner_Corp_BDC_Leads' LIMIT 1].Id;
            String assignedId = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Miner_Corp_Lead_Assigned' LIMIT 1].Id;
            List<Lead> tmcLeads = new List<Lead>();//Hold miner corp leads
            List<Lead> needSuperCenter = new List<Lead>();
            //For each lead in the trigger contect
            for(Lead l :newList){
                //If the lead is a miner corp lead record tyoe
                if(l.RecordTypeId == rtid || l.RecordTypeId == assignedId){
                    tmcLeads.add(l);//Add the lead to the tmcLeads list
                    if(Trigger.isInsert){
                        needSuperCenter.add(l);
                    }else if(Trigger.isUpdate){
                        if(l.OwnerId != oldmap.get(l.Id).OwnerId){
                            needSuperCenter.add(l);
                        }
                    }
                }
            }
            //If there are tmc leads
            if(tmcLeads.size() > 0){
                validateLeadStatus(tmcLeads,oldMap);//Call the validateStatus method on tmc leads
            }
            if(needSuperCenter.size() > 0){
                setSuperCenter(needSuperCenter);
            }
        }
    }
    //Method to be executed on the after context
    public static void after(List<Lead> newList, Map<Id,Lead> oldMap){
        
    }
    //Method to set/validate miner corp leads status
    public static void validateLeadStatus(List<Lead> newList, Map<Id,Lead> oldMap){
        //if the trigger is inser or update... run this...
        if(Trigger.isInsert || Trigger.isUpdate){
            //For each miner corp lead...
            //Get the assigned lead record type id
            String assignedId = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Miner_Corp_Lead_Assigned' LIMIT 1].Id;
            String newId = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Miner_Corp_BDC_Leads' LIMIT 1].Id;
            for(Lead l :newList){
                //Get the object name for the lead owner
                Schema.SObjectType sobjectType = l.OwnerId.getSObjectType();
                String sobjectName = sobjectType.getDescribe().getName();
                //If trigger is insert
                if(Trigger.isInsert){
                    //If the leas status is not New...
                    if(l.Status != 'New'){
                        l.Status.addError(' This field can\'t be changed manually');//Display this error
                    }else if(l.Status == 'New' && sobjectName == 'User'){
                        l.Status = 'Assigned';//Set tatus to Assigned
                        l.RecordTypeId = assignedId;
                    }
                }//End if insert
                //If trigger is update...
                if(Trigger.isUpdate){
                    //If the leas status changed
                    if(l.Status != oldMap.get(l.Id).Status){
                        //If the lead status changed to Contacted and Date Time Contacted != null or the lead status s=changed to unqualified or not interested
                        if((l.Status == 'Contacted' && l.Date_Time_Contacted__c != null) || (l.Status == 'Not Interested')){
                            //Do Nothing
                        //CLAY:If status is changed to unqualified clear out the criteria so the status can stay unqualified
                        }else if(l.Status == 'Unqualified' || l.Status == 'Work Order Created'){    
                            l.We_Provide_Service_Requested__c = false;
                            l.We_Sell_Rent_Equipment_Requested__c = false;
                            l.Requested_Quote__c = false;
                            l.Requested_Site_Visit__c = false;
                        }else{//Otherwise...
                            if(l.Status == 'Qualified' && (!l.We_Provide_Service_Requested__c && !l.We_Sell_Rent_Equipment_Requested__c && !l.Requested_Quote__c && !l.Requested_Site_Visit__c)){
                                l.addError(' Select a qualifying criteria on the lead.');//Display this error
                            //If the lead status is new... and an user is the owner...
                            }else{
                                l.Status.addError(' This field can\'t be changed manually');//Display this error
                            }
                        }
                    }
                    //If the lead was qualified but the qualified criteria has been unchecked
                    //CLAY: If I set a lead as unqualified it needs to stay unqualified. Added a condition to also check if the old lead was unqualified
                    if(l.Status == 'Unqualified' || l.Status == 'Work Order Created'){
                        //do nothing
                    }else if((!l.We_Provide_Service_Requested__c && !l.We_Sell_Rent_Equipment_Requested__c && !l.Requested_Quote__c && !l.Requested_Site_Visit__c) && 
                       (oldMap.get(l.Id).We_Provide_Service_Requested__c || oldMap.get(l.Id).We_Sell_Rent_Equipment_Requested__c || oldMap.get(l.Id).Requested_Quote__c || oldMap.get(l.Id).Requested_Site_Visit__c)){
                           l.Unqualified_Reason2__c = ''; //clear out the unqualified reason
                           //If the lead owner is an user...
                           if(sobjectName == 'User'){
                               if(l.Date_Time_Contacted__c != null)//If it has been contacted...
                                   l.Status = 'Contacted';//Set status as Contacted                            
                               else//Otherwise...
                                   l.Status = 'Assigned';//Set status as Assigned
                           }else{
                               l.Status = 'New';
                               l.RecordTypeId = newId;
                           }
                       }
                    //Check if owner changed from queue to user and set the assigned date time stamp
                    sobjectType = oldMap.get(l.Id).OwnerId.getSObjectType();
                    String oldSobjectName = sobjectType.getDescribe().getName();
                    if((sobjectName == 'User' && oldSobjectName != 'User') || sobjectName == 'User' && l.Date_Time_Assigned__c == null){
                        //l.Date_Time_Assigned__c = DateTime.now();//Stamp Time Assigned to now
                    }
                    //If the lead status is new... and an user is the owner...
                    if(l.Status == 'New' && sobjectName == 'User'){
                        l.Status = 'Assigned';//Set tatus to Assigned
                        l.Date_Time_Assigned__c = DateTime.now();//Stamp Time Assigned to now
                        l.RecordTypeId = assignedId;
                    }else if(sobjectName == 'User'){
                        l.RecordTypeId = assignedId;
                    }
                    if(l.Status == 'Qualified'){
                        System.debug('Street: ' + l.Street);
                        System.debug('City: ' + l.City);
                        System.debug('State: ' + l.StateCode);
                        System.debug('Zip: ' + l.PostalCode);
                        if(String.isBlank(l.Street) || String.isBlank(l.City) || String.isBlank(l.StateCode) || String.isBlank(l.PostalCode)){
                            l.addError(' A complete address is required on qualified lead.');
                        }
                    }
                }//End if update
                //If the lead owner is not an user...
                if(sobjectName != 'User'){
                    l.Status = 'New';//Set tatus to Assigned
                    l.Date_Time_Assigned__c = null;//Stamp Time Assigned to now
                    l.RecordTypeId = newId;
                }
                //If any of the qualification criteria are checked...
                if(l.We_Provide_Service_Requested__c || l.We_Sell_Rent_Equipment_Requested__c || l.Requested_Quote__c || l.Requested_Site_Visit__c){
                    l.Status = 'Qualified';//Set status to Qualified
                    l.Unqualified_Reason2__c = '';//clear out any unqualified reason
                    if(String.isBlank(l.Street) || String.isBlank(l.City) || String.isBlank(l.StateCode) || String.isBlank(l.PostalCode)){
                        l.addError(' A complete address is required on qualified lead.');
                    }
                }//End if qualified
                if(String.isBlank(l.PostalCode)){
                    l.PostalCode.addError(' Zip/Postal Code is required');
                }
            }//End for lead
            
        }//End if insert or update
        
    }//End method
    //This method sets the super center on the lead
    public static void setSuperCenter(List<Lead> leads){
        Set<Id> qids = new Set<Id>();
        Set<Id> uids = new Set<Id>();
        Map<Id,List<Lead>> leadsMap = new Map<Id,List<Lead>>();
        for(Lead l :leads){
            //Get the object name for the lead owner
            Schema.SObjectType sobjectType = l.OwnerId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();
            if(sobjectName == 'User'){
                uids.add(l.OwnerId);
            }else{
                qids.add(l.OwnerId);
            }
            if(!leadsMap.containsKey(l.OwnerId)){
                List<Lead> temp = new List<Lead>();
                temp.add(l);
                leadsMap.put(l.OwnerId,temp);
            }else{
                leadsMap.get(l.OwnerId).add(l);
            }
        }
        if(uids.size() > 0){
            List<User> users = [SELECT Id,Super_Center__c FROM User WHERE Id IN :uids];
            for(User u :users){
                if(leadsmap.containsKey(u.Id)){
                    for(Lead l :leadsMap.get(u.Id)){
                        l.Miner_Corp_Company__c = u.Super_Center__c;
                    }
                }
            }
        }
        if(qids.size() > 0){
            List<Group> queues = [SELECT Id,Name FROM Group WHERE Id IN :qids];
            for(Group q :queues){
                if(leadsMap.containsKey(q.Id)){
                    for(Lead l :leadsMap.get(q.Id)){
                        String sc = q.Name.substring(0,(q.Name.indexof('Leads')));
                        l.Miner_Corp_Company__c = sc.trim();
                    }
                }
            }
        }
    }
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
    
    @future
    static void initiateUpdateToFireAssignmentRules(Set<Id> leadIds) {
        
        hasRunAssignment = true;
        
		List<Lead> leads = [SELECT Id FROM Lead WHERE Id IN: leadIds];
        
		AssignmentRule AR = new AssignmentRule();
		AR = [select id from AssignmentRule where SobjectType = 'Lead' and Active = true limit 1];

		Database.DMLOptions dmlOpts = new Database.DMLOptions();
		dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;

        for ( Lead l : leads ) {
        	l.setOptions(dmlOpts);
            l.Lead_Type__c = 'New/Target Account';
        }

        update leads;
    }
    
    public static boolean hasRunAssignment = false;
    
    
}