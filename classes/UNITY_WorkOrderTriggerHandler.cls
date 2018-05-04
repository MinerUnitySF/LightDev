/*
 * @date:      11/17/2015
  * ========================================================================
 * @description: Made handleCompletedWorkOrders method @future to fix Bill to IVR error.
 * @programmer:  Izay Ramos-Irizarry
 * @date:        10/19/2016
 * ========================================================================
 */
public with sharing class UNITY_WorkOrderTriggerHandler extends UNITY_BaseHandler{
//
    //private Map< id, SObject > parentCases = new Map< id, SObject >();

    // key   : work order id + vendor id
    // value : assignment record related to the WO and the vendor
    private Map< String, UNITY_Vendor_Assignment__c > woVendorToAssignment = new Map< String, UNITY_Vendor_Assignment__c >();

    // key   : id account
    // value : account
    private Map< id, Account > vendorsData = new Map< id, Account >();

    private Map< id, UNITY_wrapperVendorByTrade > createNewDraftPO = new Map< id, UNITY_wrapperVendorByTrade >();

    // list or assignment to update
    private List< UNITY_Vendor_Assignment__c > assignmentToUpdate = new List< UNITY_Vendor_Assignment__c >();

    // list or assignment to update
    private Set<id> workOrdersIdToDispatch = new Set<id> ();

    private Set<id> vendorsRejected = new Set<id> ();

    private list<WorkOrder> woToAssignTechnician = new list<WorkOrder>();

    // list of vendors available per work order
    Map<Id, list<UNITY_wrapperVendorByTrade>> vendors = new Map<Id, list<UNITY_wrapperVendorByTrade>>();

    private List<Order>  updateToFinalOrder = new List<Order>();
    private List<WorkOrder> orderWithTemplate;
    private Map< id, id> recordIdTemplateId = new Map< id, id>();
    private Map<id,Order>  toCreateOrders = new Map<id,Order>();

    private Map<Id, Case> relatedCasesMap = new Map<Id, Case>();
    private Map<Id, UNITY_Service_Contract__c> customerServiceContracts = new Map<Id, UNITY_Service_Contract__c>();
    private Map<Id, Id> serviceContractIdsByCase = new Map<Id, Id>();

    // MAP FOR ONLY PO ORDERS WITH STATUS == 'Final'
    // key   : WO id
    // value : Map< Vendor id  , list of orders >
    private Map<Id, Map<id,List<Order>> > wo_POOrders = new Map<Id, Map<id,List<Order>> >();
    private Map<Id, Map<Id,UNITY_Service_Contract_Line_Item__c>> serviceContractLineByTradeMap = new Map<Id, Map<Id,UNITY_Service_Contract_Line_Item__c>>();

    private List<Id> workOrderWithVendorAssigned = new List<Id>();

    private List<Order> poToUpdate = new List<Order>();

    private Map<id,Map<id,UNITY_Vendor_Assignment__c>> wo_vendorAssignments = new Map<id,Map<id,UNITY_Vendor_Assignment__c>>();

    //private Map<String, UNITY_Vendor_Assignment__c>  woVendor_assignment = new Map<String, UNITY_Vendor_Assignment__c>();

    private static Id standardPriceBookId = UNITY_Constants.getStandardPriceBookId();

    private  Set<Id> completedWorkOrders = new Set<Id>();

    private static List<WorkOrder> ordersToPropagateIncludeFieldValue = new List<WorkOrder>();

    private  Map<Id,Set<id>> workOrderChangedOwners = new Map<Id,Set<id>>();
    
    private Set<Id> closedWorkOrders = new Set<Id>();
    
    public override void bulkBefore(){

        if (Trigger.isInsert){

            populateRelatedCasesMap();

            UNITY_AutopopulateChildController.autopopulateFieldsIfApplicableBulkified(trigger.new, 'WorkOrder');

            List<Id> relatedSC = new List<Id>();

            for (SObject so : Trigger.new){

                WorkOrder workOrderRecord = (WorkOrder) so;

                if (workOrderRecord.UNITY_Customer_Service_Contract__c != null){
                    relatedSC.add(workOrderRecord.UNITY_Customer_Service_Contract__c);
                }
            }

            if(relatedSC.size()>0){
                //customerServiceContracts = new Map<Id, UNITY_Service_Contract__c>([select id, UNITY_Margin__c, UNITY_Default_Labor_Rate__c, (select id, UNITY_Trade__c, UNITY_Labor_Cost__c from UNITY_Service_Contract_Line_Items__r where recordTypeid =: UNITY_Constants.SCLI_HOURLY_RATE_RECORDTYPE) from UNITY_Service_Contract__c where id in: serviceContractIdsByCase.values()]);
                customerServiceContracts = new Map<Id, UNITY_Service_Contract__c>([select id, UNITY_Margin__c, UNITY_Default_Labor_Rate__c, (select id, UNITY_Trade__c, UNITY_Labor_Cost__c from UNITY_Service_Contract_Line_Items__r where recordTypeid =: UNITY_Constants.SCLI_HOURLY_RATE_RECORDTYPE) from UNITY_Service_Contract__c where id in: relatedSC]);
            }
            system.debug('@@ : customerServiceContracts : '+customerServiceContracts);


            // populate service contract line by trade map
            for(UNITY_Service_Contract__c serviceContract : customerServiceContracts.values()){
                serviceContractLineByTradeMap.put(serviceContract.Id, new Map<Id, UNITY_Service_Contract_Line_Item__c>());
                for (UNITY_Service_Contract_Line_Item__c scli: serviceContract.UNITY_Service_Contract_Line_Items__r){
                    serviceContractLineByTradeMap.get(serviceContract.Id).put(scli.UNITY_Trade__c, scli);
                }
            }

        } else {
            MSPFS_WorkOrderHandler.revertStatusAfterUpdate( ( Map<Id, WorkOrder> )Trigger.oldMap, ( Map<Id, WorkOrder> )Trigger.newMap );
        }

        Set<id> aux_casesId = new Set<id>();

        Set<id> aux_vendorsToQuery = new Set<id>();

        Set<id> aux_updatedVendorStatus = new Set<id>();

        for (SObject so : Trigger.new){

            WorkOrder onWorkOrder = (WorkOrder) so;

            if(Trigger.isInsert){
                onWorkOrder.Pricebook2Id = standardPriceBookId;
            }

            if(Trigger.isUpdate){

                WorkOrder oldWorkOrder = (WorkOrder) Trigger.oldMap.get(onWorkOrder.id);

                if((onWorkOrder.UNITY_Vendor_Status__c != oldWorkOrder.UNITY_Vendor_Status__c)){

                    if((onWorkOrder.UNITY_Vendor_Status__c != 'Dispatching')){
                        aux_updatedVendorStatus.add(onWorkOrder.id);
                        aux_vendorsToQuery.add(onWorkOrder.UNITY_Assigned_Vendor__c);
                    }

                    if (onWorkOrder.UNITY_Auto_Dispatch__c && (onWorkOrder.UNITY_Vendor_Status__c == 'Dispatching')){
                        System.debug('Auto dispatch');
                        workOrdersIdToDispatch.add(onWorkOrder.id);
                    }
                }                
            }

            if(onWorkOrder.CaseId != null){
                aux_casesId.add(onWorkOrder.CaseId);
            }

        }


        if(Trigger.isUpdate){

            // if we have WOs to work with on the dispatch then we need to get all vendors available at the locations
            if(workOrdersIdToDispatch.size()>0){
                System.debug('===========CLAY: Auto dispatch starts here:');
                list<id> aux_list = new list<id>(workOrdersIdToDispatch);

                vendors = UNITY_Vendor_Utils.getVendorsSpecific(aux_list, WorkOrder.getSObjectType(), null , true, true);
                System.debug('Did we get any vendors to query for from our Util?' + vendors.size());
                System.debug(vendors.values());
                for(list<UNITY_wrapperVendorByTrade> vendorList :vendors.values()){
                   for(UNITY_wrapperVendorByTrade vendor :vendorList){
                        aux_vendorsToQuery.add(vendor.id);
                    }
                }
            }

            // get the vendors
            if(aux_vendorsToQuery.size()>0) {
                vendorsData = new Map<id,Account>([SELECT id,recordTypeId, Account_Email__c , UNITY_Dispatcher__c, UNITY_Miner_Regional_Office__c  FROM Account WHERE id IN :aux_vendorsToQuery]);
                System.debug('**********We just queried for vendors - how many? : ' + vendorsData.size());
                System.debug('Vendor 1:' + vendorsData);
            }
                System.debug('Aux vendor update status: ');
            if(!workOrdersIdToDispatch.isEmpty() || !aux_updatedVendorStatus.isEmpty()){
                
                // get Vendor Assignments to update status.
                // Some vendors assignments just were created when we call 'getVendorsSpecific' method
                list<UNITY_Vendor_Assignment__c> vendorAssignmnets = [SELECT id, Assignment_Warning__c, Work_Order__c, Vendor__c, Status__c, PIN__c,Initial_PO__c,
                                                                            Initial_PO__r.UNITY_Total_Cost__c, Initial_PO__r.Status , Initial_PO__r.UNITY_Vendor_Contract__c
                                                                      FROM UNITY_Vendor_Assignment__c
                                                                      WHERE Work_Order__c IN :aux_updatedVendorStatus OR Work_Order__c IN :workOrdersIdToDispatch];

                for(UNITY_Vendor_Assignment__c assignment :vendorAssignmnets){
                    woVendorToAssignment.put(assignment.Work_Order__c + '-'+ assignment.Vendor__c, assignment);
                }
            }
            // closedWorkOrders

            Map<Id,WorkOrder> completedWorkOrderMap = new Map<Id,WorkOrder>();
            for(WorkOrder newWorkOrder :(List<WorkOrder>) Trigger.new) {
                WorkOrder oldWorkOrder = (WorkOrder)Trigger.oldMap.get(newWorkOrder.Id);
                if ((newWorkOrder.SFPS_FS_OverallStatus__c != oldWorkOrder.SFPS_FS_OverallStatus__c) && newWorkOrder.SFPS_FS_OverallStatus__c == 'Completed'){
                    completedWorkOrderMap.put(newWorkOrder.Id,newWorkOrder);
                }
            }
            if (!System.isFuture()){
                    UNITY_WorkOrderTriggerHandlerHelper.adjustLaborRateAboveOrBelowMarginAndMultiTrip(completedWorkOrderMap);
                }

        }

        // query all the parent cases from where capture fields
        /*
        if( aux_casesId.size() > 0 ){

            String query =  'SELECT id, '+UNITY_Utils.getQueryFields(UNITY_Constants.WO_CAPTURE_PARENT_CASE_FIELDS.values())+' FROM Case WHERE id IN :aux_casesId';
            System.debug('>>> query aux_casesId: '+aux_casesId);
            parentCases  =  new Map< id, SObject  >(Database.query(query));

        }
        */

    }

    public override void bulkAfter(){
        
        Set<id> aux_filterVA = new Set<id>();
        
        if (trigger.isUpdate){
            if (!UNITY_Constants.isExecutingContext('UNITY_WorkOrderTriggerHandler.propagateBusinessUnitAccount')){
                //propagateBusinessUnitAccount();
            }
            
            for(SObject so :Trigger.new){
                WorkOrder newWO = (WorkOrder)so;
                WorkOrder oldWO = (WorkOrder)Trigger.oldMap.get(newWO.id);
                
                if((newWO.UNITY_Vendor_Status__c != oldWO.UNITY_Vendor_Status__c)&&(oldWO.UNITY_Assigned_Vendor__c != null))
                    aux_filterVA.add(newWO.id);
            }
            
            //getPOOrders();
            getVendorAssignments(aux_filterVA);
            //updateWOCountsOnAssetAfterUpdate(trigger.new, trigger.oldMap);
            //countWorkOrdersOnAsset(trigger.new, trigger.oldMap);
            //populateAccountLastVisitedDateAndSiteSurveyCountAfterUpdate(trigger.new, trigger.oldMap);
            if(!System.isFuture() && !System.isBatch()){
                populateAccountLastVisitedDateAndSiteSurveyCount(trigger.newMap.keySet(), JSON.serialize(trigger.oldMap));
                UNITY_UpdateCaseStatus.onAfterUpdate(trigger.newMap.keySet(),JSON.serialize(trigger.oldMap));
            }
            //Izay: MSPFS Processes
            system.debug('########### we got here dan');
            MSPFS_WorkOrderHandler.validateWorkOrderWhenETAPopulated( ( Map<Id, WorkOrder> )Trigger.oldMap, ( Map<Id, WorkOrder> )Trigger.newMap );
            MSPFS_WorkOrderHandler.populateTechnicianOnChildPOs( ( Map<Id, WorkOrder> )Trigger.oldMap, ( Map<Id, WorkOrder> )Trigger.newMap );
        }
        if(trigger.isDelete){
            //updateWOCountsOnAssetAfterDelete(trigger.old);
            //countWorkOrdersOnAsset(trigger.old, null);
            //populateAccountLastVisitedDateAndSiteSurveyCountAfterDelete(trigger.old);
            if(!System.isFuture() && !System.isBatch())
                populateAccountLastVisitedDateAndSiteSurveyCount(trigger.oldMap.keySet(), null);
        }
        
        if(trigger.isInsert || trigger.isUndelete){
            //updateWOCountsOnAssetAfterInsert(trigger.new);
            //countWorkOrdersOnAsset(trigger.new, null);
            //populateAccountLastVisitedDateAndSiteSurveyCountAfterInsert(trigger.new);
            if(!System.isFuture() && !System.isBatch()){
                populateAccountLastVisitedDateAndSiteSurveyCount(trigger.newMap.keySet(), null);
                UNITY_UpdateCaseStatus.onAfterInsert(trigger.newMap.keySet());
            }
        }
        
        if(trigger.isInsert || trigger.isUpdate) {
            //updateManualSharing();    
        }
    }

   /*
    * Name : getVendorAssignments
    * Note :
    *
    */
    private void getVendorAssignments(Set<id> filterVA){

        if(!filterVA.isEmpty()){
            Map<id,UNITY_Vendor_Assignment__c> va = new Map<id,UNITY_Vendor_Assignment__c>([SELECT  id,
                                                                                                Work_Order__c,
                                                                                                Initial_PO__c,
                                                                                                Vendor__c,
                                                                                                Initial_PO__r.RecordTypeId,
                                                                                                Initial_PO__r.Status
                                                                                        FROM  UNITY_Vendor_Assignment__c
                                                                                        WHERE Work_Order__c in :filterVA]);
            for(id vaId :va.keySet()){
                if(!wo_vendorAssignments.containsKey(va.get(vaId).Work_Order__c))
                    wo_vendorAssignments.put(va.get(vaId).Work_Order__c, new Map<id,UNITY_Vendor_Assignment__c>());

                 wo_vendorAssignments.get(va.get(vaId).Work_Order__c).put(va.get(vaId).Vendor__c , va.get(vaId));

            }
        }
    }

    /*
    private void getPOOrders(){

        Map<id,Order> orders = new Map<id,Order>([SELECT  id,
                                                          FSO__WorkOrder__c,
                                                          UNITY_Vendor__c
                                                  FROM Order
                                                  WHERE (FSO__WorkOrder__c in :Trigger.newMap.keySet()) AND
                                                        (RecordTypeId = :UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE) AND
                                                        (Status = :UNITY_Constants.ORDER_STATUS_FINAL)]);

        for(id orderId :orders.keySet()){
            if(!wo_POOrders.containsKey(orders.get(orderId).FSO__WorkOrder__c))
                wo_POOrders.put(orders.get(orderId).FSO__WorkOrder__c, new Map<id,List<Order>>());

            if(wo_POOrders.get(orders.get(orderId).FSO__WorkOrder__c).get(orders.get(orderId).UNITY_Vendor__c) == null)
                wo_POOrders.get(orders.get(orderId).FSO__WorkOrder__c).put(orders.get(orderId).UNITY_Vendor__c , new List<Order>());

            wo_POOrders.get(orders.get(orderId).FSO__WorkOrder__c).get(orders.get(orderId).UNITY_Vendor__c).add(orders.get(orderId));
        }
    }*/
    /*
    private void countWorkOrdersOnAsset(List<SObject> woList, Map<Id,SObject> woMap){
        Set<Id> assetIdSet = new Set<Id>();
        if(woMap != null){
            for(SObject o : woList){
                WorkOrder wo = (WorkOrder)o;
                WorkOrder oldwo = (WorkOrder)(woMap.get(o.id));
                if(wo.AssetId != oldwo.AssetId || (wo.AssetId != null && wo.Status != oldwo.Status && (wo.Status == 'Closed' || oldwo.Status == 'Closed'))){
                    assetIdSet.add(wo.AssetId);
                    assetIdSet.add(oldwo.AssetId);
                }
            }
        } else {
            for(SObject o : woList){
                WorkOrder wo = (WorkOrder)o;
                assetIdSet.add(wo.AssetId);
            }
        }
        if(assetIdSet.size() == 0) return;
        Map<Id,Asset> assetMap = new Map<Id, Asset>([SELECT Id, SSVY_Total_of_Work_Orders__c, SSVY_Open_Work_Orders__c FROM Asset WHERE Id IN: assetIdSet]);
        List<WorkOrder> workOrders = [SELECT Id, AssetId, Status FROM WorkOrder WHERE AssetId IN: assetIdSet];
        Map<Id, List<WorkOrder>> assetIdToWorkOrderList = new Map<Id, List<WorkOrder>>();
        for(WorkOrder wo : workOrders){
            if(!assetIdToWorkOrderList.containsKey(wo.AssetId)){
                assetIdToWorkOrderList.put(wo.AssetId, new List<WorkOrder>());
            }
            assetIdToWorkOrderList.get(wo.AssetId).add(wo);
        }
        for(Asset asset : assetMap.values()){
            assetMap.get(asset.Id).SSVY_Total_of_Work_Orders__c = 0;
            assetMap.get(asset.Id).SSVY_Open_Work_Orders__c = 0;
            if(assetIdToWorkOrderList.containsKey(asset.Id)){
                for(WorkOrder wo : assetIdToWorkOrderList.get(asset.Id)){
                    if(wo.Status != 'Closed'){
                        assetMap.get(wo.AssetId).SSVY_Total_of_Work_Orders__c++;
                        assetMap.get(wo.AssetId).SSVY_Open_Work_Orders__c++;
                    } else {
                        assetMap.get(wo.AssetId).SSVY_Total_of_Work_Orders__c++;
                    }
                }
            }
        }
        update AssetMap.values();
    } */
	@future
    public static void populateAccountLastVisitedDateAndSiteSurveyCount( Set<Id> woIdSet, String woMapString){
        UNITY_Constants.isExecutingContext('populateAccountLastVisitedDateAndSiteSurveyCount');
        //List<SObject> woList = (List<SObject>)JSON.deserialize(woListString, List<SObject>.class);
        List<SObject> woList = [SELECT Id, FSO__Completed_Date__c, AccountId, RecordTypeId FROM WorkOrder WHERE Id IN: woIdSet];
        Map<Id,SObject> woMap;
        if(String.isNotBlank(woMapString))
        	woMap = (Map<Id,SObject>)JSON.deserialize(woMapString, Map<Id,SObject>.class);
        
        Set<Id> accountIdSet = new Set<Id>();

        if(woMap != null){
            for(SObject o : woList){
                WorkOrder wo = (WorkOrder)o;
                WorkOrder oldwo = (WorkOrder)(woMap.get(o.id));
                if(wo.FSO__Completed_Date__c != oldwo.FSO__Completed_Date__c ||
                   (wo.AccountId != oldwo.AccountId) ||
                   (wo.RecordTypeId != oldwo.RecordTypeId &&
                    (wo.RecordTypeId == UNITY_Constants.WO_SITE_SURVEY_RECORDTYPE || oldwo.RecordTypeId == UNITY_Constants.WO_SITE_SURVEY_RECORDTYPE))){
                    accountIdSet.add(wo.AccountId);
                    accountIdSet.add(oldwo.AccountId);
                }
            }
        } else {
            for(SObject o : woList){
                WorkOrder wo = (WorkOrder)o;
                accountIdSet.add(wo.AccountId);
            }
        }
        if(accountIdSet.size() == 0) return;
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, SSVY_Total_Site_Surveys_Completed__c, SSVY_Last_Visited_Date__c FROM Account WHERE Id IN: accountIdSet]);
        List<WorkOrder> workOrders = [SELECT Id, RecordTypeId, FSO__Completed_Date__c, AccountId FROM WorkOrder WHERE AccountId IN: accountIdSet];
        Map<Id, List<WorkOrder>> accountIdToWorkOrderList = new Map<Id, List<WorkOrder>>();
        for(WorkOrder wo : workOrders){
            if(!accountIdToWorkOrderList.containsKey(wo.AccountId)){
                accountIdToWorkOrderList.put(wo.AccountId, new List<WorkOrder>());
            }
            accountIdToWorkOrderList.get(wo.AccountId).add(wo);
        }
        for(Account acc: accountMap.values()){
            if(accountIdToWorkOrderList.get(acc.Id) == null){
                accountMap.get(acc.Id).SSVY_Last_Visited_Date__c = null;
            } else {
                DateTime mostRecentDate;
                for(WorkOrder wo : accountIdToWorkOrderList.get(acc.Id)){
                    if(mostRecentDate == null || mostRecentDate < wo.FSO__Completed_Date__c){
                        mostRecentDate = wo.FSO__Completed_Date__c;
                    }
                }
                if(mostRecentDate != null){
                    accountMap.get(acc.Id).SSVY_Last_Visited_Date__c = mostRecentDate.dateGMT();
                } else {
                    accountMap.get(acc.Id).SSVY_Last_Visited_Date__c = null;
                }
            }
            accountMap.get(acc.Id).SSVY_Total_Site_Surveys_Completed__c = 0;
            if(accountIdToWorkOrderList.containsKey(acc.Id)){
                for(WorkOrder wo : accountIdToWorkOrderList.get(acc.Id)){
                    if(wo.RecordTypeId == UNITY_Constants.WO_SITE_SURVEY_RECORDTYPE){
                        accountMap.get(wo.AccountId).SSVY_Total_Site_Surveys_Completed__c++;
                    }
                }
            }
        }
        update AccountMap.values();
    }

    /*
    private void updateWOCountsOnAssetAfterUpdate(List<SObject> workOrders, Map<Id,SObject> mapOld){
        Set<Id> assetIdSet = new Set<Id>();
        List<WorkOrder> workOrdersToProcess = new List<WorkOrder>();
        for(SObject o : workOrders){
            WorkOrder wo = (WorkOrder)o;
            WorkOrder oldwo = (WorkOrder)(mapOld.get(o.id));
            if(wo.AssetId != oldwo.AssetId || (wo.AssetId != null && wo.Status != oldwo.Status && (wo.Status == 'Closed' || oldwo.Status == 'Closed'))){
                assetIdSet.add(wo.AssetId);
                assetIdSet.add(oldwo.AssetId);
                workOrdersToProcess.add(wo);
            }
        }
        if(workOrdersToProcess.size() == 0) return;
        Map<Id,Asset> assetMap = new Map<Id, Asset>([SELECT Id, SSVY_Total_of_Work_Orders__c, SSVY_Open_Work_Orders__c FROM Asset WHERE Id IN: assetIdSet]);
        for(WorkOrder wo : workOrdersToProcess){
            WorkOrder oldwo = (WorkOrder)(mapOld.get(wo.id));
            if(wo.AssetId != oldwo.AssetId){
                if(wo.AssetId != null) assetMap.get(wo.AssetId).SSVY_Total_of_Work_Orders__c++;
                if(oldwo.AssetId != null) assetMap.get(oldwo.AssetId).SSVY_Total_of_Work_Orders__c--;
                if (wo.Status != 'Closed' && oldwo.Status == 'Closed'){
                    if(wo.AssetId != null) assetMap.get(wo.AssetId).SSVY_Open_Work_Orders__c++;
                } else if (wo.Status == 'Closed' && oldwo.Status != 'Closed'){
                    if(oldwo.AssetId != null) assetMap.get(oldwo.AssetId).SSVY_Open_Work_Orders__c--;
                } else if (wo.Status != 'Closed' && oldwo.Status != 'Closed'){
                    if(wo.AssetId != null) assetMap.get(wo.AssetId).SSVY_Open_Work_Orders__c++;
                    if(oldwo.AssetId != null) assetMap.get(oldwo.AssetId).SSVY_Open_Work_Orders__c--;
                }
            } else {
                if (wo.Status != 'Closed' && oldwo.Status == 'Closed'){
                    assetMap.get(wo.AssetId).SSVY_Open_Work_Orders__c++;
                } else if (wo.Status == 'Closed' && oldwo.Status != 'Closed'){
                    assetMap.get(wo.AssetId).SSVY_Open_Work_Orders__c--;
                }
            }
        }
        update assetMap.values();
    }

    private void updateWOCountsOnAssetAfterInsert(List<SObject> workOrders){
        Set<Id> assetIdSet = new Set<Id>();
        List<WorkOrder> workOrdersToProcess = new List<WorkOrder>();
        for(SObject o : workOrders){
            WorkOrder wo = (WorkOrder)o;
            if(wo.AssetId != null){
                workOrdersToProcess.add(wo);
                assetIdSet.add(wo.AssetId);
            }
        }
        if(workOrdersToProcess.size() == 0) return;
        Map<Id,Asset> assetMap = new Map<Id, Asset>([SELECT Id, SSVY_Total_of_Work_Orders__c, SSVY_Open_Work_Orders__c FROM Asset WHERE Id IN: assetIdSet]);
        for(WorkOrder wo : workOrdersToProcess){
            assetMap.get(wo.AssetId).SSVY_Total_of_Work_Orders__c++;
            if(wo.Status != 'Closed'){
                assetMap.get(wo.AssetId).SSVY_Open_Work_Orders__c++;
            }
        }
        update assetMap.values();
    }

    private void updateWOCountsOnAssetAfterDelete(List<SObject> workOrders){
        Set<Id> assetIdSet = new Set<Id>();
        List<WorkOrder> workOrdersToProcess = new List<WorkOrder>();
        for(SObject o : workOrders){
            WorkOrder wo = (WorkOrder)o;
            if(wo.AssetId != null){
                workOrdersToProcess.add(wo);
                assetIdSet.add(wo.AssetId);
            }
        }
        if(workOrdersToProcess.size() == 0) return;
        Map<Id,Asset> assetMap = new Map<Id, Asset>([SELECT Id, SSVY_Total_of_Work_Orders__c, SSVY_Open_Work_Orders__c FROM Asset WHERE Id IN: assetIdSet]);
        for(WorkOrder wo : workOrdersToProcess){
            assetMap.get(wo.AssetId).SSVY_Total_of_Work_Orders__c--;
            if(wo.Status != 'Closed'){
                assetMap.get(wo.AssetId).SSVY_Open_Work_Orders__c--;
            }
        }
        update assetMap.values();
    }

    private void populateAccountLastVisitedDateAndSiteSurveyCountAfterUpdate(List<SObject> workOrders, Map<Id,SObject> mapOld){
        Set<Id> accountIdSet = new Set<Id>(); //To minimalize number of SOQL queries, query for accounts is done as single query
        Map<Id, Integer> accountIdToChangeSiteSurveyMap = new Map<Id, Integer>();
        RecordType siteSurveyRT = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'Site_Survey'];
        for(SObject o : workOrders){
            WorkOrder wo = (WorkOrder)o;
            WorkOrder oldwo = (WorkOrder)(mapOld.get(o.id));
            if(wo.AccountId != oldwo.AccountId || wo.FSO__Completed_Date__c != oldwo.FSO__Completed_Date__c){
                accountIdSet.add(wo.AccountId);
                accountIdSet.add(oldwo.AccountId);
            }
            system.debug(LoggingLevel.INFO, '****** accountIdSet: ' + accountIdSet);
            if(wo.AccountId != oldwo.AccountId && wo.RecordTypeId == siteSurveyRT.Id && wo.RecordTypeId == oldwo.RecordTypeId){
                if(!accountIdToChangeSiteSurveyMap.containsKey(wo.AccountId)) accountIdToChangeSiteSurveyMap.put(wo.AccountId, 0);
                if(!accountIdToChangeSiteSurveyMap.containsKey(oldwo.AccountId)) accountIdToChangeSiteSurveyMap.put(oldwo.AccountId, 0);
                accountIdToChangeSiteSurveyMap.put(wo.AccountId, accountIdToChangeSiteSurveyMap.get(wo.AccountId) + 1);
                accountIdToChangeSiteSurveyMap.put(oldwo.AccountId, accountIdToChangeSiteSurveyMap.get(oldwo.AccountId) - 1);
            }
            if(wo.AccountId == oldwo.AccountId && wo.RecordTypeId != oldwo.RecordTypeId && (wo.RecordTypeId == siteSurveyRT.Id || oldwo.RecordTypeId == siteSurveyRT.Id)){
                if(wo.RecordTypeId == siteSurveyRT.Id){
                    if(!accountIdToChangeSiteSurveyMap.containsKey(wo.AccountId)) accountIdToChangeSiteSurveyMap.put(wo.AccountId, 0);
                    if(!accountIdToChangeSiteSurveyMap.containsKey(oldwo.AccountId)) accountIdToChangeSiteSurveyMap.put(oldwo.AccountId, 0);
                    accountIdToChangeSiteSurveyMap.put(wo.AccountId, accountIdToChangeSiteSurveyMap.get(wo.AccountId) + 1);
                }
                if(oldwo.RecordTypeId == siteSurveyRT.Id){
                    if(!accountIdToChangeSiteSurveyMap.containsKey(wo.AccountId)) accountIdToChangeSiteSurveyMap.put(wo.AccountId, 0);
                    if(!accountIdToChangeSiteSurveyMap.containsKey(oldwo.AccountId)) accountIdToChangeSiteSurveyMap.put(oldwo.AccountId, 0);
                    accountIdToChangeSiteSurveyMap.put(wo.AccountId, accountIdToChangeSiteSurveyMap.get(wo.AccountId) - 1);
                }
            }
            if(wo.AccountId != oldwo.AccountId && wo.RecordTypeId != oldwo.RecordTypeId && (wo.RecordTypeId == siteSurveyRT.Id || oldwo.RecordTypeId == siteSurveyRT.Id)){
                if(wo.RecordTypeId == siteSurveyRT.Id){
                    if(!accountIdToChangeSiteSurveyMap.containsKey(wo.AccountId)) accountIdToChangeSiteSurveyMap.put(wo.AccountId, 0);
                    accountIdToChangeSiteSurveyMap.put(wo.AccountId, accountIdToChangeSiteSurveyMap.get(wo.AccountId) + 1);
                }
                if(oldwo.RecordTypeId == siteSurveyRT.Id){
                    if(!accountIdToChangeSiteSurveyMap.containsKey(oldwo.AccountId)) accountIdToChangeSiteSurveyMap.put(oldwo.AccountId, 0);
                    accountIdToChangeSiteSurveyMap.put(oldwo.AccountId, accountIdToChangeSiteSurveyMap.get(oldwo.AccountId) -1);
                }
            }
        }
        if(accountIdToChangeSiteSurveyMap.size() == 0 && accountIdSet.size() == 0) return;
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, SSVY_Total_Site_Surveys_Completed__c, SSVY_Last_Visited_Date__c FROM Account WHERE Id IN: accountIdSet OR Id IN: accountIdToChangeSiteSurveyMap.keySet()]);
        List<WorkOrder> woList = [SELECT Id, FSO__Completed_Date__c, AccountId FROM WorkOrder WHERE AccountId IN: accountIdSet];
        Map<Id, List<WorkOrder>> accountIdToWorkOrdersMap = new Map<Id, List<WorkOrder>>();
        for(WorkOrder wo : woList){
            if(!accountIdToWorkOrdersMap.containsKey(wo.AccountId)){
                accountIdToWorkOrdersMap.put(wo.AccountId, new List<WorkOrder>());
            }
            accountIdToWorkOrdersMap.get(wo.AccountId).add(wo);
        }
        Map<Id, Account> accountsToUpdate = new Map <Id, Account>();
        for(Id accId : accountMap.keySet()){
            if(accountIdSet.contains(accId)){
                if(accountIdToWorkOrdersMap.get(accId) == null){
                    accountMap.get(accId).SSVY_Last_Visited_Date__c = null;
                    accountsToUpdate.put(accId, accountMap.get(accId));
                } else {
                    DateTime mostRecentDate;
                    for(WorkOrder wo : accountIdToWorkOrdersMap.get(accId)){
                        if(mostRecentDate == null || mostRecentDate < wo.FSO__Completed_Date__c){
                            mostRecentDate = wo.FSO__Completed_Date__c;
                        }
                    }
                    system.debug(LoggingLevel.INFO, '****** mostRecentDate: ' + mostRecentDate);
                    if(mostRecentDate != null){
                        accountMap.get(accId).SSVY_Last_Visited_Date__c = mostRecentDate.dateGMT();
                    } else {
                        accountMap.get(accId).SSVY_Last_Visited_Date__c = null;
                    }
                    accountsToUpdate.put(accId, accountMap.get(accId));
                }
            }
            if(accountIdToChangeSiteSurveyMap.containsKey(accId)){
                if(accountsToUpdate.containsKey(accId)){
                    accountsToUpdate.get(accId).SSVY_Total_Site_Surveys_Completed__c = accountsToUpdate.get(accId).SSVY_Total_Site_Surveys_Completed__c + accountIdToChangeSiteSurveyMap.get(accId);
                } else {
                    accountMap.get(accId).SSVY_Total_Site_Surveys_Completed__c = accountMap.get(accId).SSVY_Total_Site_Surveys_Completed__c + accountIdToChangeSiteSurveyMap.get(accId);
                    accountsToUpdate.put(accId, accountMap.get(accId));
                }
            }

        }
        system.debug(LoggingLevel.INFO, '****** accountsToUpdate: ' + accountsToUpdate);
        update accountsToUpdate.values();
    }

    private void populateAccountLastVisitedDateAndSiteSurveyCountAfterDelete(List<SObject> workOrders){
        Set<Id> accountIdSet1 = new Set<Id>(); //To minimalize number of SOQL queries query for accounts is done in one query
        Set<Id> accountIdSet2 = new Set<Id>();
        RecordType siteSurveyRT = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'Site_Survey'];
        Map<Id, Integer> accountIdToChangeSiteSurveyMap = new Map<Id, Integer>();
        for(SObject o : workOrders){
            WorkOrder wo = (WorkOrder)o;
            if(wo.FSO__Completed_Date__c != null){
                accountIdSet1.add(wo.AccountId);
            }
            if(wo.RecordTypeId == siteSurveyRT.Id){
                accountIdSet2.add(wo.AccountId);
                if(!accountIdToChangeSiteSurveyMap.containsKey(wo.AccountId)){
                    accountIdToChangeSiteSurveyMap.put(wo.AccountId, 0);
                }
                accountIdToChangeSiteSurveyMap.put(wo.AccountId, accountIdToChangeSiteSurveyMap.get(wo.AccountId) + 1);
            }
        }
        if(accountIdSet1.size() == 0 && accountIdSet2.size() == 0) return;
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, SSVY_Total_Site_Surveys_Completed__c, SSVY_Last_Visited_Date__c FROM Account WHERE Id IN: accountIdSet1 OR Id IN: accountIdSet2]);
        List<WorkOrder> woList = [SELECT Id, FSO__Completed_Date__c, AccountId FROM WorkOrder WHERE AccountId IN: accountIdSet1];
        Map<Id, List<WorkOrder>> accountIdToWorkOrdersMap = new Map<Id, List<WorkOrder>>();
        for(WorkOrder wo : woList){
            if(!accountIdToWorkOrdersMap.containsKey(wo.AccountId)){
                accountIdToWorkOrdersMap.put(wo.AccountId, new List<WorkOrder>());
            }
            accountIdToWorkOrdersMap.get(wo.AccountId).add(wo);
        }
        Map<Id, Account> accountsToUpdate = new Map <Id, Account>();
        for(Id accId : accountMap.keySet()){
            if(accountIdSet1.contains(accId)){
                if(accountIdToWorkOrdersMap.get(accId) == null){
                    accountMap.get(accId).SSVY_Last_Visited_Date__c = null;
                    accountsToUpdate.put(accId, accountMap.get(accId));
                } else {
                    DateTime mostRecentDate;
                    for(WorkOrder wo : accountIdToWorkOrdersMap.get(accId)){
                        if(mostRecentDate == null || mostRecentDate < wo.FSO__Completed_Date__c){
                            mostRecentDate = wo.FSO__Completed_Date__c;
                        }
                    }
                    if(mostRecentDate != null){
                        accountMap.get(accId).SSVY_Last_Visited_Date__c = mostRecentDate.dateGMT();
                    } else {
                        accountMap.get(accId).SSVY_Last_Visited_Date__c = null;
                    }
                    accountsToUpdate.put(accId, accountMap.get(accId));
                }
            }
            if(accountIdSet2.contains(accId)){
                if(accountsToUpdate.containsKey(accId)){
                    accountsToUpdate.get(accId).SSVY_Total_Site_Surveys_Completed__c = accountsToUpdate.get(accId).SSVY_Total_Site_Surveys_Completed__c - accountIdToChangeSiteSurveyMap.get(accId);
                } else {
                    accountMap.get(accId).SSVY_Total_Site_Surveys_Completed__c = accountMap.get(accId).SSVY_Total_Site_Surveys_Completed__c - accountIdToChangeSiteSurveyMap.get(accId);
                    accountsToUpdate.put(accId, accountMap.get(accId));
                }
            }
        }
        update accountsToUpdate.values();
    }

    private void populateAccountLastVisitedDateAndSiteSurveyCountAfterInsert(List<SObject> workOrders){
        Set<Id> accountIdSet1 = new Set<Id>(); //To minimalize number of SOQL queries query for accounts is done in one query
        Set<Id> accountIdSet2 = new Set<Id>();
        RecordType siteSurveyRT = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'Site_Survey'];
        Map<Id, Integer> accountIdToChangeSiteSurveyMap = new Map<Id, Integer>();
        for(SObject o : workOrders){
            WorkOrder wo = (WorkOrder)o;
            if(wo.FSO__Completed_Date__c != null){
                accountIdSet1.add(wo.AccountId);
            }
            if(wo.RecordTypeId == siteSurveyRT.Id){
                accountIdSet2.add(wo.AccountId);
                if(!accountIdToChangeSiteSurveyMap.containsKey(wo.AccountId)){
                    accountIdToChangeSiteSurveyMap.put(wo.AccountId, 0);
                }
                accountIdToChangeSiteSurveyMap.put(wo.AccountId, accountIdToChangeSiteSurveyMap.get(wo.AccountId) + 1);
            }
        }
        if(accountIdSet1.size() == 0 && accountIdSet2.size() == 0) return;
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, SSVY_Total_Site_Surveys_Completed__c, SSVY_Last_Visited_Date__c FROM Account WHERE Id IN: accountIdSet1 OR Id IN: accountIdSet2]);
        List<WorkOrder> woList = [SELECT Id, FSO__Completed_Date__c, AccountId FROM WorkOrder WHERE AccountId IN: accountIdSet1];
        Map<Id, List<WorkOrder>> accountIdToWorkOrdersMap = new Map<Id, List<WorkOrder>>();
        for(WorkOrder wo : woList){
            if(!accountIdToWorkOrdersMap.containsKey(wo.AccountId)){
                accountIdToWorkOrdersMap.put(wo.AccountId, new List<WorkOrder>());
            }
            accountIdToWorkOrdersMap.get(wo.AccountId).add(wo);
        }
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        for(Id accId : accountMap.keySet()){
            if(accountIdSet1.contains(accId)){
                DateTime mostRecentDate;
                for(WorkOrder wo : accountIdToWorkOrdersMap.get(accId)){
                    if(mostRecentDate == null || mostRecentDate < wo.FSO__Completed_Date__c){
                        mostRecentDate = wo.FSO__Completed_Date__c;
                    }
                }
                if(mostRecentDate != null){
                    accountMap.get(accId).SSVY_Last_Visited_Date__c = mostRecentDate.dateGMT();
                } else {
                    accountMap.get(accId).SSVY_Last_Visited_Date__c = null;
                }
                accountsToUpdate.put(accId, accountMap.get(accId));
            }
            if(accountIdSet2.contains(accId)){
                if(accountsToUpdate.containsKey(accId)){
                    accountsToUpdate.get(accId).SSVY_Total_Site_Surveys_Completed__c = accountsToUpdate.get(accId).SSVY_Total_Site_Surveys_Completed__c + accountIdToChangeSiteSurveyMap.get(accId);
                } else {
                    accountMap.get(accId).SSVY_Total_Site_Surveys_Completed__c = accountMap.get(accId).SSVY_Total_Site_Surveys_Completed__c + accountIdToChangeSiteSurveyMap.get(accId);
                    accountsToUpdate.put(accId, accountMap.get(accId));
                }
            }
        }
        update accountsToUpdate.values();
    }*/

    //private Map<Id, UNITY_Service_Contract__c> customerServiceContracts = new Map<Id, UNITY_Service_Contract__c>();
    //private Map<Id, Id> serviceContractIdsByCase = new Map<Id, Id>();

    private void populateMarginFromServiceContract(WorkOrder newWO){
        UNITY_Service_Contract__c serviceContract = customerServiceContracts.get(newWO.UNITY_Customer_Service_Contract__c);
        system.debug('@@ : serviceContract : '+serviceContract);
        if (serviceContract!=null){
            system.debug('@@ : serviceContract.UNITY_Margin__c : '+serviceContract.UNITY_Margin__c);
            newWO.UNITY_Customer_Margin__c = serviceContract.UNITY_Margin__c;
        }
    }

    private void populateCPFromServiceContract(WorkOrder newWO){
        UNITY_Service_Contract__c serviceContract = customerServiceContracts.get(newWO.UNITY_Customer_Service_Contract__c);
        if (serviceContract!=null){
            if (serviceContractLineByTradeMap.get(serviceContract.Id).get(newWO.UNITY_Trade__c) != null && serviceContractLineByTradeMap.get(serviceContract.Id).get(newWO.UNITY_Trade__c).UNITY_Labor_Cost__c != null){
                newWO.UNITY_Customer_Service_Contract_Price__c = serviceContractLineByTradeMap.get(serviceContract.Id).get(newWO.UNITY_Trade__c).UNITY_Labor_Cost__c;
            }else{
                newWO.UNITY_Customer_Service_Contract_Price__c = serviceContract.UNITY_Default_Labor_Rate__c;
            }
        }
    }

    public override void beforeInsert(SObject so){

        WorkOrder newWorkOrder = (WorkOrder) so;


        //populateServiceContract(newWorkOrder); //find the service contract (active, record type = case record type), populate WO service contract field.
        //populateNTE(newWorkOrder); //check if case NTE is blank or 0, if so get NTE from SC you found earlier. if NTE on case is not null or 0, copy case NTE to WO.
        //pullNTEFromCase(newWorkOrder); // Added by Vaishnavi for T-00405

        // autopopulate record
        //UNITY_AutopopulateChildController controller = new UNITY_AutopopulateChildController('WorkOrder');
        //controller.autopopulateFieldsIfApplicable(newWorkOrder);

        // generate a random four digit ping
        newWorkOrder.UNITY_Customer_PIN__c = UNITY_Utils.generateRandomPin();

        if (!UNITY_Constants.isExecutingContext('UNITY_WorkOrderTriggerHandler.populateBusinessUnitAccount')){
            populateBusinessUnitAccount(newWorkOrder);
        }
        populateMarginFromServiceContract(newWorkOrder);
        populateCPFromServiceContract(newWorkOrder);
    }

    public override void beforeUpdate(SObject oldSo, SObject so){

        WorkOrder newWorkOrder = (WorkOrder) so;
        WorkOrder oldWorkOrder = (WorkOrder) oldSo;

        updateVendorAssignment(newWorkOrder,oldWorkOrder);

        autoDispatch(newWorkOrder,oldWorkOrder);

        if (newWorkOrder.UNITY_Vendor_Status__c == UNITY_Constants.WO_VENDOR_STATUS_ASSIGNED){
            workOrderWithVendorAssigned.add(newWorkOrder.Id);
        }

        if (newWorkOrder.UNITY_Assigned_Vendor__c != oldWorkOrder.UNITY_Assigned_Vendor__c && newWorkOrder.UNITY_Assigned_Vendor__c == null){
            newWorkOrder.UNITY_Vendor_Contract__c = null;
        }
        populateCPFromServiceContract(newWorkOrder);
        this.checkOwnerChange(newWorkOrder,oldWorkOrder);
    }

    public override void afterUpdate(SObject oldSo, SObject so){

        WorkOrder newWorkOrder = (WorkOrder) so;
        WorkOrder oldWorkOrder = (WorkOrder) oldSo;
        String nwRTID = UNITY_Constants.WO_NON_WORK_RECORDTYPE;
        Set<WorkOrder> workOrdersToDispatch = new Set<WorkOrder> ();

        if ((newWorkOrder.Status != oldWorkOrder.Status) && newWorkOrder.Status == 'Completed')
            UNITY_Constants.MAX_TRIGGER_EXECUTION = 20;

        if ((newWorkOrder.SFPS_FS_OverallStatus__c != oldWorkOrder.SFPS_FS_OverallStatus__c) && newWorkOrder.SFPS_FS_OverallStatus__c == 'Completed' && newWorkOrder.recordTypeId != nwRTID){
            completedWorkOrders.add(newWorkOrder.Id);
        }

        if (newWorkOrder.UNITY_Include__c != oldWorkOrder.UNITY_Include__c){
            ordersToPropagateIncludeFieldValue.add(newWorkOrder);
        }

        checkForPOUpdate(newWorkOrder,oldWorkOrder);
        
        this.checkForCounterWOOnAssets(newWorkOrder,oldWorkOrder);

    }

    public override void andFinally(){

        // assignmentToUpdate only collected on vendor changed , so for the rest of the operation is empty.
        if(assignmentToUpdate.size()>0){
            update assignmentToUpdate;
        }

        // woToAssignTechnician only collected only workorders to assigne technician , so for the rest of the operation is empty.
        if(woToAssignTechnician.size()>0){
            UNITY_Vendor_Utils.populateSuggestedTechnician(woToAssignTechnician);
        }

        if (!ordersToPropagateIncludeFieldValue.isEmpty()){
            UNITY_WorkOrderTriggerHandlerHelper.propagateIncludeFieldValue(ordersToPropagateIncludeFieldValue);
        }

        this.truckOnsiteProcess();

        //populate vendor service contract
        //populateVendorServiceContract();

        //methods only considered for update only, so for the rest of the operation not considered
        this.createNewDraftPO();
        this.updatePO();

        if(!System.isFuture() && !System.isBatch())
            handleCompletedWorkOrders(completedWorkOrders);
        
        if((closedWorkOrders!=null)&&!closedWorkOrders.isEmpty())countWorkOrdersOnAsset(closedWorkOrders);

        system.debug('>>>>>> WO  HANDLER Limits.getQueries() '+Limits.getQueries());

        system.debug(system.LoggingLevel.ERROR,' >>> assignmentToUpdate: '+assignmentToUpdate);

        system.debug(system.LoggingLevel.ERROR,' >>> woToAssignTechnician: '+woToAssignTechnician);
    }

    @future
    public static void handleCompletedWorkOrders(Set<Id> woids){

        if (!woids.isEmpty()){
            UNITY_WorkOrderTriggerHandlerHelper.adjustLaborHours(woids);
        }
    }

    /*
    * @name        : autoDispatch
    * @argument 1  : WorkOrder new record
    * @argument 2  : WorkOrder old record
    * @note        : Update vendor assignments Status from Vendor Status on WO and if the status is "Accepted" then update some fields on WO too
    *                Do not update vendor assignment with "No Candidate".
    */
    private void updateVendorAssignment(WorkOrder newWorkOrder, WorkOrder oldWorkOrder){
        system.debug('>>> new status '+ newWorkOrder.UNITY_Vendor_Status__c);
        system.debug('>>> old status '+ oldWorkOrder.UNITY_Vendor_Status__c);
        system.debug('>>> new vendorId '+ newWorkOrder.UNITY_Assigned_Vendor__c);
        system.debug('>>> old vendorId '+ oldWorkOrder.UNITY_Assigned_Vendor__c);
        
        if(newWorkOrder.UNITY_Vendor_Status__c != 'Assigned' ) newWorkOrder.UNITY_WO_Retract_At__c = null;

        if((newWorkOrder.UNITY_Vendor_Status__c != oldWorkOrder.UNITY_Vendor_Status__c) && String.isNotBlank(newWorkOrder.UNITY_Vendor_Status__c)
            && ((newWorkOrder.UNITY_Vendor_Status__c.indexOf('Rejected') == 0)||(newWorkOrder.UNITY_Vendor_Status__c == 'Accepted')||(newWorkOrder.UNITY_Vendor_Status__c == 'Assigned'))
            && (newWorkOrder.UNITY_Assigned_Vendor__c != null) ){

            if(woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c)!= null){

                woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c).Status__c = newWorkOrder.UNITY_Vendor_Status__c;

                assignmentToUpdate.add(woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c));

                if(newWorkOrder.UNITY_Vendor_Status__c == UNITY_Constants.WO_VENDOR_STATUS_ASSIGNED){

                    newWorkOrder.UNITY_Vendor_PIN__c             = woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c).PIN__c ;

                    newWorkOrder.UNITY_Initial_Vendor_PO_Cost__c = woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c).Initial_PO__r.UNITY_Total_Cost__c;

                    woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c).OON__c                = newWorkOrder.UNITY_OON_Vendor_Assigned__c;

                    woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c).Last_Assigned__c      = UNITY_Utils.getDateTime();

                    woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c).Assignment_Warning__c = newWorkOrder.UNITY_Vendor_Assignment_Warning__c;

                    if(vendorsData.get(newWorkOrder.UNITY_Assigned_Vendor__c) != null){
                        newWorkOrder.UNITY_Vendor_Email__c = vendorsData.get(newWorkOrder.UNITY_Assigned_Vendor__c).Account_Email__c;
                        if(vendorsData.get(newWorkOrder.UNITY_Assigned_Vendor__c).UNITY_Miner_Regional_Office__c){
                            woToAssignTechnician.add(newWorkOrder);
                        }
                    }
                }

                if(newWorkOrder.UNITY_Vendor_Status__c.indexOf('Rejected') == 0){

                    newWorkOrder.UNITY_Vendor_PIN__c                = null;
                    newWorkOrder.UNITY_Current_PO__c                = null;
                    newWorkOrder.UNITY_Vendor_Email__c              = null;
                    newWorkOrder.UNITY_WO_Retract_At__c             = null;
                    newWorkOrder.UNITY_Assigned_Vendor__c           = null;
                    newWorkOrder.UNITY_Accepted_Vendor__c           = null;
                    newWorkOrder.UNITY_Vendor_Dispatcher__c         = null;
                    newWorkOrder.UNITY_Vendor_Accept_Date__c        = null;
                    newWorkOrder.UNITY_Vendor_PO_Sent_Date__c       = null;
                    newWorkOrder.UNITY_Suggested_Work_Date__c       = null;
                    newWorkOrder.UNITY_OON_Vendor_Assigned__c       = false;
                    newWorkOrder.UNITY_Suggested_Technician__c      = null;
                    newWorkOrder.UNITY_Initial_Vendor_PO_Cost__c    = null;
                    newWorkOrder.UNITY_Vendor_Assignment_Warning__c = null;


                    //newWorkOrder.UNITY_Vendor_Accept_Date__c      = null;
                    //newWorkOrder.UNITY_Vendor_Last_Assigned__c    = null;

                }

                if(newWorkOrder.UNITY_Vendor_Status__c == UNITY_Constants.WO_VENDOR_STATUS_ACCEPTED){

                     newWorkOrder.UNITY_Auto_Dispatch__c      = false;
                     newWorkOrder.UNITY_WO_Retract_At__c      = null;
                     newWorkOrder.UNITY_Accepted_Vendor__c    = newWorkOrder.UNITY_Assigned_Vendor__c;
                     newWorkOrder.UNITY_Vendor_Accept_Date__c = UNITY_Utils.getDateTime();

                     if(woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c).Initial_PO__c  !=null){
                        newWorkOrder.UNITY_Current_PO__c      = woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c).Initial_PO__c;
                        newWorkOrder.UNITY_Vendor_Contract__c = woVendorToAssignment.get(newWorkOrder.id +'-'+newWorkOrder.UNITY_Assigned_Vendor__c).Initial_PO__r.UNITY_Vendor_Contract__c;
                     }

                     if(vendorsData.get(newWorkOrder.UNITY_Assigned_Vendor__c) != null){
                        newWorkOrder.UNITY_Vendor_Dispatcher__c  = vendorsData.get(newWorkOrder.UNITY_Assigned_Vendor__c).UNITY_Dispatcher__c;
                        if (vendorsData.get(newWorkOrder.UNITY_Assigned_Vendor__c).UNITY_Dispatcher__c != null) newWorkOrder.OwnerId = vendorsData.get(newWorkOrder.UNITY_Assigned_Vendor__c).UNITY_Dispatcher__c;
                            else if(newWorkOrder.UNITY_Agent__c != null) newWorkOrder.OwnerId = newWorkOrder.UNITY_Agent__c;
                     }
                 }
            }
        }
    }

    /*
    * @name        : checkForPOUpdate
    * @argument 1  : WorkOrder new record
    * @argument 2  : WorkOrder old record
    * @note        :
    */
    private void checkForPOUpdate(WorkOrder newWO, WorkOrder oldWO){
        system.debug('>>>> checkForPOUpdate new status '+newWO.UNITY_Vendor_Status__c);
        system.debug('>>>> checkForPOUpdate new vendor  '+newWO.UNITY_Assigned_Vendor__c);
        system.debug('>>>> checkForPOUpdate old status '+oldWO.UNITY_Vendor_Status__c);
        system.debug('>>>> checkForPOUpdate old status '+oldWO.UNITY_Assigned_Vendor__c);

        // BE SURE THET THE VENDOR STATUS CHANGED AND THE RECORD HAS VENDORS ASSIGNED AND THE CURRENT PO IS POPULATED
        // THIS METHOD IS CALLED IN THE AFTER TRIGGER SO THE "UNITY_Assigned_Vendor__c" CAN BE null FOR THE NEW WO RECORD IF IT WAS Rejected
        boolean validated_WO = ((newWO.UNITY_Vendor_Status__c != oldWO.UNITY_Vendor_Status__c)&&(oldWO.UNITY_Assigned_Vendor__c != null));

        boolean validated_ACCEPTED  = (newWO.UNITY_Vendor_Status__c == UNITY_Constants.WO_VENDOR_STATUS_ACCEPTED);

        boolean validated_REJECTED  = ((newWO.UNITY_Vendor_Status__c!=null)&&(newWO.UNITY_Vendor_Status__c.indexOf('Rejected')==0));

        String  orderStatus         = null;

        if(validated_WO && validated_ACCEPTED)
            orderStatus = UNITY_Constants.ORDER_STATUS_ACCEPTED;
        else
            if(validated_WO && validated_REJECTED)
                orderStatus = UNITY_Constants.ORDER_STATUS_REJECTED;


        if(orderStatus != null){
            if(   wo_vendorAssignments.containsKey(newWO.id)
               && wo_vendorAssignments.get(newWO.id).containsKey(oldWO.UNITY_Assigned_Vendor__c)
               &&(wo_vendorAssignments.get(newWO.id).get(oldWO.UNITY_Assigned_Vendor__c).Initial_PO__c != null)){

                Order aux_order  = new Order();
                aux_order.Id     = wo_vendorAssignments.get(newWO.id).get(oldWO.UNITY_Assigned_Vendor__c).Initial_PO__c;
                aux_order.Status = orderStatus;
                poToUpdate.add(aux_order);
            }
        }
    }

    /*
    * @name        : autoDispatch
    * @argument 1  : WorkOrder new record
    * @argument 2  : WorkOrder old record
    * @note        : Assign vendor to work orders based on ranking and score, depending on the preference order
    */
    private void autoDispatch(WorkOrder newWO, WorkOrder oldWO){
        system.debug('>>> autoDispatch new status '+ newWO.UNITY_Vendor_Status__c);
        system.debug('>>> autoDispatch oldWO status '+ oldWO.UNITY_Vendor_Status__c);
        system.debug('Workorder IDs to dispatch:' + workOrdersIdToDispatch.size());
        if( workOrdersIdToDispatch.contains(newWO.id) && (newWO.UNITY_Vendor_Status__c != oldWO.UNITY_Vendor_Status__c)){
            
            // get list of vendors at location of the work order
            List<UNITY_wrapperVendorByTrade> vendorsAtLocation = vendors.get(newWO.id);
            system.debug('vendorsAtLocation size: ' + vendorsAtLocation.size());
            // flag for assigned vendor
            boolean foundVendorForAssignment = false;

            // check if we have some candidate
            if( (vendorsAtLocation != null) && (vendorsAtLocation.size() > 0) ){
                System.debug('We are autodispatching - do we have our candidates? : ');
                integer i = 0;
                // go through all vendors and find the first Candidate available for the WO
                while( (i < vendorsAtLocation.size()) && (!foundVendorForAssignment) ){

                    UNITY_wrapperVendorByTrade onVendorW = vendorsAtLocation.get(i);
                    System.debug('onVendorW = ' + onVendorW);
                    if( (newWO.UNITY_Assigned_Vendor__c != onVendorW.id)&&(onVendorW.assignment != null)&&(onVendorW.assignedStatus == UNITY_Constants.WO_VENDOR_STATUS_CANDIDATE) ){

                        if(!onVendorW.willBeCandidateBelowMargin && !onVendorW.willBeCandidateOffHours){
                            System.debug('woVendorToAssignment Map check:' + woVendorToAssignment);
                            if( (woVendorToAssignment.get(newWO.id +'-'+onVendorW.id)!= null) ){

                                // update work order fields
                                newWO.UNITY_Assigned_Vendor__c        = onVendorW.id;
                                newWO.UNITY_Vendor_Status__c          = UNITY_Constants.WO_VENDOR_STATUS_ASSIGNED;
                                newWO.UNITY_Vendor_Last_Assigned__c   = UNITY_Utils.getDateTime();
                                newWO.UNITY_Vendor_Email__c           = onVendorW.email;
                                newWO.UNITY_Vendor_PIN__c             = woVendorToAssignment.get(newWO.id +'-'+onVendorW.id).PIN__c;
                                newWO.UNITY_Initial_Vendor_PO_Cost__c = woVendorToAssignment.get(newWO.id +'-'+onVendorW.id).Initial_PO__r.UNITY_Total_Cost__c;
                                newWO.UNITY_WO_Retract_At__c              = null;
                                //newWO.UNITY_Current_PO__c             = woVendorToAssignment.get(newWO.id +'-'+onVendorW.id).Initial_PO__c;

                                if(onVendorW.isMiner){
                                    woToAssignTechnician.add(newWO);
                                }

                                //woVendorToAssignment.get(newWO.id +'-'+onVendorW.id).Status__c        = newWO.UNITY_Vendor_Status__c;
                                //woVendorToAssignment.get(newWO.id +'-'+onVendorW.id).Last_Assigned__c = newWO.UNITY_Vendor_Last_Assigned__c;
                                onVendorW.assignment.Status__c        = newWO.UNITY_Vendor_Status__c;
                                onVendorW.assignment.Last_Assigned__c = newWO.UNITY_Vendor_Last_Assigned__c;

                                assignmentToUpdate.add( onVendorW.assignment);

                                if(newWO.UNITY_PO_Review_Pending__c){
                                    if((woVendorToAssignment.get(newWO.id +'-'+onVendorW.id).Initial_PO__c == null)||(woVendorToAssignment.get(newWO.id +'-'+onVendorW.id).Initial_PO__r.Status !='Final'))
                                        //Throw new WorkOrderException('When PO Pending Review flag is checked, PO has to be created first and in final status. Work Order Id ['+newWO.id+'] ');
                                        System.debug('When PO Pending Review flag is checked, PO has to be created first and in final status. Work Order Id ['+newWO.id+'] ');
                                }else createNewDraftPO.put(onVendorW.assignment.id,onVendorW);

                            }
                            foundVendorForAssignment = true;

                        }else{

                            if(woVendorToAssignment.get(newWO.id +'-'+onVendorW.id)!= null){

                                if(onVendorW.willBeCandidateBelowMargin){
                                     woVendorToAssignment.get(newWO.id +'-'+onVendorW.id).Status__c = UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_CANDIDATE_BELOW_MARGIN;
                                     assignmentToUpdate.add( woVendorToAssignment.get(newWO.id +'-'+onVendorW.id));
                                }else if(onVendorW.willBeCandidateOffHours){
                                     woVendorToAssignment.get(newWO.id +'-'+onVendorW.id).Status__c = UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_CANDIDATE_OFF_HOURS;
                                     assignmentToUpdate.add( woVendorToAssignment.get(newWO.id +'-'+onVendorW.id));
                                }
                            }
                        }
                        if (newWO.UNITY_Dispatch_Attempts__c == null) newWO.UNITY_Dispatch_Attempts__c = 1;
                            else newWO.UNITY_Dispatch_Attempts__c = newWO.UNITY_Dispatch_Attempts__c + 1;

                    }
                    i++;
                }
            }

            // if we did not find any vendors then we do not have candidates for WO
            if(!foundVendorForAssignment){
                System.debug('=====CLAY: Did not find vendor to assign.');
                newWO.UNITY_Vendor_Status__c = UNITY_Constants.WO_VENDOR_STATUS_NO_CANDIDATE;
                newWO.UNITY_Assigned_Vendor__c = null;
                newWO.UNITY_Auto_Dispatch__c = false;
            }
        }
    }

    /*
    * @name       : captureMiddlemanCustomer
    * @arguments  : WorkOrder new SObject
    * @note       : Populate UNITY_Customer__c fields on Work Order from the Case related.
    *               Mapping : WorkOrder.UNITY_Customer__c = Case.UNITY_Customer__c
    *                         WorkOrder.AccountId = Case.AccountId
    */
    /*
    public void captureMiddlemanCustomer(WorkOrder newWorkOrder){

        id caseId = newWorkOrder.CaseId;

        if((caseId != null) && (parentCases.get(caseId) != null)){
            newWorkOrder.put( 'UNITY_Customer__c' , parentCases.get(caseId).get('UNITY_Customer__c') );
            newWorkOrder.put( 'AccountId'   , parentCases.get(caseId).get('AccountId'));

        }

    }*/

    public void updatePO(){

        if(poToUpdate.size()>0){
          update poToUpdate;
        }
    }

    public void updateToFinalOrder(list<Order> orders){

        list<Order> toUpdate = new list<Order>();
        if((orders.size()>0) && !UNITY_Constants.isExecutingContext('UNITY_WorkOrderTriggerHandler.insertCurrentPO')){
            for(Order onOrder :orders){
                WorkOrder onWO = (WorkOrder)Trigger.newMap.get(onOrder.FSO__WorkOrder__c);
                if(!onWO.UNITY_PO_Review_Pending__c){
                    Order finalOrder = new Order();
                    finalOrder.id = onOrder.id;
                    finalOrder.Status = 'Final';
                    toUpdate.add(finalOrder);
                }
            }
            update toUpdate;
        }
    }

    /*
    * @name       : pullNTEFromCase
    * @arguments  : WorkOrder new SObject
    * Programmer  : Vaishnavi
    *
    */
    /*
    public void pullNTEFromCase(WorkOrder newWorkOrder){

        id caseId = newWorkOrder.CaseId;

        if((caseId != null) && (parentCases.get(caseId) != null)){

            if(newWorkOrder.UNITY_Not_To_Exceed_NTE__c == 0.0) // If NTE in Work Order is 0.0, pull NTE Value from Case
            {
                newWorkOrder.put( 'UNITY_Not_To_Exceed_NTE__c' , parentCases.get(caseId).get('UNITY_NTE_Threshold__c'));
            //System.debug('Print Wo' + newWorkOrder);
            }
        }

    }*/

    /*
    * @name        : populateNTE
    * @arguments   : WorkOrder new SObject
    * Programmer   : Vaishnavi
    *
    */
    public void populateNTE(WorkOrder newWorkOrder){

        Id caseId = newWorkOrder.CaseId;
        Id scId = newWorkOrder.UNITY_Customer_Service_Contract__c;

        Double SCNTE;
        Double scliNTE;
        Double caseNTE ; //= newWorkOrder.Case.UNITY_NTE_Threshold__c;
        String WOTrade;
        String scliTrade;

        List<WorkOrder> woList= [SELECT UNITY_Customer_Service_Contract__r.UNITY_Default_NTE__c,UNITY_Trade__c, Case.UNITY_NTE_Threshold__c FROM WorkOrder WHERE CaseId =:caseId];
        for(WorkOrder woListObj :woList){

            SCNTE = woListObj.UNITY_Customer_Service_Contract__r.UNITY_Default_NTE__c;
            caseNTE = woListObj.Case.UNITY_NTE_Threshold__c;
            WOTrade = String.valueOf(woListObj.UNITY_Trade__c);
        }
        System.debug('SCNTE' +SCNTE);
        System.debug('WOTRADE' +WOTRADE);

        /*
        if((caseId != null) && (caseNTE!=0.0 || caseNTE!=0)){
            newWorkOrder.put( 'UNITY_Not_To_Exceed_NTE__c' , parentCases.get(caseId).get('UNITY_NTE_Threshold__c'));
            System.debug('CASENTECopied');
        }
        else
        {
          List<UNITY_Service_Contract_Line_Item__c> scli =[SELECT Id,Name,UNITY_Trade__c,Unity_NTE__c,UNITY_Service_Contract__c FROM UNITY_Service_Contract_Line_Item__c WHERE UNITY_Service_Contract__c =:scId AND RecordType.Name = 'Hourly Rate'];
          for(UNITY_Service_Contract_Line_Item__c scliObj : scli){
          scliNTE = scliObj.Unity_NTE__c;
          scliTrade = String.valueOf(scliObj.UNITY_Trade__c);
          System.debug('SCLI' +scliNTE+ 'Trade' + scliTrade);

          }
          if(scli.size()>0 && ((scliTrade).equals(WOTrade)))
          {
              newWorkOrder.UNITY_Not_To_Exceed_NTE__c = scliNTE;
              System.debug('Trade Equal');
          }else
          {
              newWorkOrder.UNITY_Not_To_Exceed_NTE__c = SCNTE;
              System.debug('Trade Not Equal');
          }


        }*/
    }
    /*
    * @name        : populateServiceContract
    * @arguments   : WorkOrder new SObject
    * Programmer   : Vaishnavi
    *
    */

    public void populateServiceContract(WorkOrder newWorkOrder)
    {

        id caseId = newWorkOrder.CaseId;
        id customerId = newWorkOrder.UNITY_Customer__c;
        String caseRecordType;
        //String caserecordType = String.valueOf(newWorkOrder.Case.RecordType);
        List<Case> caseRT =[SELECT Id, RecordType.Name FROM Case WHERE Id =:caseId];
        for(Case caseRTObj : caseRT)
        {
        caseRecordType = caseRTObj.RecordType.Name;
        System.debug('Printing caseRT' + caseRecordType);
        }
        if(caseId != null)
        {
             List<UNITY_Service_Contract__c> matchingSCRT = [SELECT Id, Name, RecordType.Name,UNITY_Default_NTE__c FROM UNITY_Service_Contract__c WHERE RecordType.Name =: caseRecordType AND UNITY_IS_Active__c = True AND UNITY_Account__c =:customerId];
             System.debug('Fetch SC' +matchingSCRT);

             if(matchingSCRT.size()>0){
             newWorkOrder.put('UNITY_Customer_Service_Contract__c', matchingSCRT[0].Id);
             }

        }

    }


    public void applyTemplates(){

        for (sObject iter: trigger.new){

            WorkOrder workOrder = (WorkOrder)iter;

            orderWithTemplate = new List<WorkOrder>();

            if(workOrder.UNITY_Template_Configuration__c  != null){
                recordIdTemplateId.put(workOrder.id, workOrder.UNITY_Template_Configuration__c );
                orderWithTemplate.add(workOrder);
            }
        }

        UNITY_Utils.applyTemplates(recordIdTemplateId, orderWithTemplate, 'UNITY_Template_Configuration__c', 'WorkOrder');
    }


    public void propagateBusinessUnitAccount(){

        List<Order> ordersToUpdate = new List<Order>();
        List<UNITY_Proposal__c> proposalsToUpdate = new List<UNITY_Proposal__c>();

        Set<Id> workOrderBUChanged = new Set<Id>();

        if (Trigger.isUpdate){

            for (SObject iter: trigger.new){

                if ( ((WorkOrder)iter).UNITY_Business_Unit_Account__c != ((WorkOrder)trigger.oldMap.get(iter.id)).UNITY_Business_Unit_Account__c){
                    workOrderBUChanged.add(iter.Id);
                }
            }
        }

        List<Order> relatedOrders = [select id ,FSO__WorkOrder__c from Order where FSO__WorkOrder__c in: workOrderBUChanged];

        for (Order iter: relatedOrders){
            iter.UNITY_Business_Unit_Account__c = ((WorkOrder)(trigger.newMap.get(iter.FSO__WorkOrder__c))).UNITY_Business_Unit_Account__c;
            ordersToUpdate.add(iter);
        }

        List<UNITY_Proposal__c> proposalList = [select id, UNITY_Work_Order__c from UNITY_Proposal__c where UNITY_Work_Order__c in:workOrderBUChanged];

        for (UNITY_Proposal__c iter: proposalList){
            iter.UNITY_Business_Unit_Account__c = ((WorkOrder)(trigger.newMap.get(iter.UNITY_Work_Order__c))).UNITY_Business_Unit_Account__c;
            proposalsToUpdate.add(iter);
        }

         // ordersToUpdate is not empty for update operation consider
        update ordersToUpdate;
        update proposalsToUpdate;
    }

    public void populateRelatedCasesMap(){

        Set<Id> caseIdSet = new Set<Id>();

        for (SObject wo: trigger.new){
            caseIdSet.add(((WorkOrder)wo).CaseId);
        }

        List<Case> caseList = [select id, UNITY_Business_Unit_Account__c from Case where id in:caseIdSet];

        for (Case iter: caseList){
            relatedCasesMap.put(iter.Id, iter);
        }
    }

    public void createNewDraftPO(){

        Map<id,Order> orderToInsert = new Map<id,Order>();
        list<UNITY_Vendor_Assignment__c> vAssignmentToUpdate = new list<UNITY_Vendor_Assignment__c>();

        if(createNewDraftPO.size()>0){
            Map<String,Object> order_fields = null;
            Order newOrder = null;
            for(UNITY_wrapperVendorByTrade vendor :createNewDraftPO.values()){

                WorkOrder wo = (WorkOrder)Trigger.newMap.get(vendor.assignment.Work_Order__c);
                order_fields = new Map<String,Object>();
                order_fields.put('FSO__WorkOrder__c'    , vendor.assignment.Work_Order__c);
                order_fields.put('UNITY_Vendor__c'      , vendor.id);
                order_fields.put('UNITY_PO_Template__c' , wo.UNITY_PO_Template__c);
                order_fields.put('Status'               , 'Draft');
                order_fields.put('EffectiveDate'        , Date.today());
                order_fields.put('AccountId'            , wo.AccountId);
                order_fields.put('UNITY_Business_Unit__c', wo.UNITY_Business_Unit__c);
                newOrder = (Order)UNITY_Utils.createObject(Order.getSObjectType(),order_fields);
                orderToInsert.put(vendor.assignment.id, newOrder);

            }
            insert orderToInsert.values();

            Set<id> orderIds = new Set<id>();
            for(id vaId :orderToInsert.keySet()){
                createNewDraftPO.get(vaId).assignment.Initial_PO__c = orderToInsert.get(vaId).id;
                vAssignmentToUpdate.add(createNewDraftPO.get(vaId).assignment);
                orderIds.add(orderToInsert.get(vaId).id);
            }
            update vAssignmentToUpdate;

            if(!orderIds.isEmpty()) {
                Map<id, Order> aux_orderUpdetedFields = new Map<id, Order>([SELECT id, Status, UNITY_Total_Cost__c FROM Order WHERE id IN :orderIds]);

                for(UNITY_wrapperVendorByTrade vendor :createNewDraftPO.values()){
                    if(aux_orderUpdetedFields.get(vendor.assignment.Initial_PO__c)!=null){
                        WorkOrder wo = (WorkOrder)Trigger.newMap.get(vendor.assignment.Work_Order__c);
                        wo.UNITY_Initial_Vendor_PO_Cost__c = aux_orderUpdetedFields.get(vendor.assignment.Initial_PO__c).UNITY_Total_Cost__c;
                    }
                }
            }

            updateToFinalOrder(orderToInsert.values());
        }
    }

    public void populateBusinessUnitAccount(WorkOrder wo){

        if (relatedCasesMap.get(wo.CaseId) != null){
            wo.UNITY_Business_Unit_Account__c = relatedCasesMap.get(wo.CaseId).UNITY_Business_Unit_Account__c;
        }
    }

    public void populateVendorServiceContract(){

        List<Id> assignedVendorList = new List<Id>();

        if (!workOrderWithVendorAssigned.isEmpty()){

            for (Id iter: workOrderWithVendorAssigned){

                WorkOrder wo = (WorkOrder)trigger.newMap.get(iter);

                assignedVendorList.add(wo.UNITY_Assigned_Vendor__c);
            }

            //Map<Vendor Id, ServiceContract>
          Map<Id, List<UNITY_Service_Contract__c>> vendorContractMap = new Map<Id, List<UNITY_Service_Contract__c>>();

          if(!assignedVendorList.isEmpty()) {
                List<UNITY_Service_Contract__c>  vendorContractList = [Select Id, UNITY_Business_Unit__c, UNITY_Account__c from UNITY_Service_Contract__c where UNITY_Account__c in :assignedVendorList and UNITY_IS_Active__c = true and UNITY_Service_Contract__c.RecordTypeId =:UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE];

                for (UNITY_Service_Contract__c iter: vendorContractList){

                  if (vendorContractMap.get(iter.UNITY_Account__c) == null){

                      vendorContractMap.put(iter.UNITY_Account__c, new List<UNITY_Service_Contract__c>());
                  }

                  vendorContractMap.get(iter.UNITY_Account__c).add(iter);
                }
          }


          for (Id iter: workOrderWithVendorAssigned){

              WorkOrder wo = (WorkOrder)trigger.newMap.get(iter);

              List<UNITY_Service_Contract__c> relatedVendorContract = vendorContractMap.get(wo.UNITY_Assigned_Vendor__c);

              if (relatedVendorContract != null){

                  for (UNITY_Service_Contract__c contract: relatedVendorContract){

                      if (contract.UNITY_Business_Unit__c != null){

                          Set<String> businessUnitValues = new Set<String>(contract.UNITY_Business_Unit__c.split(';'));

                          if(businessUnitValues.contains(wo.UNITY_Business_Unit__c)){
                              wo.UNITY_Vendor_Contract__c = contract.Id;
                              break;
                          }
                      }
                  }
              }
          }
        }

    }

    /*
     * Name   : getLocationsByDriver
     * Param  : Set<Id>
     * Return : Map<Id,FSO__Location__c>
     * Note   : Search locations by UNTIY_Draiver__c filter 
     */
    private Map<Id,FSO__Location__c> getLocationsByDriver(Set<Id> drivers){
        return new Map<Id,FSO__Location__c>([SELECT Id, UNITY_Driver__c FROM FSO__Location__c WHERE UNITY_Driver__c IN :drivers]);
    }

    /*
     * Name    : checkOwnerChange
     * Param 1 : WorkOrder new record 
     * Param 2 : WorkOrder old record 
     * Note    : check if the record owner changed 
     */
    private void checkOwnerChange(WorkOrder newWO, WorkOrder oldWO){
        if(newWO.OwnerId != oldWO.OwnerId ){
            if(workOrderChangedOwners.get(newWO.OwnerId)==null) workOrderChangedOwners.put(newWO.OwnerId, new Set<Id>());
            workOrderChangedOwners.get(newWO.OwnerId).add(newWO.Id);
        }
    }

    /*
     * Name   : truckOnsiteProcess
     * Note   : If the WO.Owner does not have locations then set WO.UNITY_Truck_On_Site__c = null
     */
    private void truckOnsiteProcess(){

        Map<Id,FSO__Location__c> locationsByDriver = new Map<Id,FSO__Location__c>();
        Map<Id,List<FSO__Location__c>> driverLocationsMap = new Map<Id,List<FSO__Location__c>>();
        if(workOrderChangedOwners!=null && !workOrderChangedOwners.isEmpty()){
            locationsByDriver = this.getLocationsByDriver(workOrderChangedOwners.keySet());
            for(FSO__Location__c location :locationsByDriver.values()){
                if(driverLocationsMap.get(location.UNITY_Driver__c)==null) driverLocationsMap.put(location.UNITY_Driver__c, new List<FSO__Location__c>());
                driverLocationsMap.get(location.UNITY_Driver__c).add(location);
            }
            for(Id driverId :workOrderChangedOwners.keySet()){
                if((driverLocationsMap.get(driverId)==null))
                    for(Id woId :workOrderChangedOwners.get(driverId))
                        Trigger.newMap.get(woId).put('UNITY_Truck_On_Site__c',null);
                    
                
                else if((driverLocationsMap.get(driverId)!=null)&& !driverLocationsMap.get(driverId).isEmpty())
                    for(Id woId :workOrderChangedOwners.get(driverId))
                        Trigger.newMap.get(woId).put('UNITY_Truck_On_Site__c',driverLocationsMap.get(driverId).get(0).Id);
                    
                
            }
        }
    }

    // Update manual sharing with workorder.Account changed.
    private void updateManualSharing() {
        List<SObject> sobjects = new List<SObject>();
        List<SObject> sobjectsToDelete = new List<SObject>();
        List<Id> parentIds = new List<Id>();
        
        //retrieve the users associated to the contacts
        Map<Id,List<Id>> accountIdUserIdMap = new Map<Id,List<Id>>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> oldAccountIds = new Set<Id>();
        system.debug(' ---> Trigger.old :'+Trigger.old);
        system.debug(' ---> Trigger.new :'+Trigger.new);
        for(WorkOrder workorder : (List<WorkOrder>)Trigger.new) {
            WorkOrder oldworkorder;
            if(Trigger.oldMap != null) {
                oldworkorder = (WorkOrder)Trigger.oldMap.get(workorder.Id);
            }
            if(oldworkorder == null || workorder.AccountId != oldworkorder.AccountId) {
                accountIds.add(workorder.AccountId);
                if(oldworkorder != null) {
                   oldAccountIds.add(oldworkorder.AccountId);
                }
            }
        }
        System.debug(' ---> accountIds :'+accountIds);
        if(!accountIds.isEmpty()){
            for(User user : [SELECT Id,Contact.AccountId FROM User 
                             WHERE Contact.AccountId != null AND 
                                   (Contact.AccountId IN:accountIds OR
                                    Contact.AccountId IN:oldAccountIds) AND
                                   ProfileId IN (SELECT Id FROM Profile WHERE Name = 'UNITY_Customer')]) {
                if(accountIdUserIdMap.get(user.Contact.AccountId) == null) {
                    accountIdUserIdMap.put(user.Contact.AccountId, new List<Id>());
                }
                accountIdUserIdMap.get(user.Contact.AccountId).add(user.Id);   
            }
    
            system.debug('>>> accountIdUserIdMap'+accountIdUserIdMap);
            for(WorkOrder workOrderNew : (List<WorkOrder>)Trigger.new) {
                WorkOrder workOrderOld;
                if(Trigger.oldMap != null) {
                    workOrderOld =(WorkOrder)Trigger.oldMap.get(workOrderNew.Id);
                }
                if(accountIds.contains(workOrderNew.AccountId) && 
                   accountIdUserIdMap.get(workOrderNew.AccountId) != null) {
                    for(Id userId : accountIdUserIdMap.get(workOrderNew.AccountId)) {
                        sobjects.add(workOrderNew);
                        parentIds.add(userId);
                    }
                }
                if(workOrderOld != null && oldAccountIds.contains(workOrderOld.AccountId)) {
                    sobjectsToDelete.add(workOrderOld);
                } 
            }
                    
           // update the share object when the field workOrder.Account change,
           // deleting the invalid share objects.
           UNITY_SharingUtil.manualShareDelete(sobjectsToDelete,WorkOrderShare.SObjectType);
            
           System.debug('creating manual sharing'+sobjects+parentIds);
           UNITY_SharingUtil.manualShareCreateReadOnlyBulk(sobjects,parentIds,WorkOrderShare.SObjectType);
        }

    }
    
    /*
    * @name        : checkForCounterWOOnAssets
    * @argument 1  : WorkOrder new record
    * @argument 2  : WorkOrder old record
    * @note        :
    */
    private void checkForCounterWOOnAssets(WorkOrder newWO, WorkOrder oldWO){

        Boolean statusChanged = (newWO.Status!=oldWO.Status);

        if(statusChanged && (newWO.Status == 'Closed')) closedWorkOrders.add(newWO.Id);
    }

    @future
    private static void countWorkOrdersOnAsset(Set<id> woIds){
        UNITY_Utils.countWorkOrdersOnAsset(woIds, WorkOrder.getSObjectType());
    }


    class WorkOrderException extends Exception{}

}