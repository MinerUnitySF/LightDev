trigger PartsOrderDetailAll on SVMXC__RMA_Shipment_Line__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    if (trigger.isBefore)
        checkLocked();
    
    Set<Id> RMAShipmentInsertIds = new Set<Id>();
    
    Set<Id> RMAShipment_VendorPrice_Ids = new Set<Id>();
    Set<Id> RMAShipment_ExpectedQuantity_Ids = new Set<Id>();
    Set<Id> RMAShipment_LineStatus_Ids = new Set<Id>();
    Set<ID> resetWOLAttach = new Set<ID>();
    
    if(trigger.isAfter) {
        if(trigger.isInsert) {
            for(SVMXC__RMA_Shipment_Line__c rmas: Trigger.New){
                if(rmas.SVMXC__RMA_Shipment_Order__c != null && rmas.WOL_Attach__c == false)
                    RMAShipmentInsertIds.add(rmas.Id);
                if(rmas.SVMXC__RMA_Shipment_Order__c != null && rmas.WOL_Attach__c == true)
                    resetWOLAttach.add(rmas.Id);
            }
            if(RMAShipmentInsertIds.size() > 0) {
                CreateWorkDetail(RMAShipmentInsertIds);
            }
            if(resetWOLAttach.size() > 0){
                resetWOL(resetWOLAttach);
            }
        }
        
        if(trigger.isUpdate) {
            
            for(SVMXC__RMA_Shipment_Line__c rmas: Trigger.New){
                SVMXC__RMA_Shipment_Line__c oldRMAShipmentLine = Trigger.oldMap.get(rmas.ID);
                if(rmas.Vendor_Price__c != oldRMAShipmentLine.Vendor_Price__c)
                    RMAShipment_VendorPrice_Ids.add(rmas.Id);
                if(rmas.SVMXC__Expected_Quantity2__c != oldRMAShipmentLine.SVMXC__Expected_Quantity2__c)
                    RMAShipment_ExpectedQuantity_Ids.add(rmas.Id);
                if(rmas.SVMXC__Actual_Quantity2__c != oldRMAShipmentLine.SVMXC__Actual_Quantity2__c && rmas.SVMXC__Line_Status__c != oldRMAShipmentLine.SVMXC__Line_Status__c && rmas.SVMXC__Line_Status__c == 'Completed')
                    RMAShipment_LineStatus_Ids.add(rmas.Id);
            }
            if(RMAShipment_VendorPrice_Ids.size() > 0 || RMAShipment_ExpectedQuantity_Ids.size() > 0 || RMAShipment_LineStatus_Ids.size() > 0) {
                UpdateWorkDetail(RMAShipment_VendorPrice_Ids, RMAShipment_ExpectedQuantity_Ids, RMAShipment_LineStatus_Ids);
            }
        }
    }
    
    public void resetWOL(Set<ID> resetWOL){
        list<SVMXC__RMA_Shipment_Line__c> POL = [SELECT ID, WOL_Attach__c FROM SVMXC__RMA_Shipment_Line__c where ID in :resetWOL];
        for(SVMXC__RMA_Shipment_Line__c r : POL){
            r.WOL_Attach__c = false;
        }
        update POL;
    }
    
    public void UpdateWorkDetail(Set<Id> rmasVDIds, Set<Id> rmasEQIds, Set<Id> rmasLSCIds) {
        Set<Id> polIds = new Set<Id>();//hold all the ids passed to the method
        //Add all the ids to the one set to query all needed records at once
        if(!rmasVDIds.isEmpty())
            polIds.addAll(rmasVDIds);
        if(!rmasEQIds.isEmpty())
            polIds.addAll(rmasEQIds);
        if(!rmasLSCIds.isEmpty())
            polIds.addAll(rmasLSCIds);
        //If polIds is not empty...
        if(!polIds.isEmpty()){
            //Need to query all the PO Lines
            Map<Id,SVMXC__RMA_Shipment_Line__c> shippmentLinesMap = new Map<Id,SVMXC__RMA_Shipment_Line__c>([SELECT Id,Vendor_Price__c,SVMXC__Expected_Quantity2__c,SVMXC__Actual_Quantity2__c FROM SVMXC__RMA_Shipment_Line__c WHERE Id IN :polIds]);
            //Need to query the work detail lines that this
            List<SVMXC__Service_Order_Line__c> workDetails = [SELECT Id,Parts_Order_Line__c,Vendor_Cost_Per_Unit__c,SVMXC__Actual_Quantity2__c,SVMXC__Line_Status__c FROM SVMXC__Service_Order_Line__c WHERE Parts_Order_Line__c IN :polIds];
            if(!workDetails.isEmpty()){
                //Now, update the work detail line with values from PO
                for(SVMXC__Service_Order_Line__c wdl :workDetails){
                    if(!rmasVDIds.isEmpty()){
                        if(rmasVDIds.contains(wdl.Parts_Order_Line__c) && shippmentLinesMap.containsKey(wdl.Parts_Order_Line__c))
                            wdl.Vendor_Cost_Per_Unit__c = shippmentLinesMap.get(wdl.Parts_Order_Line__c).Vendor_Price__c;
                    }
                    if(!rmasEQIds.isEmpty()){
                        if(rmasEQIds.contains(wdl.Parts_Order_Line__c) && shippmentLinesMap.containsKey(wdl.Parts_Order_Line__c))
                            wdl.SVMXC__Actual_Quantity2__c = shippmentLinesMap.get(wdl.Parts_Order_Line__c).SVMXC__Expected_Quantity2__c;
                    }
                    if(!rmasLSCIds.isEmpty()){
                        if(rmasLSCIds.contains(wdl.Parts_Order_Line__c) && shippmentLinesMap.containsKey(wdl.Parts_Order_Line__c)){
                            wdl.SVMXC__Actual_Quantity2__c = shippmentLinesMap.get(wdl.Parts_Order_Line__c).SVMXC__Actual_Quantity2__c;
                            wdl.SVMXC__Line_Status__c = 'Completed';
                        }
                    }
                }
                //save the changes
                try{
                    update workDetails;
                }catch(Exception e){
                    Trigger.new[0].addError(e.getMessage());
                }
            }
        }
    }
    
    public void CreateWorkDetail(Set<Id> rmasIds) {
        
        Id UsageRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'SVMXC__Service_Order_Line__c' And DeveloperName='UsageConsumption'].Id;
        
        List<SVMXC__RMA_Shipment_Line__c> shippmentLines = [SELECT Id, SVMXC__RMA_Shipment_Order__c, SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c, SVMXC__RMA_Shipment_Order__r.Vendor__c, SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.Super_Center__c, SVMXC__Service_Order__c, SVMXC__Service_Order__r.Super_Center__c, SVMXC__Product__c, SVMXC__Expected_Quantity2__c, Vendor_Price__c FROM SVMXC__RMA_Shipment_Line__c WHERE Id IN: rmasIds AND SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c != null];

        Set<String> SuperCenterSet = new Set<String>();
        
        for(SVMXC__RMA_Shipment_Line__c rsl: shippmentLines)
            SuperCenterSet.add(rsl.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.Super_Center__c);
        List<Pricebook2> customPriceBookList = [SELECT Id, Name FROM Pricebook2 WHERE Name IN: SuperCenterSet];
        Map<String, String> customPriceBookMap = new Map<String, String>();
        for(Pricebook2 pb2: customPriceBookList) {
            if(!customPriceBookMap.containsKey(pb2.Name)){
                customPriceBookMap.put(pb2.Name, pb2.Id);
            }
        }

        Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        
        List<SVMXC__Service_Order_Line__c> ServiceOrderLines = new List<SVMXC__Service_Order_Line__c>();
        for(SVMXC__RMA_Shipment_Line__c rs: shippmentLines) {

            SVMXC__Service_Order_Line__c ServiceOrder = new SVMXC__Service_Order_Line__c();
            ServiceOrder.SVMXC__Service_Order__c = rs.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c;
            ServiceOrder.SVMXC__Line_Status__c = 'Open';
            ServiceOrder.SVMXC__Line_Type__c = 'Vendor Services';
            ServiceOrder.SVMXC__Activity_Type__c = 'Parts - Service and Remodel';
            ServiceOrder.SVMXC__Product__c = rs.SVMXC__Product__c;
            
            ServiceOrder.SVMXC__Actual_Quantity2__c = rs.SVMXC__Expected_Quantity2__c;
            ServiceOrder.Vendor_Cost_Per_Unit__c = rs.Vendor_Price__c;
            ServiceOrder.Vendor__c = rs.SVMXC__RMA_Shipment_Order__r.Vendor__c;
            ServiceOrder.Parts_Order_Line__c = rs.Id;
            ServiceOrder.RecordTypeId = UsageRecordType;
            
            PricebookEntry pe = null;
            if(rs.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.Super_Center__c != null) {
                String customPriceBookId = customPriceBookMap.get(rs.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.Super_Center__c);
                if(!String.isEmpty(customPriceBookId)) {
                    try {
                        pe = [SELECT Id, Pricebook2Id, UnitPrice, Cost__c FROM PricebookEntry WHERE Pricebook2Id =: customPriceBookId AND Product2Id =: rs.SVMXC__Product__c LIMIT 1];
                    } catch (Exception ex) { }
                }
            }
            if (pe == null) {
                try {
                    pe = [SELECT Id, Pricebook2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id =: standardPriceBook.Id AND Product2Id =: rs.SVMXC__Product__c LIMIT 1];
                } catch (Exception ex) { }
            }
            if (pe != null) {
                ServiceOrder.SVMXC__Actual_Price2__c = pe.UnitPrice;
            } 
            
            ServiceOrderLines.add(ServiceOrder);
        }

        if(ServiceOrderLines.size() > 0) 
            insert ServiceOrderLines;
    }
     
    public void checkLocked(){
        
        List<sObject> solist = new List<sObject>();
        if (trigger.isDelete)
            soList = trigger.Old;
        else
            solist = trigger.New;
            
        lockedClass.checkL(solist, 'SVMXC__Service_Order__c', 'SVMXC__Service_Order__c', 'Locked__c');
        
    }
    
    // check to see if a work detail is expected and present
    public boolean checkWL(){
        boolean result = false;
        // get work order from parent PO
        list<ID> woIDList = new list<ID>();
        for(SVMXC__RMA_Shipment_Line__C pol : trigger.new){
            if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c != null){
                woIDList.add(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c);
                system.debug('Added WOID to list::' + pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c );
            }
        }
        // no work order is associated with the parent PO, no need to continue
        if(woIDList.size() == 0)
            return false;
        
        // Get Work Details associated with the PO Line
        list<SVMXC__Service_Order_Line__c> wdList = new list<SVMXC__Service_Order_Line__c>([SELECT ID, name FROM SVMXC__Service_Order_Line__c WHERE Parts_Order_Line__c in :trigger.new]);
        
        return result;
    }

}