/**UNITY_ProposalLineTriggerHandler_Miner
 * @description: Handles quote line item trigger actions developed by the Miner team 
 * @programer:   Izay Ramos-Irizarry
 * @date:        7/19/2016
 * @version:     1.0
 */
public class UNITY_ProposalLineTriggerHandler_Miner  extends UNITY_BaseHandler{
	
    public override void bulkBefore(){
        //System.debug('###### UNITY_WorkOrderTriggerHandler_Miner in bulkBefore: ');
        if(trigger.isInsert || trigger.isUpdate){
            //List of quote lines that need price book entry id
            List<UNITY_Proposal_Line_Item__c> needPBEId = new list<UNITY_Proposal_Line_Item__c>();
            for(UNITY_Proposal_Line_Item__c qLine :(List<UNITY_Proposal_Line_Item__c>)Trigger.new){
                //If the UNITY_PriceBookEntryId__c is blank...
                if(String.isNotBlank(qLine.UNITY_Product__c) && String.isBlank(qLine.UNITY_PriceBook_Entry_Id__c))
                    needPBEId.add(qLine);
            }
            if(!needPBEId.isEmpty())
                setPriceBookEntryId(needPBEId);
        }
        if(trigger.isUpdate){
            
        }//End if trigger.isUpdate
    }
    
    public static void setPriceBookEntryId(List<UNITY_Proposal_Line_Item__c> qLines){
        Set<Id> pids = new Set<Id>();
        Id spbId = UNITY_Constants.getStandardPriceBookId();
        System.debug('##### spbId: ' + spbId);
        for(UNITY_Proposal_Line_Item__c qLine :qLines){
            pids.add(qLine.UNITY_Product__c);
        }
        List<PriceBookEntry> pbEntries = [SELECT Id,Product2Id,PriceBook2Id FROM PriceBookEntry WHERE Product2Id IN :pids AND PriceBook2Id = :spbId];
        System.debug('##### pbEntries.size(): ' + pbEntries.size());
        Map<Id,Id> prodPBEMap = new Map<Id,Id>();
        for(PriceBookEntry pbe :pbEntries){
            prodPBEMap.put(pbe.Product2Id,pbe.Id);
        }
        for(UNITY_Proposal_Line_Item__c qLine :qLines){
            if(prodPBEMap.containsKey(qLine.UNITY_Product__c))
                qLine.UNITY_PriceBook_Entry_Id__c = prodPBEMap.get(qLine.UNITY_Product__c);
        }
    }
    
}