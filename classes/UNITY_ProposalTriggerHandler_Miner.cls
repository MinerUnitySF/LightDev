public class UNITY_ProposalTriggerHandler_Miner extends UNITY_BaseHandler{
	private static Map<Id,RecordType> qRTs;
    private static Map<Id,RecordType> woRTs;
    
    static{
        if(qRTs == null){
            qRTs = new Map<Id,RecordType>([SELECT Id,Name,DeveloperName FROM recordType WHERE SObjectType = 'UNITY_Proposal__c']);
        }
        if(woRTs == null){
            woRTs = new Map<Id,RecordType>([SELECT Id,Name,DeveloperName FROM recordType WHERE SObjectType = 'WorkOrder']);
        }
    }
    
    public override void bulkAfter(){
        String masterRTId = UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE;//The master quote record type id
        String subRTId = UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE;
        //If the trigger is update...
        if(Trigger.isUpdate || Trigger.isInsert){
            
            Set<Id> woIds = new Set<Id>();//Holds the work order ids for the changed orders
            List<UNITY_Proposal__c> thisQuotes = new List<UNITY_Proposal__c>();
            //List<Id> toUpdateMaster = new List<Id>();
            List<Id> qidsAvatax = new List<Id>();
            
            //Get work order id for any order that changed status or any new order
            for(SObject s :trigger.new){
                UNITY_Proposal__c q = (UNITY_Proposal__c)s;
                if(trigger.isInsert){
                    if(q.RecordTypeId == subRTId){
                        woIds.add(q.UNITY_Work_Order__c);
                        thisQuotes.add(q);
                    }
                }else if(trigger.isUpdate){
                    UNITY_Proposal__c oldQ = (UNITY_Proposal__c)trigger.oldMap.get(q.Id);
                    //If it is a sub quote and the status changed...
                    //Collect the work order ids to update the status based on the quote status
                    if(q.RecordTypeId == subRTId && q.UNITY_Proposal_Status__c != oldQ.UNITY_Proposal_Status__c){
                        woIds.add(q.UNITY_Work_Order__c);
                        thisQuotes.add(q);
                    }
                    //If it is a sub quote and needs tax or the total price changed...
                    //Collect the quote ids to call avatax
                    if(q.RecordTypeId == subRTId && q.UNITY_Proposal_Status__c == 'Quote Creation' && 
                       (!q.UNITY_Tax_Processed__c || (q.UNITY_Final_Price2__c != oldQ.UNITY_Final_Price2__c))){
                           qidsAvatax.add(q.Id);
                           //toUpdateMaster.add(q.UNITY_Master_Quote__c);
                       }
                    
                    System.debug('##### masterquote rtid: ' + masterRTId);
                    System.debug('##### quote recordtypeId: ' + q.RecordTypeId);
                    System.debug('##### new Status: ' + q.UNITY_Status__c);
                    System.debug('##### old Status: ' + oldQ.UNITY_Status__c);
                    //If it is a master quote and the status changed to Quote Finalized...
                    //Attach the quote pdf to the case
                    if(q.RecordTypeId == masterRTId && (q.UNITY_Proposal_Status__c != oldQ.UNITY_Proposal_Status__c) && 
                       (q.UNITY_Proposal_Status__c == 'Quote Finalized' && !q.UNITY_Has_Pending_Approval_Sub_Quotes__c) && 
                       !UNITY_Constants.isExecutingContext('UNITY_AttachmentHelper_Miner.attachQuote')){
                           //Add the quote id to the finalized quote ids set
                           UNITY_AttachmentHelper_Miner.attachQuote(q.Id);
                       }
                }
                
            }
            //If there are quotes that need tax...
            if(!qidsAvatax.isEmpty()){
                //System.debug('#####Izay: toUpdateMaster: ' + toUpdateMaster.size());
                if(!System.isFuture()){
                    setQuoteTax(qidsAvatax);
                }
            }
			//If there are work order that need status update...
            if(woIds.size() > 0){
                updateWOStatus(woIds,thisQuotes);
            }
        }
    }

    @future(callout=true)
    public static void setQuoteTax(List<Id> qidsAvatax){
        UNITY_Constants.isExecutingContext.put('UNITY_ProposalTriggerHandler_Miner.setQuoteTax',true);
        if(!qidsAvatax.isEmpty()){
            UNITY_CallAvatax.AvataxResult taxResult = UNITY_CallAvatax.getTaxQuote(qidsAvatax,'quote');
            System.debug('#taxResult ' + taxResult);
        }
    }
    /** This method updates the Work Order status based on the quote status change
     * @param woids - Set<Id>: A set with the work order ids
     * @param thisQuotes - List<UNITY_Proposal__c>: List of quotes that changed status
     * */
    public static void updateWOStatus(Set<Id> woids,List<UNITY_Proposal__c> thisQuotes){
        String subRTId = UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE;
        if(woIds.size() > 0){
            //get the values from the custom setting
            List<UNITY_Status_Fields_Update_Map__c> statusMapping = UNITY_Status_Fields_Update_Map__c.getAll().values();
            Map<String,UNITY_Status_Fields_Update_Map__c> toStatusMap = new Map<String,UNITY_Status_Fields_Update_Map__c>();
            //Find all mapping from order to work order
            for(UNITY_Status_Fields_Update_Map__c sMap :statusMapping){
                if(sMap.UNITY_Origin_Object__c == 'UNITY_Proposal__c' && sMap.UNITY_Target_Object__c == 'WorkOrder'){
                    toStatusMap.put(sMap.UNITY_Origin_Value__c,sMap);
                }
            }
            //get all the work orders for the orders that changed status
            Map<Id,WorkOrder> wosMap = new Map<Id,WorkOrder>([SELECT Id,Status,RecordTypeId,UNITY_MultiTrip_Actual__c FROM WorkOrder WHERE Id IN :woIds]);
            //Set the statuses that cannot be overwriten
            Set<String> noOverwrite = new Set<String>{'Completed','Closed','Assigned'};
                //Get all order for the work orders
                List<UNITY_Proposal__c> allQs = new List<UNITY_Proposal__c>();
            allQs = [SELECT Id,UNITY_Proposal_Status__c,UNITY_Work_Order__c,RecordTypeId FROM UNITY_Proposal__c WHERE UNITY_Work_Order__c IN :woIds AND RecordTypeId = :subRTId AND Id NOT IN :trigger.newMap.keyset()];
            allQs.addAll(thisQuotes);
            Map<Id,List<UNITY_Proposal__c>> woOrdsMap = new Map<Id,List<UNITY_Proposal__c>>();//Hols all order by the work order
            //Put the orders in the woOrdsMap by the work order id
            for(UNITY_Proposal__c q :allQs){
                if(!woOrdsMap.containsKey(q.UNITY_Work_Order__c)){
                    List<UNITY_Proposal__c> temp = new List<UNITY_Proposal__c>();
                    temp.add(q);
                    woOrdsMap.put(q.UNITY_Work_Order__c,temp);
                }else{
                    woOrdsMap.get(q.UNITY_Work_Order__c).add(q);
                }
            }
            //Updated work orders
            List<WorkOrder> woToUpdate = new List<WorkOrder>();
            for(Id key :woOrdsMap.keySet()){
                if(wosMap.containsKey(key)){
                    String woStatus = wosMap.get(key).Status;
                    String woRTName = '';
                    if(woRTs.containsKey(wosMap.get(key).RecordTypeId)){
                        woRTName = woRTs.get(wosMap.get(key).RecordTypeId).DeveloperName;
                    }
                    String status = '';
                    Integer num;
                    for(UNITY_Proposal__c q :woOrdsMap.get(key)){
                        String myRTName = '';
                        if(qRTs.containsKey(q.recordTypeId)){
                            myRTName = qRTs.get(q.RecordTypeId).DeveloperName;
                        }
                        if(toStatusMap.containsKey(q.UNITY_Proposal_Status__c)){
                            String originValue = toStatusMap.get(q.UNITY_Proposal_Status__c).UNITY_Origin_Value__c;
                            String targetValue = toStatusMap.get(q.UNITY_Proposal_Status__c).UNITY_Target_Value__c;
                            String originRT = toStatusMap.get(q.UNITY_Proposal_Status__c).UNITY_Origin_Record_Type__c;
                            String targetRT = toStatusMap.get(q.UNITY_Proposal_Status__c).UNITY_Target_Record_Type__c;
                            Boolean tRTMatch = false;
                            Boolean oRTMatch = false;
                            if(String.isNotBlank(targetRT)){
                                if(woRTName == targetRT){
                                    tRTMatch = true;
                                }
                            }else{
                                tRTMatch = true;
                            }
                            if(String.isNotBlank(originRT)){
                                if(myRTName == originRT){
                                    oRTMatch = true;
                                }
                            }else{
                                oRTMatch = true;
                            }
                            if(tRTMatch && oRTMatch){
                                Integer i = Integer.valueOf(toStatusMap.get(q.UNITY_Proposal_Status__c).UNITY_Order__c);
                                if(num == null){
                                    num = i;
                                    status = toStatusMap.get(q.UNITY_Proposal_Status__c).UNITY_Target_Value__c;
                                }else if(num > i){
                                    num = i;
                                    status = toStatusMap.get(q.UNITY_Proposal_Status__c).UNITY_Target_Value__c;
                                }
                            }
                        }
                    }//End for order
                    System.debug('===== Work Order Status: ' + woStatus);
                    System.debug('===== New Status: ' + status);
                    if((!noOverwrite.contains(woStatus)) && String.isNotBlank(status)){
                        wosMap.get(key).Status = status;
                        if(!wosMap.get(key).UNITY_MultiTrip_Actual__c && status == 'Pending Re-Dispatch')
                            wosMap.get(key).Status = 'In Progress';
                        //wosMap.get(key).SFPS_FS_AllTasks_Completed__c = null;
                        //wosMap.get(key).UNITY_Next_Step__c = null;
                        //if status == 'Pending Re-Dispatch'
                        woToUpdate.add(wosMap.get(key));
                    }
                }
            }//End for work orders map
            if(woToUpdate.size() > 0){
                try{
                    update woToUpdate;
                }catch(Exception e){
                    trigger.new[0].addError('An error occurred while updating the work order status. Error: ' + e.getMessage());
                }
            }//End if to updates
        }//End woIds.size
    }
}