/*------------------------------------------------------------
Name:          UNITY_CaseUtilities
Author:        Krishna Kameneni
Company:       Miner
Description:   This utility class updateCaseOwner() method updates case owner before insert or update on Case.
History:
03/25/2015     Krishna Kameneni(Perficient)    Added/Modified comments
Created methods
------------------------------------------------------------*/
public class UNITY_CaseUtilities{
    /*
    public static void onBeforeInsert(List<Case> casesList){
        updateCaseOwner(casesList,null, null);
    }
    public static void onBeforeUpdate(Map<Id,Case> oldCasesMap,List<Case> newCasesList, Map<Id,Case> newCasesMap){
        List<Case> eligibleCases = new List<Case>();
        for(Case cVar: newCasesList){
            if(cVar.Origin != 'Phone')
                eligibleCases.add(cVar);
        }
        if(eligibleCases.size()>0)
            updateCaseOwner(eligibleCases,oldCasesMap,newCasesMap);
        
    }

    public static void updateCaseOwner(List<Case> casesList, Map<Id,Case> oldCasesMap, Map<Id,Case> newCasesMap){
        try{
            Set<Id>businessUnitIds=new Set<Id>();
            for(case c : casesList){
                businessUnitIds.add(c.UNITY_Business_Unit_Account__c);
            }
            System.debug('Business Unit###'+ businessUnitIds);
            List<Account>businessUnits = [SELECT Id,UNITY_TimeZoneSidKey__c,
                                          UNITY_Agent_Work_Day__c,
                                          UNITY_Agent_Work_Hour_Start_Time__c,
                                          UNITY_Agent_Work_Hour_End_Time__c,
                                          UNITY_Off_Hour_Queue__c
                                          FROM Account
                                          WHERE Id IN : businessUnitIds];
            Set<String> offHourQueueNames =new Set<String>();
            for(Account bu:businessUnits){
                offHourQueueNames.add(bu.UNITY_Off_Hour_Queue__c);
            }
            Map<Id,Account>idAccountMap=new Map<Id,Account>(businessUnits);
            Map<Id,Account>caseIdAccountMap =new Map<Id,Account>();
            List<Group> Queues = [SELECT Id,DeveloperName
                                  FROM Group 
                                  WHERE Type = 'Queue'
                                  AND DeveloperName IN :offHourQueueNames];
            Map<String,Id>nameQueueIdMap = new Map<String,Id>();
            for(Group q : Queues){
                nameQueueIdMap.put(q.DeveloperName,q.Id); 
            }
            for(Case c : casesList){
                caseIdAccountMap.put(c.Id,idAccountMap.get(c.UNITY_Business_Unit_Account__c));
            }
            
            for(Case c : casesList){
                String caseModifiedDayOfWeek = c.SystemModstamp.format('EEEE')!=NULL?c.SystemModstamp.format('EEEE'): DateTime.now().format('EEEE');
                if(!caseIdAccountMap.get(c.Id).UNITY_Agent_Work_Day__c.contains(caseModifiedDayOfWeek)){
                    if(!(oldCasesMap.get(c.Id).OwnerId == nameQueueIdMap.get(caseIdAccountMap.get(c.Id).UNITY_Off_Hour_Queue__c) && 
                      newCasesMap.get(c.Id).OwnerId != nameQueueIdMap.get(caseIdAccountMap.get(c.Id).UNITY_Off_Hour_Queue__c)))
                        c.OwnerId = nameQueueIdMap.get(caseIdAccountMap.get(c.Id).UNITY_Off_Hour_Queue__c);

                }
                else{
                    Account bu = caseIdAccountMap.get(c.Id);
                    Integer agentStartHour = Integer.valueOf(bu.UNITY_Agent_Work_Hour_Start_Time__c.substring(0,bu.UNITY_Agent_Work_Hour_Start_Time__c.indexOfChar(58)));
                    Integer agentStartMinute = Integer.valueOf(bu.UNITY_Agent_Work_Hour_Start_Time__c.indexOfChar(58)+1);
                    Time agentStartTime =Time.newInstance(agentStartHour,agentStartMinute,0,0);
                    Integer agentEndHour = Integer.valueOf(bu.UNITY_Agent_Work_Hour_End_Time__c.substring(0,bu.UNITY_Agent_Work_Hour_End_Time__c.indexOfChar(58)));
                    Integer agentEndMinute = Integer.valueOf(bu.UNITY_Agent_Work_Hour_End_Time__c.substring(bu.UNITY_Agent_Work_Hour_End_Time__c.indexOfChar(58)+1));
                    Time agentEndTime =Time.newInstance(agentEndHour,agentEndMinute,0,0);
                    UNITY_Utils.DateTimeZone tz =UNITY_Utils.getDateTime(c.SystemModstamp,null,bu.UNITY_TimeZoneSidKey__c);
                    Integer caseLastModifiedHour =tz.HH;
                    Integer caseLastModifiedMinute =tz.MM;
                    Time caseLastModifiedTime = Time.newInstance(caseLastModifiedHour,caseLastModifiedMinute,0,0);
                    System.Debug('caseLastModifiedHour:'+caseLastModifiedTime);
                    System.Debug('agent start time:'+agentStartTime);
                    System.Debug('agent End time:'+agentEndTime);
                    if(caseLastModifiedTime<agentStartTime || caseLastModifiedTime>agentEndTime){
                          if(!(oldCasesMap.get(c.Id).OwnerId == nameQueueIdMap.get(caseIdAccountMap.get(c.Id).UNITY_Off_Hour_Queue__c) && 
                      newCasesMap.get(c.Id).OwnerId != nameQueueIdMap.get(caseIdAccountMap.get(c.Id).UNITY_Off_Hour_Queue__c)))
                        c.OwnerId = nameQueueIdMap.get(caseIdAccountMap.get(c.Id).UNITY_Off_Hour_Queue__c);
                    }
                    
                }
            }
        }
        catch(Exception e){
            System.Debug('Error while changing case owner:'+e);
        }
    }
    */

    @future
    public static void fireAssignmentRule(Set<Id> caseIdsSet){
        List<Case> cases = [SELECT Id, UNITY_Fire_Assignment_Rule__c FROM Case WHERE Id IN :caseIdsSet];

        if (cases.size()>0)
        {
            List<Case> casesToUpdateList = new List<Case>();
            for(Case c : cases){
                if (c.UNITY_Fire_Assignment_Rule__c) {
                    case cx = new Case();
                    cx.Id = c.Id;
                    cx.UNITY_Fire_Assignment_Rule__c = false;

                    casesToUpdateList.add(cx);
                }
            }

            if (casesToUpdateList.size()>0)
            {
                try{
                    //AssignmentRule AR = new AssignmentRule();
                    Case_AssignmentRule_Helper caseARHelper = new Case_AssignmentRule_Helper();
                    AssignmentRule AR = caseARHelper.getCaseAssignmentRule();

                    Database.DMLOptions dmlOpts;
                    if (AR != null)
                    {
                        dmlOpts = new Database.DMLOptions();
                        dmlOpts.assignmentRuleHeader.assignmentRuleId = AR.Id;

                        for(Case cx : casesToUpdateList){
                            if (dmlOpts != null)
                                cx.setOptions(dmlOpts);
                        }
                    }

                    update casesToUpdateList;
                }
                catch(Exception e){
                    System.Debug('Error save case update with assignment rule:'+e);
                }
            }
        }
    }
    
    //without sharing required to get access to Assignment Rule object
    private without sharing class Case_AssignmentRule_Helper {
        private AssignmentRule getCaseAssignmentRule ()
        {
            try {                      
                AssignmentRule AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true Limit 1];
                return AR;
            } catch (Exception e){
                ApexPages.addMessages(e);
                return null;
            }

        }
    }
}