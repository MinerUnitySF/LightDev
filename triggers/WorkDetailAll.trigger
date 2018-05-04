trigger WorkDetailAll on SVMXC__Service_Order_Line__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    if (trigger.isBefore) {
        checkLocked();
        
        if (trigger.isInsert) {
            updateWorkDetail();
            getVendor();
        }
        
        WorkDetailTriggerHandler.before(trigger.new, trigger.oldMap);
    }
    
    if ((trigger.isAfter) && ((trigger.isUpdate) || (trigger.isInsert))){
        inventoryRelief();
        //updatePOL();
        
    }
    if(trigger.isAfter){
        if(!trigger.isDelete)
            WorkDetailTriggerHandler.after(trigger.new, trigger.oldMap);
    }
    
    //updates related parts order lines to complete when the work detail is completed.
    public void updatePOL(){
        Set<Id> helpSet = new Set<Id>();
        List<SVMXC__Service_Order_Line__c> helpList = new List<SVMXC__Service_Order_Line__c>();
        //list<SVMXC__Service_Order_Line__c> completedWOD = [Select ID, SVMXC__Line_Status__c, SVMXC__Billable_Quantity__c  FROM SVMXC__Service_Order_Line__c Where ID in :trigger.new AND SVMXC__Line_Status__c = 'Completed'];
        Map<ID, SVMXC__Service_Order_Line__c> CompleteWODmap = new Map<ID, SVMXC__Service_Order_Line__c>([Select ID, SVMXC__Line_Status__c, SVMXC__actual_Quantity2__c  FROM SVMXC__Service_Order_Line__c Where ID in :trigger.new AND SVMXC__Line_Status__c = 'Completed']);
        if(!completeWODmap.isEmpty()){
            list<SVMXC__RMA_Shipment_Line__c> POL = [select ID, SVMXC__Line_Status__c, SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c, SVMXC__Service_Order_line__c FROM SVMXC__RMA_Shipment_Line__c Where SVMXC__Service_Order_line__c in :CompleteWODmap.keyset() AND SVMXC__Line_status__c not in ('completed','cancelled')];
            if (POL.Size() > 0){
                for(SVMXC__RMA_Shipment_Line__c rsl : POL ){
                    if (rsl.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c != null){
                        rsl.SVMXC__Line_Status__c = 'completed';
                        rsl.SVMXC__Actual_Quantity2__c = CompleteWODmap.get(rsl.SVMXC__Service_Order_line__c).SVMXC__actual_Quantity2__c;
                    }
                        
                    else{
                        helpSet.add(rsl.SVMXC__Service_Order_line__c);
                        //SVMXC__Service_Order_Line__c wo = Trigger.oldMap.get(POL[i].SVMXC__Service_Order_line__c);
                        //wo.addError('Please set the Destination Location prior to closing parts lines');
                    }
                }
            }
            update POL;
        }
        
        helpList = [SELECT Id FROM SVMXC__Service_Order_Line__c WHERE Id IN : helpSet];
        for (SVMXC__Service_Order_Line__c wo : helplist){
            SVMXC__Service_Order_Line__c actualRecord = trigger.newMap.get(wo.Id);
            actualrecord.addError('Please set the Destination Location prior to closing parts lines');
        }
        
    }
    
    // check the value of the locked field on the work order to determine if the work detail can be modified
    public void checkLocked() {
        /*
         * if (trigger.isDelete){
         for (SVMXC__Service_Order_Line__c wod : trigger.old)
             trigger.oldMap.get(wod.Id).addError('Work Order is Locked because an approval process has begun. Records cannot be created, edited or deleted');
        }
        */
        set<Id> parentIDSet = new Set<Id>();
        map<String, Boolean> parentMap = new Map<String, Boolean>();
        if (trigger.isDelete){
            for (SVMXC__Service_Order_Line__c wod : trigger.old)
                parentIDSet.add(wod.SVMXC__Service_Order__c);
            
            for (SVMXC__Service_Order__c wo : [SELECT Id, Locked__c FROM SVMXC__Service_Order__c WHERE Id in :parentIDSet]) 
                parentMap.put(wo.Id, wo.Locked__c);

            for(SVMXC__Service_Order_Line__c wod : trigger.old) {
                if (parentMap.get(wod.SVMXC__Service_Order__c))
                    wod.addError('Work Order is Locked because an approval process has begun. Records cannot be created, edited or deleted');
            }
        }
        else{
            for (SVMXC__Service_Order_Line__c wod : trigger.new)
                parentIDSet.add(wod.SVMXC__Service_Order__c); 
            
            for (SVMXC__Service_Order__c wo : [SELECT Id, Locked__c FROM SVMXC__Service_Order__c WHERE Id in :parentIDSet])
                parentMap.put(wo.Id, wo.Locked__c);
        
            for(SVMXC__Service_Order_Line__c wod : trigger.new) {
                if (parentMap.get(wod.SVMXC__Service_Order__c))
                    wod.addError('Work Order is Locked because an approval process has begun. Records cannot be created, edited or deleted');
            }
        }
        
    }    
    
    public void updateWorkDetail(){
        
        Set<Id> wset = new Set<Id>();
        for (SVMXC__Service_Order_Line__c wd : trigger.new)
            wset.add(wd.SVMXC__Service_Order__c);
        
        List<SVMXC__Service_Order__c> wlist = new List<SVMXC__Service_Order__c>();
        Map<Id, Id> wmap = new Map<Id, Id>();
        wlist = [SELECT Id, SVMXC__Group_Member__r.SVMXC__Inventory_Location__c FROM SVMXC__Service_Order__c WHERE Id IN : wset AND (Business_Unit__c = 'Miner Corp' OR Business_Unit__c = 'National Maintenance Services')];
        
        Set<Id> wset2 = new Set<Id>();
        for (SVMXC__Service_Order__c windex : wlist){
            wset2.add(windex.Id);
            if (windex.SVMXC__Group_Member__c != null)
                wmap.put(windex.Id, windex.SVMXC__Group_Member__r.SVMXC__Inventory_Location__c);
        }
        
        Set<Id> tset = new Set<Id>();
        for (SVMXC__Service_Order_Line__c wd : trigger.new){
            if (wd.SVMXC__Service_Order__c != null){
                if ((wd.SVMXC__Line_Type__c == 'Parts') && (wd.SVMXC__Consumed_From_Location__c == null) && (wd.Non_Inventory_Part__c == false) 
                   && (wset2.contains(wd.SVMXC__Service_Order__c)) && (wmap.containsKey(wd.SVMXC__Service_Order__c)))
                    wd.SVMXC__Consumed_From_Location__c = wmap.get(wd.SVMXC__Service_Order__c);
            }
        }
        
    }

    public void getVendor(){
        
        String rtid = [Select Id From RecordType  Where SobjectType = 'SVMXC__Service_Order__c' and DeveloperName = 'TFS'].id;
        system.debug('RecTypeID: ' + rtid);
        
        Set<Id> wset = new Set<Id>();
        for (SVMXC__Service_Order_Line__c wd : trigger.new)
            wset.add(wd.SVMXC__Service_Order__c);
            
        List<SVMXC__Service_Order__c> wlist = new List<SVMXC__Service_Order__c>();
        wlist = [SELECT Id, Vendor_Name_c__c FROM SVMXC__Service_Order__c WHERE Id IN : wset AND RecordTypeId =: rtid AND Business_Unit__c = 'Total Fleet Solutions'];
        
        Map<Id, Id> wmap = new Map<Id, Id>();
        for (SVMXC__Service_Order__c windex : wlist) {
            system.debug('WD working: ' + windex.Id);
            wmap.put(windex.Id, windex.Vendor_Name_c__c);
        }
            
        for (SVMXC__Service_Order_Line__c wd : trigger.new){
            if (wmap.containsKey(wd.SVMXC__Service_Order__c))
                wd.Vendor__c = wmap.get(wd.SVMXC__Service_Order__c);
        }
    }
    
    public void inventoryRelief(){
        
        if (checkRecursive.runOnce()){
            
            String rtid = [Select Id From RecordType  Where SobjectType = 'SVMXC__Stock_History__c' and DeveloperName = 'Stock_History'].id;
            
            Set<Id> wdset = new Set<Id>();
            for (SVMXC__Service_Order_Line__c wdindex : trigger.new){
                if ((wdindex.SVMXC__Line_Type__c == 'Parts') && (wdindex.Non_Inventory_Part__c == false)){
                    if (((trigger.isInsert) && (wdindex.Invoice_Detail__c != null)) || ((trigger.isUpdate) && (wdindex.Invoice_Detail__c != null) && (trigger.oldMap.get(wdindex.Id).Invoice_Detail__c == null)))
                        wdset.add(wdindex.Id);
                }
            }
            
            Set<Id> lset = new Set<Id>();
            Set<Id> pset = new Set<Id>();
            List<SVMXC__Service_Order_Line__c> wdlist = new List<SVMXC__Service_Order_Line__c>();
            wdlist = [SELECT Id, SVMXC__Product__c, SVMXC__Product__r.SVMXC__Stockable__c, SVMXC__Consumed_From_Location__c, SVMXC__Actual_Quantity2__c,SVMXC__Posted_To_Inventory__c, SVMXC__Service_Order__c  FROM SVMXC__Service_Order_Line__c WHERE Id IN : wdset];
            for (SVMXC__Service_Order_Line__c wdindex : wdlist){
                if (wdindex.SVMXC__Product__c != null){
                    if ((wdindex.SVMXC__Product__r.SVMXC__Stockable__c == true) && (wdindex.SVMXC__Posted_To_Inventory__c == false)){
                        lset.add(wdindex.SVMXC__Consumed_From_Location__c);
                        pset.add(wdindex.SVMXC__Product__c);
                    }
                }
            }
            
            List<SVMXC__Product_Stock__c> pslist = new List<SVMXC__Product_Stock__c>();
            pslist = [SELECT Id, SVMXC__Location__c, SVMXC__Product__c, SVMXC__Status__c, SVMXC__Quantity2__c FROM SVMXC__Product_Stock__c WHERE SVMXC__Location__c IN : lset AND SVMXC__Product__c IN : pset AND (SVMXC__Status__c = 'Available' OR SVMXC__Status__c = 'Consumed')];
            
            List<SVMXC__Product_Stock__c> updatelist = new List<SVMXC__Product_Stock__c>();
            List<SVMXC__Product_Stock__c> insertlist = new List<SVMXC__Product_Stock__c>();
            Boolean a, c;
            List<SVMXC__Stock_History__c> shlist = new List<SVMXC__Stock_History__c>();
            for (SVMXC__Service_Order_Line__c wdindex : wdlist){
                if ((wdindex.SVMXC__Product__c != null) && (wdindex.SVMXC__Product__r.SVMXC__Stockable__c == true) && (wdindex.SVMXC__Posted_To_Inventory__c == false)){
                    a = false;
                    c = false;
                    for (SVMXC__Product_Stock__c psindex : pslist){
                        if ((psindex.SVMXC__Location__c == wdindex.SVMXC__Consumed_From_Location__c) && (psindex.SVMXC__Product__c == wdindex.SVMXC__Product__c) && (psindex.SVMXC__Status__c == 'Available')){
                            a = true;
                            if (psindex.SVMXC__Quantity2__c == null)
                                psindex.SVMXC__Quantity2__c = 0;
                            if (wdindex.SVMXC__Actual_Quantity2__c != null){
                                SVMXC__Stock_History__c sh = new SVMXC__Stock_History__c(RecordTypeId = rtid, SVMXC__Product_Stock__c = psindex.Id, SVMXC__Product__c = wdindex.SVMXC__Product__c,
                                                             SVMXC__Location__c = wdindex.SVMXC__Consumed_From_Location__c, SVMXC__Changed_By__c = userInfo.getUserId(), SVMXC__Date_Changed__c = dateTime.now(),
                                                             SVMXC__Status__c = 'Available', SVMXC__Quantity_before_change2__c = psindex.SVMXC__Quantity2__c, SVMXC__Transaction_Quantity2__c = wdindex.SVMXC__Actual_Quantity2__c,
                                                             SVMXC__Quantity_after_change2__c = psindex.SVMXC__Quantity2__c - wdindex.SVMXC__Actual_Quantity2__c, SVMXC__Service_Order__c = wdindex.SVMXC__Service_Order__c,
                                                             SVMXC__Service_Order_Line__c = wdindex.Id);
                                shlist.add(sh);
                                psindex.SVMXC__Quantity2__c -= wdindex.SVMXC__Actual_Quantity2__c;
                                updatelist.add(psindex);
                            }
                            
                        }
                        if ((psindex.SVMXC__Location__c == wdindex.SVMXC__Consumed_From_Location__c) && (psindex.SVMXC__Product__c == wdindex.SVMXC__Product__c) && (psindex.SVMXC__Status__c == 'Consumed')){
                            c = true;
                            if (psindex.SVMXC__Quantity2__c == null)
                                psindex.SVMXC__Quantity2__c = 0;
                            if (wdindex.SVMXC__Actual_Quantity2__c != null){
                                SVMXC__Stock_History__c sh = new SVMXC__Stock_History__c(RecordTypeId = rtid, SVMXC__Product_Stock__c = psindex.Id, SVMXC__Product__c = wdindex.SVMXC__Product__c,
                                                             SVMXC__Location__c = wdindex.SVMXC__Consumed_From_Location__c, SVMXC__Changed_By__c = userInfo.getUserId(), SVMXC__Date_Changed__c = dateTime.now(),
                                                             SVMXC__Status__c = 'Consumed', SVMXC__Quantity_before_change2__c = psindex.SVMXC__Quantity2__c, SVMXC__Transaction_Quantity2__c = wdindex.SVMXC__Actual_Quantity2__c,
                                                             SVMXC__Quantity_after_change2__c = psindex.SVMXC__Quantity2__c + wdindex.SVMXC__Actual_Quantity2__c, SVMXC__Service_Order__c = wdindex.SVMXC__Service_Order__c,
                                                             SVMXC__Service_Order_Line__c = wdindex.Id);
                                shlist.add(sh);
                                psindex.SVMXC__Quantity2__c += wdindex.SVMXC__Actual_Quantity2__c;
                                updatelist.add(psindex);
                            }
                        }
                    }
                    if (a== false){
                        SVMXC__Product_Stock__c ps = new SVMXC__Product_Stock__c(SVMXC__Location__c = wdindex.SVMXC__Consumed_From_Location__c, SVMXC__Product__c = wdindex.SVMXC__Product__c, SVMXC__Status__c = 'Available',
                                                     SVMXC__Quantity2__c = 0 - wdindex.SVMXC__Actual_Quantity2__c);
                        insertlist.add(ps);
                    }
                    if (c == false){
                        SVMXC__Product_Stock__c ps = new SVMXC__Product_Stock__c(SVMXC__Location__c = wdindex.SVMXC__Consumed_From_Location__c, SVMXC__Product__c = wdindex.SVMXC__Product__c, SVMXC__Status__c = 'Consumed',
                                                     SVMXC__Quantity2__c = wdindex.SVMXC__Actual_Quantity2__c);
                        insertlist.add(ps);
                    }
                    
                }
            }
            
            update updatelist;
            insert insertlist;
            
            for (SVMXC__Service_Order_Line__c wdindex : wdlist){
                if ((wdindex.SVMXC__Product__c != null) && (wdindex.SVMXC__Product__r.SVMXC__Stockable__c == true) && (wdindex.SVMXC__Posted_To_Inventory__c == false) && (wdindex.SVMXC__Actual_Quantity2__c != null)){
                    for (SVMXC__Product_Stock__c psindex : insertlist){
                        if ((psindex.SVMXC__Location__c == wdindex.SVMXC__Consumed_From_Location__c) && (psindex.SVMXC__Product__c == wdindex.SVMXC__Product__c) && (psindex.SVMXC__Status__c == 'Available')){
                            SVMXC__Stock_History__c sh = new SVMXC__Stock_History__c(RecordTypeId = rtid, SVMXC__Product_Stock__c = psindex.Id, SVMXC__Product__c = wdindex.SVMXC__Product__c,
                                                             SVMXC__Location__c = wdindex.SVMXC__Consumed_From_Location__c, SVMXC__Changed_By__c = userInfo.getUserId(), SVMXC__Date_Changed__c = dateTime.now(),
                                                             SVMXC__Status__c = 'Available', SVMXC__Quantity_before_change2__c = 0, SVMXC__Transaction_Quantity2__c = wdindex.SVMXC__Actual_Quantity2__c,
                                                             SVMXC__Quantity_after_change2__c = psindex.SVMXC__Quantity2__c , SVMXC__Service_Order__c = wdindex.SVMXC__Service_Order__c,
                                                             SVMXC__Service_Order_Line__c = wdindex.Id);
                            shlist.add(sh);
                        }
                        if ((psindex.SVMXC__Location__c == wdindex.SVMXC__Consumed_From_Location__c) && (psindex.SVMXC__Product__c == wdindex.SVMXC__Product__c) && (psindex.SVMXC__Status__c == 'Consumed')){
                            SVMXC__Stock_History__c sh = new SVMXC__Stock_History__c(RecordTypeId = rtid, SVMXC__Product_Stock__c = psindex.Id, SVMXC__Product__c = wdindex.SVMXC__Product__c,
                                                             SVMXC__Location__c = wdindex.SVMXC__Consumed_From_Location__c, SVMXC__Changed_By__c = userInfo.getUserId(), SVMXC__Date_Changed__c = dateTime.now(),
                                                             SVMXC__Status__c = 'Consumed', SVMXC__Quantity_before_change2__c = 0, SVMXC__Transaction_Quantity2__c = wdindex.SVMXC__Actual_Quantity2__c,
                                                             SVMXC__Quantity_after_change2__c = psindex.SVMXC__Quantity2__c , SVMXC__Service_Order__c = wdindex.SVMXC__Service_Order__c,
                                                             SVMXC__Service_Order_Line__c = wdindex.Id);
                            shlist.add(sh);
                        }
                    }
                }
                wdindex.SVMXC__Posted_To_Inventory__c = true;

            }
            
            insert shlist;
            update wdlist;
            
        }
            
    }

}