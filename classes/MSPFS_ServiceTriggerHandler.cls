public with sharing class MSPFS_ServiceTriggerHandler extends UNITY_BaseHandler {

    public override void bulkBefore() {
        
        if(Trigger.isInsert){
            if(MSPFS_ServiceTriggerHandler.canSetDefault())
                setDefaultOnServiceRecord();
        }

        if ( Trigger.isUpdate ) {
            if(MSPFS_ServiceTriggerHandler.cancascadeTechnician())
                cascadeTechnicianAssignment();
            if(MSPFS_ServiceTriggerHandler.canSetDefault())
                setDefaultOnServiceRecord();
        }

    }

    private void cascadeTechnicianAssignment() {

        Map<Id, CKSW_BASE__Service__c> resourceChangeMap = new Map<Id, CKSW_BASE__Service__c>();
        Set<Id> resourceIdSet = new Set<Id>();
        for ( sObject sObj : Trigger.new ) {
            CKSW_BASE__Service__c service = (CKSW_BASE__Service__c)sObj;
            CKSW_BASE__Service__c oldService = (CKSW_BASE__Service__c) Trigger.oldMap.get( service.Id );
            if ( String.isNotBlank(service.CKSW_BASE__Resource__c) && service.CKSW_BASE__Resource__c != oldService.CKSW_BASE__Resource__c ) {
                resourceChangeMap.put( service.Id, service );
                resourceIdSet.add( service.CKSW_BASE__Resource__c );
            }
        }
        System.debug('#####Izay: resourceIdSet = ' + resourceIdSet.size());
        if (!resourceIdSet.isEmpty() ){

            Map<Id, CKSW_BASE__Resource__c> resourceMap = new Map<Id, CKSW_BASE__Resource__c>( [SELECT CKSW_BASE__User__c,CKSW_BASE__Location__c FROM CKSW_BASE__Resource__c WHERE Id IN: resourceIdSet] );

            List<WorkOrder> wOrders = new List<WorkOrder>(); 
            for ( WorkOrder wOrder : [SELECT Id, FSL_INTG__Service__c FROM WorkOrder WHERE FSL_INTG__Service__c IN: resourceChangeMap.keySet()]) {
                if( resourceChangeMap.containsKey(wOrder.FSL_INTG__Service__c) ){
                    CKSW_BASE__Service__c service = resourceChangeMap.get( wOrder.FSL_INTG__Service__c );
                    //Set the location on the service record if it is empty
                    if(String.isBlank(service.CKSW_BASE__Location__c))
                        service.CKSW_BASE__Location__c = resourceMap.get( service.CKSW_BASE__Resource__c ).CKSW_BASE__Location__c;

                    wOrder.UNITY_Primary_Technician__c = resourceMap.get( service.CKSW_BASE__Resource__c ).CKSW_BASE__User__c;

                    wOrders.add(wOrder);
                }
                    
            }

            if ( !wOrders.isEmpty() ){
                Database.update( wOrders, false );
            } 

        }else{
            MSPFS_ServiceTriggerHandler.cascadeTechnicianOnce = true;
        }
            
    }

    /**This method auto assigns NOT MSP wo to a bu default resopurce when the Tech ETA is populated oin the WO
    */
    public static void setDefaultOnServiceRecord(){
        Map<Id,List<CKSW_BASE__Service__c>> woServicesMap = new Map<Id,List<CKSW_BASE__Service__c>>();//Map of woId to Service Id
        for(SObject obj :Trigger.new){
            CKSW_BASE__Service__c serv = (CKSW_BASE__Service__c)obj;
            if(!woServicesMap.containsKey(serv.FSL_INTG__Work_Order__c))
                woServicesMap.put(serv.FSL_INTG__Work_Order__c, new List<CKSW_BASE__Service__c>());
            woServicesMap.get(serv.FSL_INTG__Work_Order__c).add(serv);
        }
        if(!woServicesMap.keySet().isEmpty()){
            //Need to get the work orders...
            List<WorkOrder> workOrders = [SELECT Id,UNITY_Business_Unit_Account__c,FSL_INTG__Service__c,StartDate,EndDate,UNITY_Work_Window_End__c,
                                          MSPFS_Intercompany_Transfer__c,UNITY_Accepted_Vendor__c,UNITY_Accepted_Vendor__r.MSPFS_Is_MSP_BU__c
                                          FROM WorkOrder WHERE Id IN :woServicesMap.keySet() 
                                          AND RecordTypeId = :UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE
                                          AND Status != 'Cancelled'];
            if(!workOrders.isEmpty()){
                Set<Id> buids = new Set<Id>();
                for(WorkOrder wo :workOrders){
                    buids.add(wo.UNITY_Business_Unit_Account__c);
                    if(String.isNotBlank(wo.UNITY_Accepted_Vendor__c))
                        buids.add(wo.UNITY_Accepted_Vendor__c);
                }
                //Now, need to get all Not Is MSP BUs in the buServiceMap
                Map<Id,Account> buMap = new Map<Id,Account>([SELECT Id,MSPFS_Is_MSP_BU__c,
                                                            (SELECT Id FROM BusinessUnitLocations__r LIMIT 1) 
                                                            FROM Account WHERE Id IN :buids AND RecordTypeId = :UNITY_Constants.ACCOUNT_MINER_RECORDTYPE]);
                //Now need to get the defaul technician per bu account
                List<CKSW_BASE__Resource__c> resources = [SELECT Id,MSPFS_BU_Default_Resource__c,MSPFS_BU_Account_Id__c,CKSW_BASE__Location__c 
                                                          FROM CKSW_BASE__Resource__c WHERE MSPFS_BU_Account_Id__c IN :buids 
                                                          AND MSPFS_BU_Default_Resource__c = TRUE];
                //Put resource in map by BU Account Id
                Map<Id,CKSW_BASE__Resource__c> buDefaultResourceMap = new Map<Id,CKSW_BASE__Resource__c>();
                if(!resources.isEmpty()){
                    for(CKSW_BASE__Resource__c res :resources){
                        buDefaultResourceMap.put(res.MSPFS_BU_Account_Id__c,res);
                    }
                }
                
                //Now, loop through the buServiceMap... 
                //if the buMap has the buid... this is not an MSP BU thus needs auto populate resource in service record
                List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
                for(WorkOrder wo :workOrders){
                    //If buMap has the work order busines unit account in it... it is not an msp bu and needs processing...
                    if(buMap.containsKey(wo.UNITY_Business_Unit_Account__c)){
                        if(!buMap.get(wo.UNITY_Business_Unit_Account__c).MSPFS_Is_MSP_BU__c && !wo.MSPFS_Intercompany_Transfer__c && 
                            buDefaultResourceMap.containsKey(wo.UNITY_Business_Unit_Account__c) && woServicesMap.containsKey(wo.Id)){
                                for(CKSW_BASE__Service__c serv :woServicesMap.get(wo.Id)){
                                    CKSW_BASE__Service__c oldServ = null;
                                    if(Trigger.isUpdate)
                                        oldServ = (CKSW_BASE__Service__c)Trigger.oldMap.get(serv.Id);
                                    if(Trigger.isInsert){
                                        if(serv.CKSW_BASE__Start__c != null && wo.StartDate != null){
                                            serv.CKSW_BASE__Start__c = wo.StartDate;
                                            serv.CKSW_BASE__Finish__c = wo.StartDate.addHours(1);
                                            serv.CKSW_BASE__Resource__c = buDefaultResourceMap.get(wo.UNITY_Business_Unit_Account__c).Id;
                                            serv.CKSW_BASE__Location__c = buDefaultResourceMap.get(wo.UNITY_Business_Unit_Account__c).CKSW_BASE__Location__c;
                                        }
                                    }else if(Trigger.isUpdate){
                                        if(serv.CKSW_BASE__Start__c != null && serv.CKSW_BASE__Start__c != oldServ.CKSW_BASE__Start__c && wo.StartDate != null){
                                            serv.CKSW_BASE__Start__c = wo.StartDate;
                                            serv.CKSW_BASE__Finish__c = wo.StartDate.addHours(1);
                                            serv.CKSW_BASE__Resource__c = buDefaultResourceMap.get(wo.UNITY_Business_Unit_Account__c).Id;
                                            serv.CKSW_BASE__Location__c = buDefaultResourceMap.get(wo.UNITY_Business_Unit_Account__c).CKSW_BASE__Location__c;
                                            wo.EndDate = wo.StartDate.addHours(1);
                                            workOrdersToUpdate.add(wo);
                                        }
                                        else if (serv.CKSW_BASE__Start__c == null && serv.CKSW_BASE__Start__c != oldServ.CKSW_BASE__Start__c){
                                            serv.CKSW_BASE__Finish__c = null;
                                            serv.CKSW_BASE__Resource__c = null;
                                            serv.CKSW_BASE__Location__c = null;
                                            wo.EndDate = null; 
                                            workOrdersToUpdate.add(wo);
                                        }
                                    }
                                }
                        }else if(String.isNotBlank(wo.UNITY_Accepted_Vendor__c) && buMap.containsKey(wo.UNITY_Accepted_Vendor__c) ){
                            if(buMap.get(wo.UNITY_Accepted_Vendor__c).MSPFS_Is_MSP_BU__c && !buMap.get(wo.UNITY_Business_Unit_Account__c).MSPFS_Is_MSP_BU__c){
                                if(!buMap.get(wo.UNITY_Accepted_Vendor__c).BusinessUnitLocations__r.isEmpty()){
                                    for(CKSW_BASE__Service__c serv :woServicesMap.get(wo.Id)){
                                        if(String.isEmpty(serv.CKSW_BASE__Location__c))
                                            serv.CKSW_BASE__Location__c = buMap.get(wo.UNITY_Accepted_Vendor__c).BusinessUnitLocations__r[0].Id;
                                    }
                                }
                            }
                        }else if(buMap.get(wo.UNITY_Business_Unit_Account__c).MSPFS_Is_MSP_BU__c){
                            if(!buMap.get(wo.UNITY_Business_Unit_Account__c).BusinessUnitLocations__r.isEmpty()){
                                for(CKSW_BASE__Service__c serv :woServicesMap.get(wo.Id)){
                                    if(String.isEmpty(serv.CKSW_BASE__Location__c))
                                        serv.CKSW_BASE__Location__c = buMap.get(wo.UNITY_Business_Unit_Account__c).BusinessUnitLocations__r[0].Id;
                                }
                            }
                        }
                    }
                }//End for workOrders
                System.debug('Izay: workOrdersToUpdate = ' + JSON.serializePretty(workOrdersToUpdate));
                if ( !workOrdersToUpdate.isEmpty() ) Database.update( workOrdersToUpdate, false );
            }
        }
    }

    public static Boolean setDefaultOnce = true;
    public static Boolean canSetDefault(){
        if(setDefaultOnce){
            setDefaultOnce = false;
            return true;
        }
        return setDefaultOnce;
    }

    public static Boolean cascadeTechnicianOnce = true;
    public static Boolean cancascadeTechnician(){
        if(cascadeTechnicianOnce){
            cascadeTechnicianOnce = false;
            return true;
        }
        return cascadeTechnicianOnce;
    }

}