trigger PartsOrderAll on SVMXC__RMA_Shipment_Order__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    if (trigger.isBefore)
        checkLocked();
    
    if ((trigger.isBefore) && (trigger.isInsert))
        updatePartsOrder();
    
    if ((trigger.isAfter) && (trigger.isUpdate || trigger.isInsert)){
        PartsOrderTriggerHandlerHelper.ValidateTechManageInventory(trigger.newmap,trigger.oldMap);
    }
    
    
    public void updatePartsOrder(){
        
        String uid = UserInfo.getUserId();
        ID UserID = UserInfo.getUserID();
        
        for (SVMXC__RMA_Shipment_Order__c ord : trigger.new) {
            ord.Buyer__c = UserID;
        }
        
        List<SVMXC__Service_Group_Members__c> tlist = new List<SVMXC__Service_Group_Members__c>();
        SVMXC__Service_Group_Members__c t = null;
        tlist = [SELECT Id, SVMXC__Service_Group__c, SVMXC__Service_Group__r.Name, SVMXC__Inventory_Location__c  FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Salesforce_User__c =: uid ];
        if (tlist.size() != 0)
            t = tlist.get(0);
        
        if (t != null){
            List<Bill_To_Accounts__c> btclist = new List<Bill_To_Accounts__c>();
            btclist = [SELECT Id, Account_ID__c FROM Bill_To_Accounts__c WHERE Service_Team__c =: t.SVMXC__Service_Group__r.Name];
            if (btclist.size() > 0){
                for (SVMXC__RMA_Shipment_Order__c index : trigger.new)
                    index.Internal_Bill_To__c = btclist.get(0).Account_ID__c; 
            }
            if (t.SVMXC__Inventory_Location__c != null){
                for (SVMXC__RMA_Shipment_Order__c index2 : trigger.new)
                    index2.SVMXC__Destination_Location__c = t.SVMXC__Inventory_Location__c;
            }
        }
        
    }
    
    public void checkLocked(){
        
        List<sObject> solist = new List<sObject>();
        if (trigger.isDelete)
            soList = trigger.Old;
        else
            solist = trigger.New;
        
        lockedClass.checkL(solist, 'SVMXC__Service_Order__c', 'SVMXC__Service_Order__c', 'Locked__c');
        
    }
    
}