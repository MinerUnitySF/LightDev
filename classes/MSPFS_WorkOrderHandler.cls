/*------------------------------------------------------------
Name:           MSPFS_WorkOrderHandler 
Author:         Nicholas McBride/Izay Ramos/Dan Cobb
Company:        Miner
Description:    This class handles work order processes introduced for the MSPFS project.
                - updateWorkOrder(): Invocable method calles from a process definition to complete the auto acceptance of MSP WO's 
                - updateWorkOrders(): Auto accept and updates MSP BU's WO. Sets MSP BU's vendor service contract on WO
                - handleIntercompanyTransferSharing(): Handles the sharing of WO and POs with MSP when Asset Light BU's use MSP BU's as vendor
                - shareWorkOrdersWithBU(): Creates sharing records for WO, Service, and POs for the given BU/WO
                - populateTechnicianOnChildPOs(): Auto populates the Technician and Technician#2 fields on POs from the WO technician fields
                - validateWorkOrderWhenETAPopulated(): Validates quoted WO's to make sure thgat a quote has been accepted before the WO is dispatched
Date:           1/20/2017
=====================================================
Changelog
=====================================================
Developer:      Izay Ramos-Irizarry
Description:    Updated updateWorkOrders method to do the entire auto accept process
Date:           2/9/2017
=====================================================
------------------------------------------------------------*/
public class MSPFS_WorkOrderHandler {
    
    @InvocableMethod(label='MSPFS Auto Accept Work Order' description='Auto Accept Work Order when the Business Unit is MSP.')
    public static void updateWorkOrder(List<Id> WorkOrderIds){
        if(!System.isFuture())
            updateWorkOrders(WorkOrderIds);
    }
    
    //@future
    static void updateWorkOrders(List<Id> WorkOrderIds){
        List<WorkOrder> WorkOrders =[SELECT Id,AccountId,UNITY_Action__c,UNITY_Dispatch_Attempts__c,UNITY_Business_Unit__c,UNITY_Business_Unit_Account__c,
                                     UNITY_Trade__c,UNITY_Vendor_Last_Assigned__c,UNITY_Assigned_Vendor__c,UNITY_Accepted_Vendor__c,UNITY_Vendor_Status__c
                                     FROM WorkOrder 
                                     WHERE Id in :WorkOrderIds];

        if(!WorkOrders.isEmpty()){

            Set<Id> vendorAccountIds = new Set<Id>();
            Set<Id> vaIds = new Set<Id>();
            List<UNITY_Vendor_Assignment__c> vendorAssignments = new List<UNITY_Vendor_Assignment__c>();
            Map<Id,UNITY_Vendor_Assignment__c> woVAMap = new Map<Id,UNITY_Vendor_Assignment__c>();

            For(WorkOrder wo :WorkOrders){
                UNITY_Vendor_Assignment__c va = new UNITY_Vendor_Assignment__c(
                    Customer__c = wo.AccountId,
                    Work_Order__c = wo.Id,
                    Status__c = 'Assigned',
                    Request_Type__c = 'Service Request',
                    Trade__c = wo.UNITY_Trade__c,
                    Vendor__c = wo.UNITY_Business_Unit_Account__c,
                    Last_Assigned__c = UNITY_Utils.getDateTime()
                );
                vendorAssignments.add(va);
                vendorAccountIds.add(wo.UNITY_Business_Unit_Account__c);
            }
            
            try{
                insert vendorAssignments;
                for(UNITY_Vendor_Assignment__c va :vendorAssignments){
                    vaIds.add(va.Id);
                }
            }catch(Exception e){
                System.debug('Izay: Error while inserting vendor assignment = ' + e.getMessage());
                Throw e;
            }

            vendorAssignments = [SELECT Id,Customer__c,Status__c,Work_Order__c,Pin__c,UNITY_Vendor_Email__c,Vendor__c 
                                FROM UNITY_Vendor_Assignment__c WHERE Id IN :vaIds];
            
            for(UNITY_Vendor_Assignment__c va :vendorAssignments){
                woVAMap.put(va.Work_Order__c,va);
            }

            for(WorkOrder wo: WorkOrders){
                wo.UNITY_Vendor_Status__c = 'Assigned';
                wo.UNITY_Vendor_Last_Assigned__c = UNITY_Utils.getDateTime();
                wo.UNITY_Assigned_Vendor__c = wo.UNITY_Business_Unit_Account__c;
            }

            try{
                update WorkOrders;
                WorkOrders =[SELECT Id,AccountId,UNITY_Action__c,UNITY_Dispatch_Attempts__c,UNITY_Business_Unit__c,UNITY_Business_Unit_Account__c,
                                     UNITY_Trade__c,UNITY_Vendor_Last_Assigned__c,UNITY_Assigned_Vendor__c,UNITY_Accepted_Vendor__c,UNITY_Vendor_Status__c
                                     FROM WorkOrder 
                                     WHERE Id in :WorkOrderIds];
            }catch(Exception e){
                System.debug('Izay: Error while updating work order(s). Line[83] = ' + e.getMessage());
                Throw e;
            }

            //get vendor email and pin and populate
            //dispatch +1
     
            for(WorkOrder wo: WorkOrders){
                wo.UNITY_Vendor_Status__c = UNITY_Constants.WO_VENDOR_STATUS_ACCEPTED;
                wo.UNITY_Auto_Dispatch__c = false;
                wo.UNITY_WO_Retract_At__c = null;
                wo.UNITY_Accepted_Vendor__c = wo.UNITY_Assigned_Vendor__c;
                wo.UNITY_Vendor_Accept_Date__c = UNITY_Utils.getDateTime();
                wo.UNITY_Dispatch_Attempts__c = wo.UNITY_Dispatch_Attempts__c + 1;
                wo.UNITY_Vendor_PIN__c = woVAMap.get(wo.Id).Pin__c;
                wo.UNITY_Vendor_Email__c = woVAMap.get(wo.Id).UNITY_Vendor_Email__c;
                wo.Status = 'Pending Tech Dispatch';
                //Update the vendor assignment record
                woVAMap.get(wo.Id).Status__c = wo.UNITY_Vendor_Status__c;
            }
            
            //get service contracts
            //service contract is active? is service request type? 
            //Izay: Removed query. Use UNITY_Constant to find record type ids
            String rtidSC = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
                /*[SELECT Id FROM RecordType WHERE SObjectType = 'UNITY_Service_Contract__c' AND Name = 'Service Request' LIMIT 1].Id;*/        
            List<UNITY_Service_Contract__c> serviceContract = [SELECT Name, UNITY_Business_Unit__c, UNITY_Account__c
                                                               FROM UNITY_Service_Contract__c 
                                                               WHERE UNITY_Account__c = :vendorAccountIds 
                                                               AND UNITY_IS_Active__c = TRUE
                                                               AND Default_Customer_Service_Contract__c = FALSE
                                                               AND RecordTypeID = :rtidSC
                                                               LIMIT 1];
            
            //assign service contract to work order if business unit in the list and vendor is on work order
            for(WorkOrder wo: WorkOrders){
                for(UNITY_Service_Contract__c sc :serviceContract){
                    if(sc.UNITY_Business_Unit__c.contains(wo.UNITY_Business_Unit__c) && woVAMap.get(wo.Id).Vendor__c == sc.UNITY_Account__c){
                        wo.UNITY_Vendor_Contract__c = sc.Id;
                    }
                }  
            }
            try{
                //Izay: Changed to update
                update WorkOrders;
                update woVAMap.values();
            }catch(Exception e){
                System.debug('Izay: Error while updating work order(s). Line[129] = ' + e.getMessage());
                Throw e;
            }
        }
    }

    /**This method creates a service record on work order creation */
    /* No Longer Needed since we got the FSLI to work */
    /*
    public static void createServiceRecord(List<SObject> newList){
        if(!newList.isEmpty() && Trigger.isAfter){
            Map<Id,Id> woServiceMap = new Map<Id,Id>();//Map to hold WO Id by the Service record Id to update WO
            List<CKSW_BASE__Service__c> newServices = new List<CKSW_BASE__Service__c>();
            for(SObject obj :newList){
                WorkOrder wo = (WorkOrder)obj;
                CKSW_BASE__Service__c service = new CKSW_BASE__Service__c(
                    FSL_INTG__Work_Order__c = wo.Id,
                    FSO__WorkOrder__c = wo.Id,
                    CKSW_BASE__Account__c = wo.AccountId,
                    CKSW_BASE__Auto_Geocode__c = true,
                    FSL_INTG__Case__c = wo.CaseId,
                    CKSW_BASE__Comment__c = wo.UNITY_Work_Description__c,
                    CKSW_BASE__Contact__c = wo.ContactId,
                    CKSW_BASE__Description__c = wo.Description,
                    CKSW_BASE__Duration__c = 60,
                    CKSW_BASE__Duration_Type__c = 'Minutes',
                    CKSW_BASE__Open_Date__c = Date.today(),
                    CKSW_BASE__Status__c = 'New'
                );
                newServices.add(service);
            }
            if(!newServices.isEmpty()){
                try{
                    insert newServices;
                    for(CKSW_BASE__Service__c service :newServices){
                        woServiceMap.put(service.FSL_INTG__Work_Order__c,service.Id);
                    }
                    if(!System.isFuture() && !System.isBatch()){
                        updateWorkOrderWithService(woServiceMap);
                    }
                }catch(Exception e){
                    Trigger.new[0].addError('Error: ' + e.getMessage());
                }
            }
        }
    }
    */
    /**This method updates the WO with its serice record*/
    /* No Longer Needed since we got the FSLI to work */
    /*
    @future
    public static void updateWorkOrderWithService(Map<Id,Id> woServiceMap){
        if(woServiceMap != null && !woServiceMap.keySet().isEmpty()){
            List<WorkOrder> workOrders = new List<WorkOrder>();//List of work orders to update
            for(Id id :woServiceMap.keySet()){
                WOrkOrder wo = new WorkOrder();
                wo.Id = id;
                wo.FSL_INTG__Service__c = woServiceMap.get(id);
                workOrders.add(wo);
            }
            try{
                update workOrders;
            }catch(Exception e){
                //Need some sort of exception handling here...
            }
        }
    }
    */
    /**This method handles sharing Intercompany Transfer WOs with all Dispatchers of the MSP BU
    *@param newList List<WorkOrder> the list of new records in the trigger transaction
    *@param oldMap  Map<Id,WorkOrder> the map of records with their old values in the transaction
    */
    public static void handleIntercompanyTransferSharing(List<SObject> newList, Map<Id,SObject> oldMap){
        
        List<WorkOrder> acceptedWOs = new List<WorkOrder>();
        List<WorkOrderShare> woShare = new List<WorkOrderShare>();
        Set<Id> vendorIds = new Set<Id>();
        Map<Id,List<WorkOrder>> woShareWithBUMap = new Map<Id,List<WorkOrder>>();
        Set<Id> buids = new Set<Id>();
        //Only run on update context.
        if(Trigger.isUpdate || Trigger.isInsert){
            for(SObject so :newList){
                WorkOrder wo = (WorkOrder)so;
                WorkOrder oldWO = oldMap != null ? (WorkOrder)oldMap.get(wo.Id) : null;
                //If the vendor accepted...
                if(oldWO != null){
                    if((String.isNotBlank(wo.UNITY_Accepted_Vendor__c) && wo.UNITY_Accepted_Vendor__c != oldWO.UNITY_Accepted_Vendor__c) || 
                       (String.isNotBlank(wo.UNITY_Accepted_Vendor__c) && wo.OwnerId != oldWO.OwnerId)){
                        acceptedWOs.add(wo);
                        vendorIds.add(wo.UNITY_Accepted_Vendor__c);
                        buids.add(wo.UNITY_Business_Unit_Account__c);
                    }
                    if(wo.MSPFS_Related_Is_Intercompany__c && !oldWO.MSPFS_Related_Is_Intercompany__c){
                        acceptedWOs.add(wo);
                        vendorIds.add(wo.MSPFS_Related_Accepted_Vendor_Id__c);
                        buids.add(wo.UNITY_Business_Unit_Account__c);
                    }
                }else if(wo.MSPFS_Related_Is_Intercompany__c){
                    acceptedWOs.add(wo);
                    vendorIds.add(wo.MSPFS_Related_Accepted_Vendor_Id__c);
                    buids.add(wo.UNITY_Business_Unit_Account__c);
                }
            }
            System.debug('#####Izay: acceptedWOs = ' + JSON.serializePretty(acceptedWOs.size()));
            System.debug('#####Izay: vendorIds = ' + JSON.serializePretty(vendorIds));
            System.debug('#####Izay: buids = '  + JSON.serializePretty(buids));
            if(!vendorIds.isEmpty()){
                //Query the account record for the accepted vendors filtering by the Is MSP BU flag.
                Map<Id,Account> vendorsMap = new Map<Id,Account>([SELECT Id,MSPFS_Is_MSP_BU__c, MSP_Go_Live_Date__c FROM Account WHERE Id IN :vendorIds AND MSPFS_Is_MSP_BU__c = TRUE AND RecordTypeId = :UNITY_Constants.ACCOUNT_MINER_RECORDTYPE]);
                System.debug('#####Izay: vendorsMap = ' + JSON.serializePretty(vendorsMap));
                //If any vendors are returned...
                if(!vendorsMap.keySet().isEmpty()){
                    //Need to check that the BU on the WO is NOT MSP BU
                    Map<Id,Account> buAccountsMap = new Map<Id,Account>([SELECT Id,MSPFS_Is_MSP_BU__c FROM Account WHERE Id IN :buids]);
                    System.debug('#####Izay: buAccountsMap = ' + JSON.serializePretty(buAccountsMap));
                    //Set the can HandleIntercompanyTransfer to false... it shouldn't run again if it got to this point
                    canHandleIntercompanyTransfer = false;
                    for(WorkOrder wo :acceptedWOs){
                        if( vendorsMap.containsKey(wo.UNITY_Accepted_Vendor__c) && buAccountsMap.containsKey(wo.UNITY_Business_Unit_Account__c)){
                            //If the BU on the WO is NOT MSP BU and the Accepted Vendor IS MSP BU...
                            if(!buAccountsMap.get(wo.UNITY_Business_Unit_Account__c).MSPFS_Is_MSP_BU__c && vendorsMap.get(wo.UNITY_Accepted_Vendor__c).MSPFS_Is_MSP_BU__c){
                                if (vendorsMap.get(wo.UNITY_Accepted_Vendor__c).MSP_Go_Live_Date__c != null &&
                                     wo.UNITY_Vendor_Accept_Date__c >= vendorsMap.get(wo.UNITY_Accepted_Vendor__c).MSP_Go_Live_Date__c )
                                     wo.MSPFS_Intercompany_Transfer__c = true;//Flg WO as intercompany transfer
                                //Need to create sharing record for the WO for all Dispatcher/tecnicians in MSP BU
                                if(!woShareWithBUMap.containsKey(wo.UNITY_Accepted_Vendor__c))
                                    woShareWithBUMap.put(wo.UNITY_Accepted_Vendor__c,new List<WorkOrder>());

                                woShareWithBUMap.get(wo.UNITY_Accepted_Vendor__c).add(wo);
                            }
                        }else if(vendorsMap.containsKey(wo.MSPFS_Related_Accepted_Vendor_Id__c) && buAccountsMap.containsKey(wo.UNITY_Business_Unit_Account__c)){
                            //If the BU on the WO is NOT MSP BU and the Accepted Vendor IS MSP BU...
                            if(!buAccountsMap.get(wo.UNITY_Business_Unit_Account__c).MSPFS_Is_MSP_BU__c && vendorsMap.get(wo.MSPFS_Related_Accepted_Vendor_Id__c).MSPFS_Is_MSP_BU__c){
                                //wo.MSPFS_Intercompany_Transfer__c = true;//Flg WO as intercompany transfer
                                //Need to create sharing record for the WO for all Dispatcher/tecnicians in MSP BU
                                if(!woShareWithBUMap.containsKey(wo.MSPFS_Related_Accepted_Vendor_Id__c))
                                    woShareWithBUMap.put(wo.MSPFS_Related_Accepted_Vendor_Id__c,new List<WorkOrder>());

                                woShareWithBUMap.get(wo.MSPFS_Related_Accepted_Vendor_Id__c).add(wo);
                            }
                        }
                    }
                    //See if there are any work orders that need sharing with a BU and share it
                    if(!woShareWithBUMap.keySet().isEmpty()){
                        //Need to get all the location users and location resources to share the wo with them
                        Database.SaveResult[] shareResult = shareWorkOrdersWithBU(woShareWithBUMap);
                        for(Database.SaveResult sr :shareResult){
                            if(!sr.isSuccess()){
                                Database.Error err = sr.getErrors()[0];
                                if(!(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION && err.getMessage().contains('AccessLevel'))){
                                    //Trigger.new[0].addError(' An error ocurred while sharing the work order with MSP. Error: ' + err.getMessage());
                                    System.debug('###Izay: An error ocurred while sharing the work order with MSP. Error: ' + err.getMessage());
                                }
                            }
                        }
                    }//End if woShareWithBU
                }
            }
        }
        
    }

    public static Database.SaveResult[] shareWorkOrdersWithBU(Map<Id,List<WorkOrder>> buWOMap){
        Database.SaveResult[] srArr;
        if(buWOMap != null){
            
            List<CKSW_BASE__Resource__c> technicians = new List<CKSW_BASE__Resource__c>();
            List<CKSW_BASE__User_Location__c> dispatchers = new list<CKSW_BASE__User_Location__c>();
            
            technicians = [SELECT Id,CKSW_BASE__Location__c,MSPFS_BU_Account_Id__c,CKSW_BASE__User__c 
                           FROM CKSW_BASE__Resource__c WHERE MSPFS_BU_Account_Id__c IN: buWOMap.keySet() AND CKSW_BASE__User__r.IsActive = TRUE AND CKSW_BASE__Contractor__c = FALSE];
            dispatchers = [SELECT Id,CKSW_BASE__Location__c,MSPFS_BU_Account_Id__c,CKSW_BASE__User__c 
                           FROM CKSW_BASE__User_Location__c WHERE MSPFS_BU_Account_Id__c IN: buWOMap.keySet() AND CKSW_BASE__User__r.IsActive = TRUE];
            
            Map<Id,List<CKSW_BASE__Resource__c>> buTechsMap = new Map<Id,List<CKSW_BASE__Resource__c>>();
            Map<Id,List<CKSW_BASE__User_Location__c>> buDispsMap = new Map<Id,List<CKSW_BASE__User_Location__c>>();
            if(!technicians.isEmpty()){
                for(CKSW_BASE__Resource__c tech :technicians){
                    if(!buTechsMap.containsKey(tech.MSPFS_BU_Account_Id__c))
                        buTechsMap.put(tech.MSPFS_BU_Account_Id__c, new List<CKSW_BASE__Resource__c>());
                    buTechsMap.get(tech.MSPFS_BU_Account_Id__c).add(tech);
                }
            }
            if(!dispatchers.isEmpty()){
                for(CKSW_BASE__User_Location__c disp :dispatchers){
                    if(!buDispsMap.containsKey(disp.MSPFS_BU_Account_Id__c))
                        buDispsMap.put(disp.MSPFS_BU_Account_Id__c, new List<CKSW_BASE__User_Location__c>());
                    buDispsMap.get(disp.MSPFS_BU_Account_Id__c).add(disp);
                }
            }
            
            /*
            Map<Id,Account> buMap = new Map<Id,Account>([SELECT Id,BU_Unique_Field__c,UNITY_Off_Hour_Queue__c FROM Account WHERE Id IN:buWOMap.keySet()]);
            Map<Id,String> buQueueName = new Map<Id,String>();//For standard queue
            Map<Id,String> buQueueName_AH = new Map<Id,String>();//For after hours queue
            for(Account a :buMap.values()){
                String qname = 'UNITY_';
                qName = qName + a.BU_Unique_Field__c.replaceAll(' ', '_');
                String qname_AH = qName + '_After_Hours';
                buQueueName.put(a.Id,qName);
                buQueueName_AH.put(a.Id,qName_AH);
            }
            List<Group> queues =  [SELECT Id,DeveloperName FROM Group 
                                   WHERE DeveloperName IN :buQueueName.values() 
                                   OR DeveloperName IN :buQueueName_AH.values()];
            Map<String,Group> queueNameMap = new Map<String,Group>();
            for(Group q :queues){
                queueNameMap.put(q.Developername,q);
            }
            */
            //Iterate through work orders and get the ids to query related Service and Order records
            Set<Id> woids =  new Set<Id>();
            for(Id buid :buWOMap.keySet()){
                for(WorkOrder wo :buWOMap.get(buid)){
                    woids.add(wo.Id);
                }
            }
            List<Order> orders = [SELECT Id,FSO__WorkOrder__c FROM Order WHERE FSO__WorkOrder__c IN :woids AND Status != 'Cancelled' AND UNITY_Vendor__c IN :buWOMap.keySet()];
            List<CKSW_BASE__Service__c> services = [SELECT Id,FSL_INTG__Work_Order__c FROM CKSW_BASE__Service__c WHERE FSL_INTG__Work_Order__c IN :woids];
            //Key: work order id, Value: List<Order>
            Map<Id,List<Order>> woOrdersMap = new Map<Id,List<Order>>();
            //Key: work order id, Value: List<Service>
            Map<Id,List<CKSW_BASE__Service__c>> woServicesMap = new Map<Id,List<CKSW_BASE__Service__c>>();
            //Iterate through the Orders and Services pu put them in the maps by wo id
            for(Order o :orders){
                if(!woOrdersMap.containsKey(o.FSO__WorkOrder__c))
                    woOrdersMap.put(o.FSO__WorkOrder__c, new List<Order>());
                woOrdersMap.get(o.FSO__WorkOrder__c).add(o);
            }
            for(CKSW_BASE__Service__c s :services){
                if(!woServicesMap.containsKey(s.FSL_INTG__Work_Order__c))
                    woServicesMap.put(s.FSL_INTG__Work_Order__c, new List<CKSW_BASE__Service__c>());
                woServicesMap.get(s.FSL_INTG__Work_Order__c).add(s);
            }
            //List to hold the wo share records
            List<WorkOrderShare> woShareToInsert = new List<WorkOrderShare>();
            //List to hold the order share records
            List<OrderShare> oShareToInsert = new List<OrderShare>();
            //List to hold the service share records
            List<CKSW_BASE__Service__Share> sShareToInsert = new List<CKSW_BASE__Service__Share>();
            for(Id buid :buWOMap.keySet()){
                for(WorkOrder wo :buWOMap.get(buid)){
                    //If there are tech records... need to share with them.
                    if(buTechsMap.containsKey(buid)){
                        //For each tech in the MSP BU Location (resource)
                        for(CKSW_BASE__Resource__c tech :buTechsMap.get(buid)){
                            //Share the work order
                            WorkOrderShare woShare = new WorkOrderShare();
                            woShare.ParentId = wo.Id;
                            woShare.AccessLevel = 'Edit';
                            woShare.RowCause = Schema.WorkOrderShare.RowCause.Manual;
                            woShare.UserOrGroupId = tech.CKSW_BASE__User__c;
                            woShareToInsert.add(woShare);
                            //Share any PO
                            if(woOrdersMap.containsKey(wo.Id)){
                                for(Order o :woOrdersMap.get(wo.Id)){
                                    OrderShare oShare = new OrderShare();
                                    oShare.OrderId = o.Id;
                                    oShare.OrderAccessLevel = 'Edit';
                                    oShare.RowCause = Schema.OrderShare.RowCause.Manual;
                                    oShare.UserOrGroupId = tech.CKSW_BASE__User__c;
                                    oShareToInsert.add(oShare);
                                }
                            }
                            
                            //Share any Service
                            if(woServicesMap.containsKey(wo.Id)){
                                for(CKSW_BASE__Service__c s :woServicesMap.get(wo.Id)){
                                    CKSW_BASE__Service__Share sShare = new CKSW_BASE__Service__Share();
                                    sShare.ParentID = s.Id;
                                    sShare.AccessLevel = 'Edit';
                                    sShare.RowCause = Schema.CKSW_BASE__Service__Share.RowCause.Manual;
                                    sShare.UserOrGroupId = tech.CKSW_BASE__User__c;
                                    sShareToInsert.add(sShare);
                                }
                            }
                        }
                    }
                    if(buDispsMap.containsKey(buid)){
                        for(CKSW_BASE__User_Location__c disp :buDispsMap.get(buid)){
                            WorkOrderShare woShare = new WorkOrderShare();
                            woShare.ParentId = wo.Id;
                            woShare.AccessLevel = 'Edit';
                            woShare.RowCause = Schema.WorkOrderShare.RowCause.Manual;
                            woShare.UserOrGroupId = disp.CKSW_BASE__User__c;
                            woShareToInsert.add(woShare);
                            //Share any PO
                            if(woOrdersMap.containsKey(wo.Id)){
                                for(Order o :woOrdersMap.get(wo.Id)){
                                    OrderShare oShare = new OrderShare();
                                    oShare.OrderId = o.Id;
                                    oShare.OrderAccessLevel = 'Edit';
                                    oShare.RowCause = Schema.OrderShare.RowCause.Manual;
                                    oShare.UserOrGroupId = disp.CKSW_BASE__User__c;
                                    oShareToInsert.add(oShare);
                                }
                            }
                            
                            //Share any Service
                            if(woServicesMap.containsKey(wo.Id)){
                                for(CKSW_BASE__Service__c s :woServicesMap.get(wo.Id)){
                                    CKSW_BASE__Service__Share sShare = new CKSW_BASE__Service__Share();
                                    sShare.ParentId = s.Id;
                                    sShare.AccessLevel = 'Edit';
                                    sShare.RowCause = Schema.CKSW_BASE__Service__Share.RowCause.Manual;
                                    sShare.UserOrGroupId = disp.CKSW_BASE__User__c;
                                    sShareToInsert.add(sShare);
                                }
                            }
                        }
                    }
                    
                    /*
                    if(buMap.containsKey(buid)){
                        
                        Id qid = queueNameMap.get(buQueueName.get(buid)).Id;
                        Id qid_ah = queueNameMap.get(buQueueName_AH.get(buid)).Id;

                        WorkOrderShare woShare = new WorkOrderShare();
                        woShare.ParentId = wo.Id;
                        woShare.AccessLevel = 'Edit';
                        woShare.RowCause = Schema.WorkOrderShare.RowCause.Manual;
                        woShare.UserOrGroupId = qid;
                        woShareToInsert.add(woShare);

                        WorkOrderShare woShare_AH = new WorkOrderShare();
                        woShare_AH.ParentId = wo.Id;
                        woShare_AH.AccessLevel = 'Edit';
                        woShare_AH.RowCause = Schema.WorkOrderShare.RowCause.Manual;
                        woShare.UserOrGroupId = qid_ah;
                        woShareToInsert.add(woShare_AH);
                    }
                    */
                }//End for wo
            }//End for buid
            if(!woShareToInsert.isEmpty()){
                srArr = Database.insert(woShareToInsert,false);
                Database.insert(oShareToInsert,false);
                Database.insert(sShareToInsert,false);
                return srArr;
            }
        }//End if buWOMap not null
        return srArr;
    }
    //Izay: Updated
    public static void populateTechnicianOnChildPOs( Map<Id, WorkOrder> oldWOValues, Map<Id, WorkOrder> newWOValues ) {
        
        system.debug('%%%%% Start populateTechnicianOnChildPOs');

        if(oldWOValues != null && newWOValues != null){
            List<OrderItem> itemsToUpdate = new List<OrderItem>(); 
            Map<Id,WorkOrder> techChangeWorkOrders = new Map<Id,WorkOrder>();
            Set<Id> techUserIds = new Set<Id>();
            Set<Id> buids = new Set<Id>();
            for (WorkOrder wo : newWOValues.values()) {
                WorkOrder oldWO = oldWOValues.get(wo.Id);
                Boolean changed = false;
                system.debug('%%%%% wo.UNITY_Primary_Technician__c: '+wo.UNITY_Primary_Technician__c);
                system.debug('%%%%% oldWO.UNITY_Primary_Technician__c: '+oldWO.UNITY_Primary_Technician__c);
                if(String.isNotBlank(wo.UNITY_Primary_Technician__c) && wo.UNITY_Primary_Technician__c != oldWO.UNITY_Primary_Technician__c){
                    techUserIds.add(wo.UNITY_Primary_Technician__c);
                    changed = true;
                }
                if(String.isNotBlank(wo.UNITY_Secondary_Technician__c) && wo.UNITY_Secondary_Technician__c != oldWO.UNITY_Secondary_Technician__c){
                    techUserIds.add(wo.UNITY_Secondary_Technician__c);
                    changed = true;
                }
                if(changed){
                    if(wo.MSPFS_Intercompany_Transfer__c)
                        buids.add(wo.UNITY_Accepted_Vendor__c);
                    else
                        buids.add(wo.UNITY_Business_Unit_Account__c);
                    techChangeWorkOrders.put(wo.Id,wo);
                }
            }
            List<Order> relatedPurchaseOrders = [SELECT Id, FSO__WorkOrder__c, 
                                                 (SELECT Id, UNITY_Product_Type__c,MSPFS_Technician__c,MSPFS_Technician2__c, 
                                                  MSPFS_MSP_Cost__c,MSPFS_MSP_Price__c,UNITY_Cost__c
                                                  FROM OrderItems
                                                  WHERE UNITY_Product_Type__c = 'Labor' OR UNITY_Product_Type__c = 'Travel'
                                                 ) 
                                                FROM Order 
                                                WHERE FSO__WorkOrder__c IN: techChangeWorkOrders.keySet() 
                                                AND UNITY_Vendor__c IN :buids
                                                AND RecordTypeId = :UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE 
                                                AND Status != 'Cancelled'];
            if(!relatedPurchaseOrders.isEmpty()){
                Map<Id,List<Order>> woOrdersMap = new Map<Id,List<Order>>();
                for(Order o :relatedPurchaseOrders){
                    if(!woOrdersMap.containsKey(o.FSO__WorkOrder__c))
                        woOrdersMap.put(o.FSO__WorkOrder__c, new List<Order>());
                    woOrdersMap.get(o.FSO__WorkOrder__c).add(o);
                }
                Map<Id, List<CKSW_BASE__Resource__c>> userIdToResourceRecordMap = new Map<Id, List<CKSW_BASE__Resource__c>>();
                List<CKSW_BASE__Resource__c> techResources = [SELECT CKSW_BASE__User__c,MSPFS_Burden_Rate__c,MSPFS_BU_Account_Id__c
                                                              FROM CKSW_BASE__Resource__c 
                                                              WHERE CKSW_BASE__User__c IN :techUserIds
                                                              AND MSPFS_BU_Account_Id__c IN :buids];
                for(CKSW_BASE__Resource__c resource :techResources){
                    if(!userIdToResourceRecordMap.containsKey(resource.CKSW_BASE__User__c))
                        userIdToResourceRecordMap.put(resource.CKSW_BASE__User__c,new List<CKSW_BASE__Resource__c>());
                    userIdToResourceRecordMap.get(resource.CKSW_BASE__User__c).add(resource);
                }
                for(WorkOrder wo :techChangeWorkOrders.values()){
                    if(woOrdersMap.containsKey(wo.Id)){
                        CKSW_BASE__Resource__c tech1 = null;
                        CKSW_BASE__Resource__c tech2 = null;
                        Double rate = 0;
                        //Set primary tech resource record
                        if(String.isNotBlank(wo.UNITY_Primary_Technician__c)){
                            if(userIdToResourceRecordMap.containsKey(wo.UNITY_Primary_Technician__c)){
                                for(CKSW_BASE__Resource__c res :userIdToResourceRecordMap.get(wo.UNITY_Primary_Technician__c)){
                                    if((!wo.MSPFS_Intercompany_Transfer__c && res.MSPFS_BU_Account_Id__c == wo.UNITY_Business_Unit_Account__c) || 
                                       (wo.MSPFS_Intercompany_Transfer__c && res.MSPFS_BU_Account_Id__c == wo.UNITY_Accepted_Vendor__c) ){
                                        tech1 = res;
                                        rate += res.MSPFS_Burden_Rate__c;
                                    }
                                }
                            }
                        }
                        //Set secondary tech resource record
                        if(String.isNotBlank(wo.UNITY_Secondary_Technician__c)){
                            if(userIdToResourceRecordMap.containsKey(wo.UNITY_Secondary_Technician__c)){
                                for(CKSW_BASE__Resource__c res :userIdToResourceRecordMap.get(wo.UNITY_Secondary_Technician__c)){
                                    if((!wo.MSPFS_Intercompany_Transfer__c && res.MSPFS_BU_Account_Id__c == wo.UNITY_Business_Unit_Account__c) || 
                                       (wo.MSPFS_Intercompany_Transfer__c && res.MSPFS_BU_Account_Id__c == wo.UNITY_Accepted_Vendor__c)){
                                        tech2 = res;
                                        rate += res.MSPFS_Burden_Rate__c;
                                    }
                                }
                            }
                        }

                        for(Order o :relatedPurchaseOrders){
                            for(OrderItem oi :o.OrderItems){
                                oi.MSPFS_Technician__c = tech1 != null ? tech1.Id : null;
                                oi.MSPFS_Technician2__c = tech2 != null ? tech2.Id : null;
                                if(wo.MSPFS_Intercompany_Transfer__c){
                                    oi.MSPFS_MSP_Cost__c = rate;
                                    oi.MSPFS_MSP_Price__c = oi.UNITY_Cost__c;
                                }
                                itemsToUpdate.add(oi);
                            }
                        }
                    }
                }
            }
            if(!itemsToUpdate.isEmpty()){
                try{
                    update itemsToUpdate;
                }catch(Exception e){
                    trigger.new[0].addError(' Error: ' + e.getMessage());
                }

            } 
        }//End if new and old not null

    }

    public static void validateWorkOrderWhenETAPopulated( Map<Id, WorkOrder> oldWOValues, Map<Id, WorkOrder> newWOValues ) {

        system.debug('%%%%% Start validateWorkOrderWhenETAPopulated');

        Map<Id, WorkOrder> techETAChangedWorkOrders = new Map<Id, WorkOrder>();
        Set<Id> buids = new Set<Id>();
        for ( WorkOrder wOrder : newWOValues.values() ) {
            WorkOrder oldOrder = oldWOValues.get( wOrder.Id );
            if (wOrder.MSPFS_Service_Order_Type__c == 'Quoted' && wOrder.StartDate != null && oldOrder.StartDate == null) {
                techETAChangedWorkOrders.put( wOrder.Id, wOrder );
                buids.add(wOrder.UNITY_Business_Unit_Account__c);
            }
        }

        system.debug('### second 1');

        if (!techETAChangedWorkOrders.isEmpty()){
            Map<Id, Account> mspBusinessUnitAccountMap = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN :buids AND MSPFS_Is_MSP_BU__c = true]); 

            system.debug('### second 2');

            Map<Id, List<UNITY_Proposal__c>> workOrderToQuoteListMap = new Map<Id, List<UNITY_Proposal__c>>();

            List<UNITY_Proposal__c> quotesRelatedToWOInTrigger = [SELECT Id, UNITY_Work_Order__c
                                                                  FROM UNITY_Proposal__c 
                                                                  WHERE UNITY_Work_Order__c IN: techETAChangedWorkOrders.keySet() 
                                                                  AND UNITY_Proposal_Status__c = 'Customer Approved'];
            system.debug('### second 3');
            
            for ( UNITY_Proposal__c quote : quotesRelatedToWOInTrigger ) {
                if ( !workOrderToQuoteListMap.containsKey(quote.UNITY_Work_Order__c) ) 
                    workOrderToQuoteListMap.put( quote.UNITY_Work_Order__c, new List<UNITY_Proposal__c>() );

                workOrderToQuoteListMap.get( quote.UNITY_Work_Order__c ).add( quote );
            }

            for ( WorkOrder wOrder : techETAChangedWorkOrders.values() ) {
                if(mspBusinessUnitAccountMap.containsKey(wOrder.UNITY_Business_Unit_Account__c)){
                    if (!workOrderToQuoteListMap.containsKey( wOrder.Id )){
                        Trigger.new[0].addError('A quote is required before dispatching a Quoted work order');
                    }
                }
            }
        }
    }

    public static void revertStatusAfterUpdate( Map<Id, WorkOrder> oldWOValues, Map<Id, WorkOrder> newWOValues ) {
        Set<Id> buids = new Set<Id>();
        for ( WorkOrder wo : newWOValues.values() ) {
            WorkOrder oldWO = oldWOValues.get( wo.Id ); 
            if ( oldWO.Status != wo.Status ) {
              if (wo.Status == 'Pending Tech Dispatch')
                buids.add(wo.UNITY_Business_Unit_Account__c);
            }
        }
        Map<Id,Account> busMap = new Map<Id,Account>();
        if (buids.size() > 0){
              
            busMap = new Map<Id, Account>([SELECT Id, MSPFS_Is_MSP_BU__c FROM Account WHERE Id IN :buids]);
          
              for ( WorkOrder wo : newWOValues.values() ) {
                WorkOrder oldWO = oldWOValues.get( wo.Id );  
                      
                if ( !busMap.get(wo.UNITY_Business_Unit_Account__c).MSPFS_Is_MSP_BU__c &&
                     (oldWO.Status == 'Pending Vendor Estimate'  || 
                      oldWO.Status == 'Usage Request Needed' || 
                      oldWO.Status == 'Pending Re-Dispatch' || 
                      oldWO.Status == 'New' || 
                      oldWO.Status == 'Completed' ||
                      oldWO.Status == 'Quote Needed') ) {
                            wo.Status = oldWO.Status;
                }
            }
         }
    }

    public static Boolean canHandleIntercompanyTransfer = true;
    public static Boolean handleIntercompanyTransferOnce(){
        if(canHandleIntercompanyTransfer){
            //canHandleIntercompanyTransfer = false;
            return true;
        }else{
            return canHandleIntercompanyTransfer;
        }
    }

    /**This methods handles revenue recognition for MSP on intercompany transfer processes
    *@param workOrders - List<WorkOrder>: The list of work orders that need to be processes
    Deprecated: Izay 
    public static void intercompanyMSPRevenueRecognition(List<WorkOrder> workOrders){
        if(!workOrders.isEmpty()){
            //First make sure that the work order is intercompany transfer and that it hasn't been rocessed previously.
            Map<Id,WorkOrder> validWOsMap = new Map<Id,WOrkOrder>();
            Set<Id> mspBUIds = new Set<Id>();
            for(WorkOrder wo :workOrders){
                if(!wo.MSPFS_Intercompany_MSP_Revenue_Processed__c && wo.MSPFS_Intercompany_Transfer__c && wo.Status == 'Completed' && wo.UNITY_Attachment_Compliant__c){
                    validWOsMap.put(wo.Id,wo);
                    mspBUIds.add(wo.UNITY_Accepted_Vendor__c);
                }
            }
            //If there are valid work order... continue with the process
            if(!validWOsMap.keySet().isEmpty()){
                //Need to get all the POs related to the WO where the vendor is MSP BU (same as accepted vendor on the WOs)
                Map<Id,Order> ordersMap = new Map<Id,Order>([SELECT Id,FSO__WorkOrder__c,UNITY_Vendor__c,UNITY_Vendor__r.BU_Unique_Field__c,UNITY_Work_Order_Type__c,EffectiveDate,
                                                            (SELECT Id,MSPFS_MSP_Cost__c,MSPFS_MSP_Price__c,UNITY_Is_Vendor_Supply__c,PricebookEntry.Product2.UNITY_Product_Type__c,
                                                            UNITY_Vendor_Adjusted_Quantity__c,UNITY_Total_Cost__c,UNITY_Activity_Type__c
                                                            FROM OrderItems WHERE UNITY_Is_Vendor_Supply__c = true)
                                                            FROM Order WHERE FSO__WorkOrder__c IN :validWOsMap.keySet() AND UNITY_Vendor__c IN :mspBUIds AND Status IN ('Accepted','Final')]);
                if(!ordersMap.keySet().isEmpty()){
                    //Now need to place the orders in a map by work order id
                    Map<Id,List<Order>> woOrdersMap = new Map<Id,List<Order>>();
                    Map<Id,Map<Id,Order>> newOrdersByWOMap = new Map<Id,Map<Id,Order>>();//Holds new orders by the work order id and old order id
                    Map<Id,List<OrderItem>> newOrderItemsByOldOrderId = new Map<Id,List<orderItem>>();//Holds new order items by old order id
                    List<Order> ordersToInsert = new List<Order>();//Holds mew orders to be inserted
                    List<OrderItem> orderItemsToInsert = new List<OrderItem>();//Holds new order items to be inserted
                    for(Order o :ordersMap.values()){
                        if(!woOrdersMap.containsKey(o.FSO__WorkOrder__c))
                            woOrdersMap.put(o.FSO__WorkOrder__c,new List<Order>());
                        woOrdersMap.get(o.FSO__WorkOrder__c).add(o);
                    }
                    //Now need to go through each work order and POs and create New POs to account for MSP Cost
                    for(WorkOrder wo :validWOsMap.values()){
                        if(woOrdersMap.containsKey(wo.Id)){
                            for(Order o :woOrdersMap.get(wo.Id)){
                                //===================================
                                // Create the new order
                                // =================================== 
                                Order newOrder = new Order();
                                newOrder.FSO__WorkOrder__c = o.FSO__WorkOrder__c;
                                newOrder.AccountId = wo.UNITY_Business_Unit_Account__c;
                                newOrder.UNITY_Customer__c = wo.UNITY_Business_Unit_Account__c;
                                newOrder.UNITY_GL_Sub_Account__c = null;
                                newOrder.UNITY_GL_Segment_Account__c = null;
                                newOrder.UNITY_Business_Unit__c = o.UNITY_Vendor__r.BU_Unique_Field__c;
                                newOrder.UNITY_Business_Unit_Account__c = o.UNITY_Vendor__c;
                                newOrder.UNITY_Invoice__c = null;
                                newOrder.UNITY_Invoiced__c = false;
                                newOrder.EffectiveDate = o.EffectiveDate;
                                newOrder.MSPFS_Skip_Pricing_Rules__c= true;
                                newOrder.Status = 'Draft';
                                newOrder.UNITY_Tax_Processed__c = true;
                                //Put the new order in the map by wo id and old order id
                                if(!newOrdersByWOMap.containsKey(wo.Id))
                                    newOrdersByWOMap.put(wo.Id, new Map<Id,Order>());
                                newOrdersByWOMap.get(wo.Id).put(o.Id,newOrder);
                                //Add the new order in toInsert list
                                ordersToInsert.add(newOrder);
                                // ===================================
                                // Create the new order items
                                // =================================== 
                                for(OrderItem oItem :o.OrderItems){
                                    //=======================================
                                    //May want to validate here that MSP Cost, MSP Price, and Vendor Adjusted Qty are populated
                                    //=======================================
                                    OrderItem newOrderItem = oItem.clone(false,true,false,false);
                                    newOrderItem.UNITY_Cost__c = oItem.MSPFS_MSP_Cost__c;
                                    newOrderItem.UNITY_Total_Cost__c = oItem.UNITY_Vendor_Adjusted_Quantity__c * oItem.MSPFS_MSP_Cost__c;
                                    newOrderItem.UNITY_Price__c = oItem.MSPFS_MSP_Price__c;
                                    newOrderItem.UnitPrice  = oItem.MSPFS_MSP_Price__c;
                                    newOrderItem.Quantity = oItem.UNITY_Vendor_Adjusted_Quantity__c;
                                    newOrderItem.UNITY_Customer_Adjusted_Quantity__c = oItem.UNITY_Vendor_Adjusted_Quantity__c;
                                    newOrderItem.UNITY_Total_Price__c = oItem.UNITY_Total_Cost__c;
                                    newOrderItem.MSPFS_MSP_Cost__c = null;
                                    newOrderItem.MSPFS_MSP_Price__c = null;
                                    newOrderItem.UNITY_Sales_Tax__c = 0;
                                    newOrderItem.UNITY_GL_Revenue_Account__c = null;
                                    newOrderItem.UNITY_GL_Cost_Account__c = null;
                                    newOrderItem.UNITY_GL_Tax_Account__c = null;
                                    //Update the line type activity type fields to match what it should be for MSP BU
                                    if(oItem.PricebookEntry.Product2.UNITY_Product_Type__c.contains('Labor')){
                                        if(o.UNITY_Work_Order_Type__c == 'Project')
                                            newOrderItem.UNITY_Type__c = 'Labor - Installation';
                                        else 
                                            newOrderItem.UNITY_Type__c = 'Labor - Service';
                                        if(o.UNITY_Work_Order_Type__c == 'PM')
                                            newOrderItem.UNITY_Activity_Type__c = 'Preventative Maintenance';
                                        else
                                            newOrderItem.UNITY_Activity_Type__c = oItem.UNITY_Activity_Type__c.substring(7);
                                    }
                                    if(oItem.PricebookEntry.Product2.UNITY_Product_Type__c.contains('Travel')){
                                        newOrderItem.UNITY_Type__c = 'Travel';
                                        if(o.UNITY_Work_Order_Type__c == 'PM')
                                            newOrderItem.UNITY_Activity_Type__c = 'Preventative Maintenance';
                                        else
                                            newOrderItem.UNITY_Activity_Type__c = oItem.UNITY_Activity_Type__c.substring(7);
                                    }
                                    if(oItem.PricebookEntry.Product2.UNITY_Product_Type__c.contains('Parts')){
                                        newOrderItem.UNITY_Type__c = 'Parts';
                                    }
                                    if(!newOrderItemsByOldOrderId.containsKey(o.Id))
                                        newOrderItemsByOldOrderId.put(o.Id,new List<OrderItem>());
                                    newOrderItemsByOldOrderId.get(o.Id).add(newOrderItem);
                                }
                            }
                        }
                    }
                    //Now need to insert the orders
                    //Then, parent the new order items to the new orders
                    //Then insert the order items
                    SavePoint sp = Database.setSavepoint();//Save point to revert back to if an error is thrown
                    Set<Id> orderItemIds = new Set<Id>();
                    Map<Id,OrderItem> orderItemsMap = new Map<Id,OrderItem>();
                    Map<Id,Id> oldOrderIdNewOrderIdMap = new Map<Id,Id>();
                    System.debug('Izay: ordersToInsert = ' + JSON.serializePretty(ordersToInsert));
                    try{
                        insert ordersToInsert;
                        for(Id woId :newOrdersByWOMap.keySet()){
                            for(Id oldOrderId :newOrdersByWOMap.get(woId).keySet()){
                                oldOrderIdNewOrderIdMap.put(oldOrderId,newOrdersByWOMap.get(woId).get(oldOrderId).Id);
                                for(OrderItem item :newOrderItemsByOldOrderId.get(oldOrderId)){
                                    item.OrderId = newOrdersByWOMap.get(woId).get(oldOrderId).Id;
                                    System.debug('Izay: OrderId = ' + item.OrderId);
                                    orderItemsToInsert.add(item);
                                }
                            }
                        }
                        insert orderItemsToInsert;
                        for(OrderItem oi :orderItemsToInsert){
                            orderItemIds.add(oi.Id);
                        }
                        orderItemsMap = new Map<Id,OrderItem>([SELECT Id,UNITY_Price__c,UNITY_Customer_Adjusted_Quantity__c,UNITY_Cost__c,OrderId,
                                                               UNITY_Sales_Tax__c,UNITY_Discount__c,UNITY_Discount_Amount__c,PricebookEntry.Product2Id,
                                                               UNITY_Tax_Code__c,UNITY_Is_Vendor_Supply__c,UNITY_GL_Revenue_Account__c,UNITY_GL_Tax_Account__c,
                                                               UNITY_GL_Sub_Account__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Asset__c,UNITY_Unknown_Part_Description__c
                                                               FROM OrderItem WHERE Id IN :orderItemIds]);
                    }catch(Exception e){
                        Database.rollback(sp);
                        Trigger.new[0].addError('Error while processing MSP revenue. Error: ' + e.getMessage() + '. Stacktrace: ' + e.getStackTraceString());
                    }
                    System.debug('Izay: oldOrderIdNewOrderIdMap = ' + JSON.serializePretty(oldOrderIdNewOrderIdMap));
                    //If we get to this point with no errors... now need to create the invoice
                    Map<Id,UNITY_Invoice__c> invoiceByWOId = new Map<Id,UNITY_Invoice__c>();
                    for(WorkOrder wo :validWOsMap.values()){
                        if(newOrdersByWOMap.containsKey(wo.Id)){
                            UNITY_Invoice__c invoice = new UNITY_Invoice__c();
                            invoice.UNITY_Case__c = wo.CaseId;
                            invoice.UNITY_Customer__c = wo.UNITY_Business_Unit_Account__c;
                            invoice.UNITY_Status__c = 'Invoice Creation';
                            invoice.UNITY_Vendor_Service_Fee__c = 0;
                            invoice.UNITY_Discount_from_POs__c = 0;
                            invoice.UNITY_Discount_Amount__c = 0;
                            invoiceByWOId.put(wo.Id,invoice);
                        }
                    }
                    //Insert the invoice
                    //Then, create the invoice lines
                    //And related the POs to the invoice
                    try{
                        insert invoiceByWOId.values();
                        List<Order> ordersToUpdate = new List<Order>();//Orders to update
                        List<UNITY_Invoice_Line_Item__c> invLines = new List<UNITY_Invoice_Line_Item__c>();//Invoicelines to update
                        Set<Id> invIds = new Set<Id>();//Holds the invoice ids
                        for(Id woId :invoiceByWOId.keySet()){
                            //Add the invoice id to set 
                            invIds.add(invoiceByWOId.get(woId).Id);
                            if(newOrdersByWOMap.containsKey(woId)){
                                for(Id oldOrderId :newOrdersByWOMap.get(woId).keySet()){
                                    //Associate the PO with the invoice and finalize POs
                                    newOrdersByWOMap.get(woId).get(oldOrderId).UNITY_Invoice__c = invoiceByWOId.get(woId).Id;
                                    newOrdersByWOMap.get(woId).get(oldOrderId).UNITY_Invoiced__c = true;
                                    //newOrdersByWOMap.get(woId).get(oldOrderId).Status = 'Final';
                                    ordersToUpdate.add(newOrdersByWOMap.get(woId).get(oldOrderId));

                                    for(OrderItem item :newOrderItemsByOldOrderId.get(oldOrderId)){
                                        
                                        OrderItem oItem;
                                        if(orderItemsMap.containsKey(item.Id)){
                                            oItem =  orderItemsMap.get(item.Id);
                                        }
                                        if(oItem != null){
                                            //Need to create the invoice lines here...
                                            UNITY_Invoice_Line_Item__c invLine = new UNITY_Invoice_Line_Item__c();
                                            invLine.UNITY_Invoice__c = invoiceByWOId.get(woId).Id;
                                            invLine.UNITY_Total_Price__c = oItem.UNITY_Price__c * oItem.UNITY_Customer_Adjusted_Quantity__c;
                                            invLine.UNITY_Cost__c = oItem.UNITY_Cost__c * oItem.UNITY_Customer_Adjusted_Quantity__c;
                                            //invLine.UNITY_Sales_Tax__c = oItem.UNITY_Sales_Tax__c;
                                            invLine.UNITY_PO_Price__c = oItem.UNITY_Price__c; 
                                            invLine.UNITY_Quantity__c = oItem.UNITY_Customer_Adjusted_Quantity__c;
                                            
                                            invLine.UNITY_Adjusted_Quantity__c = oItem.UNITY_Customer_Adjusted_Quantity__c;

                                            //Izay: Added this additional fields to the invoice ceration
                                            //to support SL Integration
                                            invLine.UNITY_Discount__c = oItem.UNITY_Discount__c;
                                            invLine.UNITY_Discount_Amount__c = oItem.UNITY_Discount_Amount__c;
                                            invLine.Product__c = oItem.PricebookEntry.Product2Id;
                                            //invLine.UNITY_Tax_Code__c = oItem.UNITY_Tax_Code__c;
                                            invLine.UNITY_Is_Vendor_Supply__c = oItem.UNITY_Is_Vendor_Supply__c;
                                            invLine.UNITY_GL_Revenue_Account__c = oItem.UNITY_GL_Revenue_Account__c;
                                            invLine.UNITY_GL_Tax_Account__c = oItem.UNITY_GL_Tax_Account__c;
                                            invLine.UNITY_GL_Sub_Account__c = oItem.UNITY_GL_Sub_Account__c;
                                            invLine.UNITY_Type__c = oItem.UNITY_Type__c;
                                            invLine.UNITY_Activity_Type__c = oItem.UNITY_Activity_Type__c;
                                            invLine.UNITY_WorkOrder__c = woId;
                                            invLine.UNITY_Asset__c = oItem.UNITY_Asset__c;
                                            invLine.UNITY_Description__c = oItem.UNITY_Unknown_Part_Description__c;

                                            invLines.add(invLine);
                                        
                                        }
                                            
                                    }
                                }
                            }
                        }

                        if(!invLines.isEmpty()){
                            insert invLines;
                        }
                        if(!ordersToUpdate.isEmpty()){
                            //List<Order> temp = new List<Order>();
                            //temp.addAll(ordersToUpdate);
                            update ordersToUpdate;
                        }

                        //Now need to finalize the invoice
                        List<UNITY_Invoice__c> invoices = [SELECT Id,UNITY_Status__c FROM UNITY_Invoice__c WHERE Id IN :invIds];
                        for(UNITY_Invoice__c inv :invoices){
                            inv.UNITY_Status__c = 'Invoice Finalized';
                            inv.UNITY_Invoice_Status__c =  'Invoice Finalized';
                        }
                        update invoices;
                    }catch(Exception e){
                        Database.rollback(sp);
                        //Throw exception to trigger.new[0]
                        Trigger.new[0].addError('Error while processing MSP revenue. Error: ' + e.getMessage() + '. Stacktrace: ' + e.getStackTraceString());
                    }
                }//End if orders
            }//End if valid work orders
        }//End if work orders
    }//End intercompanyMSPRevenueRecognition()
    */
}