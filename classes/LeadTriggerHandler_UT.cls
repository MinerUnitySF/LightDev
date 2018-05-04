/**
 * LeadTriggerHandler_UT
 * Izay Ramos-Irizarry
 * 9.29.2015
 * izramos@minercorp.com
 */
@isTest(SeeAllData=true)
public class LeadTriggerHandler_UT {
    //Test insertion of leads and assignment to Lead Queue
    public static TestMethod void test1(){
        //Create three(3) leads
        List<Lead> leads = TestDataProvider.getLeads(3, 'Miner_Corp_BDC_Leads');
        leads[0].PostalCode = '78232';//Set the zip on a leads to match an assignment rule
        leads[0].Business_Unit__c = 'Miner Corp';//Set the lead business unit to miner corp
        leads[0].LeadSource = 'Cold Call';//Set the lead source
        String qid = [SELECT Id,Name FROM Group WHERE Name LIKE '%Leads%' AND Type = 'Queue' LIMIT 1].Id;
        System.debug('============= qid: '+qid);
        leads[0].OwnerId = qid;
        //Start test
        test.startTest();
        //Insert the leads
        insert leads;
        //Get the lead ids to refetch the lead records
        Set<Id> lids = new Set<Id>();
        for(Lead l :leads){
            lids.add(l.Id);
        }
        leads = [SELECT Id,OwnerId,We_Provide_Service_Requested__c,Status,Unqualified_Reason2__c,Street,City,StateCode,PostalCode FROM Lead WHERE Id IN :lids];
        //Change lead status to 'Assigned' by changing lead owner from queue to user
        //Get the queue id
        Id lid = null;
        for(Lead l :leads){
            Schema.SObjectType sobjectType = l.OwnerId.getSObjectType();
            String sObjectName = sobjectType.getDescribe().getName();
            if(sObjectName != 'User'){
                l.OwnerId = UserInfo.getUserId();
                lid = l.Id;
            }
        }
        System.debug('================== lid: ' + lid);
        //Update lead
        resetTrigger();
        Database.update(leads);
        //Change lead status to 'Contacted' by loging a call
        //create a task (log a call)
        Task t = new Task(
            Subject = 'Call',
            Description = 'Something on the call',
            WhoId = lid,
            ActivityDate = Date.today(),
            Status = 'Completed'
        );
        //Insert the task
        insert t;
        Lead lead = new Lead();
        lead = [SELECT Id,OwnerId,We_Provide_Service_Requested__c,Status,Unqualified_Reason2__c,Street,City,StateCode,State,PostalCode FROM Lead WHERE Id = :lid LIMIT 1];
        System.debug('============== Lead Status: ' + lead.Status);
        //Change lead status to 'Qualified' by checking a qualifying criteria
        lead.We_Provide_Service_Requested__c = true;
        //Update lead
        resetTrigger();
        Database.update(lead);
        lead = [SELECT Id,OwnerId,We_Provide_Service_Requested__c,Status,Unqualified_Reason2__c,Street,City,StateCode,State,PostalCode FROM Lead WHERE Id = :lid LIMIT 1];
        System.debug('============== Lead Status: ' + lead.Status);
        //Change the lead status by deselecting the qualifying criteria
        lead.We_Provide_Service_Requested__c = false;
        //Update lead
        resetTrigger();
        Database.update(lead);//Was failing
        lead = [SELECT Id,OwnerId,We_Provide_Service_Requested__c,Status,Unqualified_Reason2__c,Street,City,StateCode,State,PostalCode FROM Lead WHERE Id = :lid LIMIT 1];
        System.debug('============== Lead Status: ' + lead.Status);
        //Change lead status to 'Unqualified' by changing status and setting Unqualified Reason
        lead.Status = 'Unqualified';
        lead.Unqualified_Reason2__c = 'We do not provide service requested';
        resetTrigger();
        Database.update(lead);
        //Change the lead status manually to 'Qualified'
        try{
            lead.Status = 'Qualified';
            resetTrigger();
            Database.update(lead);
        }catch(Exception e){}
        lead = [SELECT Id,OwnerId,We_Provide_Service_Requested__c,Status,Unqualified_Reason2__c,Street,City,StateCode,State,PostalCode FROM Lead WHERE Id = :lead.Id LIMIT 1];
        System.debug('============== Lead Status: ' + lead.Status);
        //Re-assign the lead back to a queue
        if(String.isNotBlank(qid)){
            lead.OwnerId = qid;
            resetTrigger();
            Database.update(lead);
        }
        test.stopTest();
    }
    public static void resetTrigger(){
        ////Reset trigger run
        LeadTriggerHandler.isFirstTriggerRun_Before = true;
        LeadTriggerHandler.isFirstTriggerRun_After = true;
    }
}