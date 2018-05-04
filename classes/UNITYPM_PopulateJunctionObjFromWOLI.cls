global class UNITYPM_PopulateJunctionObjFromWOLI implements Database.Batchable<sObject> {
  
    global Database.QueryLocator start(Database.BatchableContext BC) {
       
        String query = 'SELECT  UNITY_Work_Plan__c, WorkOrderId, AssetId, UNITY_PM_WOLI__c FROM WorkOrderLineItem where UNITY_PM_WOLI__c = true  and UNITY_Work_Plan__c != null and AssetId != null';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<WorkOrderLineItem> woliList) {    
        List<UNITYPM_Work_Order_Assets_junction__c> woAwp = new List<UNITYPM_Work_Order_Assets_junction__c>();
        Map<id,Map<id,id>> ao = new Map<id,Map<id,id>>();
        
        for(WorkOrderLineItem woli : woliList)
        { 
            if(!ao.containskey(woli.WorkOrderId)) {             
                ao.put(woli.WorkOrderId,new map<id,id>());
              }
            else {             
              ao.get(woli.WorkOrderId).put(woli.AssetId,woli.UNITY_Work_Plan__c);
            }          
        }
        
        for(Id iw:ao.keyset()) {
           UNITYPM_Work_Order_Assets_junction__c item = new UNITYPM_Work_Order_Assets_junction__c(); 
            item.Work_Order__c = iw;            
            for(Id ia:ao.get(iw).keyset()) {               
               item.Asset__c = ia;
               ID iwp =ao.get(iw).get(ia); 
               item.Work_Plan__c = iwp;               
            } 
             woAwp.add(item);
        }
        
        try {
            if (woAwp.size() > 0)
                upsert woAwp;
         
        } catch(Exception e) {
            System.debug('>>>>   error >>>> ' + e);
        }         
    }   
     
    global void finish(Database.BatchableContext BC) {      
  }
}