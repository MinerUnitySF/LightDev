/*------------------------------------------------------------
Name:           UNITY_UpdateCaseStatus
Author:         Krishna Kamineni (Perficient)
Company:        Miner
Description:    This updateStatus() method updates status field by assign least status of its workorders
History:
03/22/2016      Krishna Kamineni Initial version.
------------------------------------------------------------*/
public class UNITY_UpdateCaseStatus{
    public static Map<String,String> caseIdToScStatusMap;

    @future
    //public static void onAfterInsert(String woList){
    public static void onAfterInsert(Set<Id> woIdSet){
        //List<SObject> workOrdersList = (List<SObject>)JSON.deserialize(woList, List<SObject>.class);
        List<WorkOrder> workOrdersList = queryForWorkOrderFieldsToUpdateStatus( woIdSet );
        System.debug('#####Izay: In UNITY_UpdateCaseStatus.onAfterInsert');
        updateStatus(workOrdersList,null);
    }
    @future(callout=true)
    //Clay - changed to callout=true to assist in mulesoft callout
    //public static void onAfterUpdate(String woList ,String oldWOs){
    public static void onAfterUpdate(Set<Id> woIdSet, String oldWOs){
        UNITY_Constants.isExecutingContext('UNITY_UpdateCaseStatus.onAfterInsert');
        //List<SObject> workOrdersList = (List<SObject>)JSON.deserialize(woList, List<SObject>.class);
        List<SObject> workOrdersList = queryForWorkOrderFieldsToUpdateStatus( woIdSet );
        Map<Id,SObject> oldMap = (Map<Id,SObject>)JSON.deserialize(oldWOs, Map<Id,SObject>.class);
        updateStatus(workOrdersList,oldMap);
    }
    
    public static List<sObject> queryForWorkOrderFieldsToUpdateStatus(Set<Id> woIdSet) {
        return [SELECT Id, CaseId, Status FROM WorkOrder WHERE Id IN: woIdSet];
    }
    
    public static void updateStatus(List<SObject> workOrdersList,Map<Id,SObject>oldMap){
        List<Id> caseIds =new List<Id>();
        List<Case>eligibleCasesForUpdate =new List<Case>();
        for(SObject woObj : workOrdersList){
            WorkOrder wo = (WorkOrder)woObj;

            if(oldMap==null)
                caseIds.add(wo.CaseId);
            else if(wo.Status!=((WorkOrder)oldMap.get(wo.id)).status)
                caseIds.add(wo.CaseId);
        }

        if (caseIds.size() > 0)
        { //removed UNITY_BS_Service_Channel_Status_Text__c from query. Cant remember why it was there, but Im not referencing it anywhere else.
            List<Case> cases =[SELECT Id,Status, UNITY_Service_Channel_Status__c, UNITY_Portal_Source__c
                               FROM Case
                               WHERE Id = :caseIds];    
            //CLAY - clearing for future method
            caseIds.clear();
            Map<Id,Case>idCaseMap = new Map<Id,Case>(cases);       
            if(!cases.isEmpty()){
                List<WorkOrder>workOrders =[SELECT Id,Status,CaseId
                                            FROM WorkOrder
                                            WHERE CaseId =:idCaseMap.keySet()];
                Map<Id,List<WorkOrder>>caseIdWorkOrderMap =new Map<Id,List<WorkOrder>>();
                for(WorkOrder wo : workOrders){
                    if(!caseIdWorkOrderMap.containskey(wo.CaseId)){
                        caseIdWorkOrderMap.put(wo.CaseId, new List<WorkOrder>());                
                    }
                    caseIdWorkOrderMap.get(wo.CaseId).add(wo);
                }//CLAY: I added the UNITY_Service_Channel_Status__c - going to see if this will do status mappings
                List<UNITY_WorkOrder_Case_Status_Values_Map__mdt> statusValues =[SELECT UNITY_SequenceNumber__c,UNITY_WorkOrder_Status__c,UNITY_Case_Status__c, UNITY_Service_Channel_Status__c
                                                             FROM UNITY_WorkOrder_Case_Status_Values_Map__mdt
                                                             Order By UNITY_SequenceNumber__c asc];
                Map<String,Decimal>workOrderStatusSequenceNumberMap = new Map<String,Decimal>();
                Map<String,String>workOrderStatusCaseStatusMap = new Map<String,String>();
                //CLAY
                Map<Decimal, String>sequenceToScStatusMap = new Map<Decimal, String>();
                for(UNITY_WorkOrder_Case_Status_Values_Map__mdt cs : statusValues){
                    workOrderStatusSequenceNumberMap.put(cs.UNITY_WorkOrder_Status__c,cs.UNITY_SequenceNumber__c);
                    workOrderStatusCaseStatusMap.put(cs.UNITY_WorkOrder_Status__c,cs.UNITY_Case_Status__c);
                    //adding the sequence and service channel status to the map:
                    sequenceToScStatusMap.put(cs.UNITY_SequenceNumber__c, cs.UNITY_Service_Channel_Status__c);
                }
                String newStatus = null;
                Decimal caseSeq;
                
                for(Id caseId : caseIdWorkOrderMap.keySet()){
                    Boolean updated = false;
                    //need to have the method also return the sequence number
                    Map<string, decimal> tempStatSeq = getLeastStatus(caseIdWorkOrderMap.get(caseId),workOrderStatusSequenceNumberMap,workOrderStatusCaseStatusMap);
                    //newStatus = getLeastStatus(caseIdWorkOrderMap.get(caseId),workOrderStatusSequenceNumberMap,workOrderStatusCaseStatusMap);
                    //set the newstatus as the key (should be the first one)
                    if (tempStatSeq.size() > 0){
                        newStatus = (new List<String>(tempStatSeq.keySet()))[0];                        
                        caseSeq = tempStatSeq.values()[0];
                    }

                    if(newStatus!=null){
                        if (idCaseMap.get(caseId).Status != newStatus){
                            updated = true;
                            idCaseMap.get(caseId).Status = newStatus;    
                        }
                        if(sequenceToScStatusMap.containskey(caseSeq) && sequenceToScStatusMap.get(caseSeq) != null){
                            updated = true;
                            //idCaseMap.get(caseId).UNITY_Service_Channel_Status__c = sequenceToScStatusMap.get(caseSeq);
                            If (sequenceToScStatusMap.get(caseSeq) != idCaseMap.get(caseId).UNITY_Service_Channel_Status__c 
                                    && idCaseMap.get(caseId).UNITY_Portal_Source__c == UNITY_Constants.CASE_PORTAL_SOURCE_SERVICE_CHANNEL) {

                                idCaseMap.get(caseId).UNITY_Service_Channel_Status__c = sequenceToScStatusMap.get(caseSeq);
                                //adding this case to the list of 
                                caseIds.add(caseId);
                                if (caseIdToScStatusMap == null){
                                    caseIdToScStatusMap = new Map<String,String>();
                                }
                                caseIdToScStatusMap.put(caseId, sequenceToScStatusMap.get(caseSeq));


                            }
                        }
                        if (updated)
                            eligibleCasesForUpdate.add(idCaseMap.get(caseId));
                    }
                    //See if our case's sequence number has a service channel status to switch to
                    //if( ){
                    //    idCaseMap.get(caseId).UNITY_Service_Channel_Status__c = sequenceToScStatusMap.get(caseSeq);
                    //    eligibleCasesForUpdate.add(idCaseMap.get(caseId)); 
                    //}
                }

                try{
                    if (caseIds.size() > 0)
                        UNITY_MuleCalloutOperation.prepareCallOutAlt(caseIds, 'Case');

                    if ( eligibleCasesForUpdate.size()>0 ) update eligibleCasesForUpdate; 
                    //CLAY: TODO
                    //needs to return list of case Ids that get updated                    
                    //return caseIds;         
                }catch(DMLException e){
                    System.Debug('Error:***********************'+e);
                }
            }
        } 
        //return caseIds;       
    }
    
    public static Map<String, Decimal> getLeastStatus(List<WorkOrder>workOrders, Map<String,Decimal>statusValueMap,Map<String,String>workOrderStatusCaseStatusMap){
        Decimal sequenceNumber,min;
        min = statusValueMap.get(workOrders.get(0).Status);
        String leastStatus = workOrderStatusCaseStatusMap.get(workOrders.get(0).Status);
        for(WorkOrder wo : workOrders){
            sequenceNumber = statusValueMap.get(wo.Status);
            if(sequenceNumber<min){
                min=sequenceNumber;
                leastStatus=workOrderStatusCaseStatusMap.get(wo.status);
            }
        }
        //CLAY:
        //will return not only the status but also the sequence number to assist in getting the SC status (sequence is unique)
        MAP<String, Decimal> statusToSequence = new MAP<String, Decimal>();
        statusToSequence.put(leastStatus, sequenceNumber);
        //return leastStatus;
        return statusToSequence;
    }
}