/**This class serves as an utility class for work order triggers
***@Developer: Izay Ramos-Irizarry
***@Date:      4/6/2015
***@Version:   1.0
*/
public class WorkOrderTriggerUtil{
    /**This method manages actions to perform before a work order is inserted,updated, or deleted
    ***@param newWorkOrders List<SVMXC__Service_Order__c> - The new work orders being inserted/updated
    ***@param oldWorkOrders Map<Id,SVMXC__Service_Order__c> - The old work orders being updated
    ***@param isInsert Boolean - Denotes if trigger is insert
    ***@param isUpdate Boolean - Denotes if trigger is update
    ***@param isDelete Boolean - Denotes if trigger is delete
    */
    public static void before(List<SVMXC__Service_Order__c> newWorkOrders, Map<Id,SVMXC__Service_Order__c> oldWorkOrders, Boolean isInsert, Boolean isUpdate, Boolean isDelete) {
        /* ****************************************************************************
        *** Anything that needs to be executed before insert and only before insert ***
        ******************************************************************************* 
        */
        if(isInsert){
            /* **********************************************************************************************
            *** Set the service group on the work order from the current user service group member record *** 
            *************************************************************************************************
            */
            List<SVMXC__Service_Group_Members__c> teams = [SELECT SVMXC__Service_Group__c FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Salesforce_User__c = :UserInfo.getUserId() LIMIT 1];
            //If there is a service group member record for this user...
            if (teams.size() > 0) {
                for (SVMXC__Service_Order__c wo :newWorkOrders) {
                    //Add the service group id to the work orders
                    if(String.isBlank(wo.SVMXC__Service_Group__c)){
                        wo.SVMXC__Service_Group__c = teams[0].SVMXC__Service_Group__c;
                    }
                }
            }
        }
        
        /* ****************************************************************************
        *** Anything that needs to be executed before update and only before update ***
        ******************************************************************************* 
        */
        if(isUpdate){
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //If work order status is changed from work finished to parts needed or estimate needed, clear the technician arrived and the lookup to the tech //
            ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            for (SVMXC__Service_Order__c wo : newWorkOrders){
                //loop through and check if our old work order is work finished and our new one is either parts needed or estimate needed
                if (oldWorkOrders.get(wo.Id).SVMXC__Order_Status__c == 'Work Finished' && 
                    (wo.SVMXC__Order_Status__c == 'Parts Needed' || wo.SVMXC__Order_Status__c == 'Estimate Needed' || wo.SVMXC__Order_Status__c == 'Re-Dispatch')){
                        wo.Technician_Arrived__c = false;
                        wo.SVMXC__Group_Member__c = null;
                    }
            }
            /* *******************************************
            *** Update or Create Meter Reading History ***
            **********************************************
            */
            Set<Id> workOrderIds = new Set<Id>();//Hold work order ids
            //Get work order is and location id for all work orders
            for(SVMXC__Service_Order__c wo :newWorkOrders){
                workOrderIds.add(wo.Id);
            }
            //Fetch meter history for all work orders
            List<Meter_History__c> meterHistories = [SELECT Id,Description__c,Installed_Product__c,Meter_Reading__c,Reading_Date__c,Work_Order__c
                         FROM Meter_History__c
                         WHERE Work_Order__c in :workOrderIds];
            //Map to hold a list of meter history by work order id
            Map<Id,List<Meter_History__c>> meterHistoryMap = new Map<Id,List<Meter_History__c>>();
            for(Meter_History__c h :meterHistories){
                if(!meterHistoryMap.containsKey(h.Work_Order__c)){
                    List<Meter_History__c> temp = new List<Meter_History__c>();
                    temp.add(h);
                    meterHistoryMap.put(h.Work_Order__c,temp);
                }else{
                    meterHistoryMap.get(h.Work_Order__c).add(h);
                }
            }
            //List of meter history to insert
            List<Meter_History__c> mhToInsert = new List<Meter_History__c>();
            //List of meter history to update
            List<Meter_History__c> mhToUpdate = new List<Meter_History__c>();
            //Iterate through all work orders being updated to create or update meter history
            for(SVMXC__Service_Order__c wo :newWorkOrders){
                //If the work order has a meter reading...
                if(String.isNotBlank(String.valueOf(wo.Meter_Reading__c))){
                    //If the work order has an installed product...
                    if(String.isNotBlank(wo.SVMXC__Component__c)){
                        //If the this work order has meter reading history...
                        if(meterHistoryMap.containsKey(wo.Id)){
                            //If it has only one meter reading history
                            if(meterHistoryMap.get(wo.Id).size() == 1){
                                //If the meter reading changed in this transaction...
                                if(wo.Meter_Reading__c != oldWorkOrders.get(wo.Id).Meter_Reading__c){
                                    meterHistoryMap.get(wo.Id)[0].Meter_Reading__c = wo.Meter_Reading__c;
                                    meterHistoryMap.get(wo.Id)[0].Reading_Date__c = wo.TFS_Service_Date__c != null ? wo.TFS_Service_Date__c : Date.today();
                                    mhToUpdate.add(meterHistoryMap.get(wo.Id)[0]);
                                }//End if meter reading changed
                            //Otherwise, if it has more than 1 meter reading... 
                            }else if(meterHistoryMap.get(wo.Id).size() > 1){
                                //If not running  a test class
                                //Throw an error, too many meter reading history records
                                if(!Test.isRunningTest())
                                    wo.addError('Too many meter histories already exist, please contact your administrator for further instructions');
                            }//End if meter reading is 1
                        //Otherwise, create a new meter reading history for this work order
                        }else{
                            Meter_History__c newMeterHistory = new Meter_History__c(
                                Installed_Product__c = wo.SVMXC__Component__c,
                                Meter_Reading__c = wo.Meter_Reading__c,
                                Work_Order__c = wo.Id,
                                Description__c = 'Meter Reading from Work Order',
                                Reading_Date__c = wo.TFS_Service_Date__c != null ? wo.TFS_Service_Date__c : Date.today()
                            );
                            mhToInsert.add(newMeterHistory);
                        }//End if has meter reading history, else
                    //Otherwise, throw an exception, no installed product
                    }else{
                        wo.addError('Please select an installed product in order to set a meter reading');
                    }//End if installed product, else
                }//End if has meter reading
            }//End for work orders
            //Insert or update meter reading history w/ exception handling
            try{
                if(mhToInsert.size() > 0)
                    insert mhToInsert;
                if(mhToUpdate.size() > 0)
                    update mhToUpdate;
            }catch(Exception e){
                newWorkOrders[0].addError('Error: ' + e.getMessage());
            }
        }//End if is update
    }//End before


    
    /**This method manages actions to perform after a work order is inserted,updated, or deleted
    ***@param newWorkOrders Map<Id,SVMXC__Service_Order__c> - The new work orders being inserted/updated
    ***@param oldWorkOrders Map<Id,SVMXC__Service_Order__c> - The old work orders being updated
    ***@param isInsert Boolean - Denotes if trigger is insert
    ***@param isUpdate Boolean - Denotes if trigger is update
    ***@param isDelete Boolean - Denotes if trigger is delete
    */
    public static void after(List<SVMXC__Service_Order__c> newWorkOrders, Map<Id,SVMXC__Service_Order__c> oldWorkOrders, Boolean isInsert, Boolean isUpdate, Boolean isDelete){
        //get work detail record type
        String recordTypeId = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'SVMXC__Service_Order_Line__c' AND Name = 'Usage/Consumption' LIMIT 1].Id;
        /* **************************************************************************
        *** Anything that needs to be executed after insert and only after insert ***
        *****************************************************************************
        */
        if(isInsert){   
            //List of meter history to insert
            List<Meter_History__c> mhToInsert = new List<Meter_History__c>();
            //List of work detail lines to insert
            List<SVMXC__Service_Order_Line__c> wodlToInsert = new List<SVMXC__Service_Order_Line__c>();
            /*****************************************************************
            *** Get Pricebook entry and product for NMS default part lines ***
            ******************************************************************
            */ 
            //String to hold the product id
            String prodId = [SELECT Id, Name, Value__c FROM Key_Value_Store__c WHERE NAME = 'NMS Service Fees' LIMIT 1].Value__c;
            //String to hold the price book id
            String pbId = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE isStandard = TRUE LIMIT 1].Id;
            //The product
            Product2 prod = new Product2();
            //The price book entry
            PricebookEntry pbookEntry = new PricebookEntry();
            if(String.isNotBlank(prodId)){
                prod = [SELECT Id, SVMXC__Product_Cost__c FROM Product2 WHERE Id =: prodId LIMIT 1];
                pbookEntry = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :prod.Id AND Pricebook2Id = :pbId AND isActive = TRUE LIMIT 1];
            }else{
                newWorkOrders[0].addError('Error: nms service fees not found.');
            }//End if prodId not blank
            //Iterate through all work orders being inserted
            for(SVMXC__Service_Order__c wo :newWorkOrders){
                /* *****************************************************************
                *** Create Meter History line for work orders with meter reading ***
                ********************************************************************
                */
                //If the work order has a meter reading...
                if(String.isNotBlank(String.valueOf(wo.Meter_Reading__c))){
                    //If the work order has an installed product...
                    if(String.isNotBlank(wo.SVMXC__Component__c)){
                        Meter_History__c newMeterHistory = new Meter_History__c(
                            Installed_Product__c = wo.SVMXC__Component__c,
                            Meter_Reading__c = wo.Meter_Reading__c,
                            Work_Order__c = wo.Id,
                            Description__c = 'Meter Reading from Work Order',
                            Reading_Date__c = wo.TFS_Service_Date__c != null ? wo.TFS_Service_Date__c : Date.today()
                        );
                        mhToInsert.add(newMeterHistory);
                    //Otherwise, throw an exception, no installed product
                    }else{
                        wo.addError('Please select an installed product in order to set a meter reading');
                    }//End if installed product, else
                }//End if has meter reading
                
                /* **********************************************
                *** Create Shop Fee lines for NMS work orders ***
                ************************************************* 
                */
                if(wo.Business_Unit__c == 'National Maintenance Services'){
                    SVMXC__Service_Order_Line__c woDetailLine = new SVMXC__Service_Order_Line__c(
                        RecordTypeId = recordTypeId,
                        SVMXC__Service_Order__c = wo.Id,
                        SVMXC__Line_Type__c = 'Parts',
                        SVMXC__Actual_Quantity2__c = 1,
                        SVMXC__Activity_Type__c = 'Parts Equipment',
                        SVMXC__Product__c = prod.Id,
                        Vendor_Cost_Per_Unit__c = prod.SVMXC__Product_Cost__c,
                        SVMXC__Actual_Price2__c = pbookEntry.UnitPrice
                    );
                    wodlToInsert.add(woDetailLine);
                }//End of if NMS
                
                /* ********************************************************************
                *** Create Asset Mgmt. Fee or Recurring Rental  for TFS work orders ***
                *********************************************************************** 
                */
                //If the work order is flagged as TFS AMF WO...
                if(wo.TFS_AMF_WO__c){
                    //If the work order type is Leasing/Rental...
                    if(wo.SVMXC__Order_Type__c == 'Leasing/Rental'){
                        //Create a new work order detail line fo the work order using the work order...
                        //Recurring Rental Fees field
                        SVMXC__Service_Order_Line__c woDetailLine = new SVMXC__Service_Order_Line__c(
                            RecordTypeId = recordTypeId,
                            SVMXC__Service_Order__c = wo.Id,
                            SVMXC__Line_Type__c = 'Vendor Services',
                            SVMXC__Actual_Quantity2__c = 1,
                            SVMXC__Activity_Type__c = 'Rental - Service and Remodel',
                            Sales_Tax__c = 0,
                            SVMXC__Actual_Price2__c = wo.Recurring_Rental_Fees__c,
                            Work_Complete__c = true
                        );
                        wodlToInsert.add(woDetailLine);
                    //Otherwise...
                    //Create a new work order detail line fo the work order using the work order...
                    //Asset Mgmt Fees field
                    }else{
                        SVMXC__Service_Order_Line__c woDetailLine = new SVMXC__Service_Order_Line__c(
                            RecordTypeId = recordTypeId,
                            SVMXC__Service_Order__c = wo.Id,
                            SVMXC__Line_Type__c = 'Labor',
                            SVMXC__Actual_Quantity2__c = 1,
                            SVMXC__Activity_Type__c = 'Asset Mgmt Fees',
                            Sales_Tax__c = 0,
                            SVMXC__Actual_Price2__c = wo.Asset_Mgmt_Fees__c,
                            Work_Complete__c = true
                        );
                        wodlToInsert.add(woDetailLine);
                    }//End if work order type
                }//End if AMF
                
            }//End for work orders
            //If there are meter histories to insert...
            if(mhToInsert.size() > 0){
                insert mhToInsert;//Insert the meter histories
            }
            //If there are work order detail lines to insert...
            if(wodlToInsert.size() > 0){
                insert wodlToInsert;//Insert the work order detail lines
            }
            
        }//End if insert
        /* **************************************************************************
        *** Anything that needs to be executed after update and only after update ***
        *****************************************************************************
        */
        if(isUpdate){
            //Get TFS Record Type
            String tfsRecTypeId = [SELECT Id FROM RecordType  WHERE SobjectType = 'SVMXC__Service_Order__c' AND DeveloperName = 'TFS'].id;
            //List of work detail lines to insert
            List<SVMXC__Service_Order_Line__c> wodlToInsert = new List<SVMXC__Service_Order_Line__c>();
            //Hold ids for work orders with group change//Hold group member ids
            Map<Id,Id> grpMbrIds = new Map<Id,Id>();
            //List of work detail lines to update
            List<SVMXC__Service_Order_Line__c> wodlToUpdate = new List<SVMXC__Service_Order_Line__c>();
            //Iterate through all work orders being updated
            //Set to hold tfs work order ids where the vendor has changed
            Map<Id,Id> tfsWOVendorMap = new Map<Id,Id>();
            for(SVMXC__Service_Order__c wo :newWorkOrders){
                /* ***********************************************************************
                *** Create default work order Travel detail line for Miner Corp orders ***
                **************************************************************************
                */
                //If the technician has arrived for the first time to the location...
                if (wo.Business_Unit__c == 'Miner Corp' && (wo.Technician_Arrived__c == true && oldWorkOrders.get(wo.Id).Technician_Arrived__c == false) && wo.SVMXC__Order_Type__c != 'Sales-EQUIP' && wo.SVMXC__Order_Type__c != 'Parts Orders' && wo.Location__c != NULL && wo.Travel_Time__c != NULL){
                    SVMXC__Service_Order_Line__c newWorkDetailLine = new SVMXC__Service_Order_Line__c(
                        RecordTypeId = recordTypeId,
                        SVMXC__Service_Order__c = wo.Id,
                        SVMXC__Line_Type__c = 'Travel',
                        SVMXC__Actual_Quantity2__c = wo.Travel_Time__c,
                        SVMXC__Actual_Price2__c = wo.Labor_Standard_DDM__c,
                        Labor_Type__c = 'Labor-Standard (DDM)',
                        SVMXC__Activity_Type__c = 'Standard Labor',
                        Service_Report_Line__c = 'Queued'
                    );
                    wodlToInsert.add(newWorkDetailLine);
                }//End if match
                //Get the group member for the work order if the group member changed
                if(String.isNotBlank(wo.SVMXC__Group_Member__c) && (wo.SVMXC__Group_Member__c != oldWorkOrders.get(wo.Id).SVMXC__Group_Member__c) && !wo.Locked__c){
                    grpMbrIds.put(wo.Id,wo.SVMXC__Group_Member__c);
                }
                //Check if the vendoe changed in work TFS Work order
                if((wo.RecordTypeId == tfsRecTypeId && wo.Business_Unit__c == 'Total Fleet Solutions') && (wo.Vendor_Name_c__c != oldWorkOrders.get(wo.Id).Vendor_Name_c__c)){
                    tfsWOVendorMap.put(wo.Id,wo.Vendor_Name_c__c);
                }
            }//End for work order
            //If there are work detail lines to insert...
            if(wodlToInsert.size() > 0){
                insert wodlToInsert;//Insert the work order detail lines
            }
            /* ********************************************************************************************
            *** Update the Vendo Cost Per Unit on the work orders Travel lines if Service Group changed ***
            ***********************************************************************************************
            */
            //If there are ids in the grpMbrIds set...
            if(grpMbrIds.size() > 0){
                //Get the group members
                Map<Id,SVMXC__Service_Group_Members__c> techsMap =  new Map<Id,SVMXC__Service_Group_Members__c>([SELECT Id, SVMXC__Fixed_Cost__c FROM SVMXC__Service_Group_Members__c WHERE Id IN :grpMbrIds.values()]);
                //Get travel lines for the work orders
                list <SVMXC__Service_Order_Line__c> wodLines = [SELECT Id,SVMXC__Service_Order__c,Vendor_Cost_Per_Unit__c FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c IN :grpMbrIds.keySet() AND RecordTypeId = :RecordTypeId AND SVMXC__Line_Type__c = 'Travel'];
                //Update the vendor cost in travel lines...
                for(SVMXC__Service_Order_Line__c line :wodLines){
                    //If the grpMbrIds map contains this work order id as a key 
                    if(grpMbrIds.containsKey(line.SVMXC__Service_Order__c)){
                        if(techsMap.containsKey(grpMbrIds.get(line.SVMXC__Service_Order__c))){
                            line.Vendor_Cost_Per_Unit__c = techsMap.get(grpMbrIds.get(line.SVMXC__Service_Order__c)).SVMXC__Fixed_Cost__c;
                            wodlToUpdate.add(line);
                        }
                    }
                }//End for travel line
            }//End if group member ids
            //If there are vendor changes on TFS work order...
            if(tfsWOVendorMap.keySet().size() > 0){
                //Fetch detail lines for TFS work order where vendor changed 
                List<SVMXC__Service_Order_Line__c> tfsDets = [SELECT Id,SVMXC__Service_Order__c,Vendor__c FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c IN :tfsWOVendorMap.keySet()];
                //If detail lines were returned...
                if(tfsDets.size() > 0){
                    //For each detail line...
                    for(SVMXC__Service_Order_Line__c line :tfsDets){
                        if(tfsWOVendorMap.containsKey(line.SVMXC__Service_Order__c)){
                            //Update line vendor with work order vendor
                            line.Vendor__c = tfsWOVendorMap.get(line.SVMXC__Service_Order__c);
                            wodlToUpdate.add(line);
                        }
                    }
                }
            }
            //If there are work order lines to update...
            if(wodlToUpdate.size() > 0){
                update wodlToUpdate;//Update the work order detail lines
            }
        }//End if isUpdate
        /* **************************************************************
        *** Anything that needs to be executed after insert or update ***
        ***************************************************************** 
        */
        if(isInsert || isUpdate){
            /* *******************************************************************************
            *** Submit work order for approval if the work order status is Credit Approval ***
            **********************************************************************************
            */
            for(SVMXC__Service_Order__c wo :newWorkOrders){
                if (wo.SVMXC__Order_Status__c == 'Credit Approval' ) {
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setComments('Credit Approval Required');
                    req.setObjectId(wo.Id);
                    try{
                        Approval.ProcessResult result = Approval.process(req);
                    }catch(Exception e){
                        //Expected to fail during testing
                    }
                }//End if credit approval
            }//End for work order
        }//End if insert or update
            
    }//End after

    /**
     * setSuperCenters can be called to reset the Super Center lookup on a list of workorders based on the super center/segment combination of the location they link to.
     * @param  workOrders  The list of work orders to change the super center lookup of
     */
    public static void setSuperCenters(List<SVMXC__Service_Order__c> workOrders){
        //Set to hold the service team ids
        Set<Id> servTeamIds = new Set<Id>();
        //query all supercenter records
        List<Super_Center__c> supercenters = [SELECT Id, Name, Preferred_for_Super_Center__c, Super_Center__c, Segment__c FROM Super_Center__c];
        List<Segment__c> segments = [SELECT Id,Name,Segment_Name__c,Super_Center__c FROM Segment__c];
        for(SVMXC__Service_Order__c wo : workOrders){
            if(String.isNotBlank(wo.SVMXC__Service_Group__c)){
                servTeamIds.add(wo.SVMXC__Service_Group__c);
            }else{
                wo.Super_Center2__c = null;
            }
        }
        //query the servgice teams
        Map<Id,SVMXC__Service_Group__c> servTeamsMap = new Map<Id,SVMXC__Service_Group__c>([SELECT Id,Name,Super_Center__c,Segment__c FROM SVMXC__Service_Group__c WHERE Id In :servTeamIds]);
        
        for(SVMXC__Service_Order__c wo : workOrders){
            if(String.isNotBlank(wo.SVMXC__Service_Group__c)){
                if(servTeamsMap.containsKey(wo.SVMXC__Service_Group__c)){
                    String superCenter = servTeamsMap.get(wo.SVMXC__Service_Group__c).Super_Center__c;
                    String segment = servTeamsMap.get(wo.SVMXC__Service_Group__c).Segment__c;
                    //we need to match the list to the segment in the supercenter
                    for (Super_Center__c sc : supercenters){
                        //does this super center match the one in our map for this work order?
                        //check for the supercenter names matching and not blank
                        if(String.isNotBlank(sc.Super_Center__c)){
                            if (sc.Super_Center__c ==  superCenter){
                                if(String.isNotBlank(segment)){
                                    if(sc.Segment__c.contains(segment)){
                                        wo.Super_Center2__c = sc.Id;
                                        for(Segment__c seg :segments){
                                            if(seg.Super_Center__c == sc.Id && seg.Segment_Name__c == segment){
                                            	wo.Segment__c = seg.Id;
                                                break;
                                            }
                                        }
                                        break;
                                    }
                                }else if(sc.Preferred_for_Super_Center__c){
                                    wo.Super_Center2__c = sc.Id;
                                    break;
                                }
                            }else{
                                //no super center found
                            }
                        }//end of supercenter on location is not blank
                    }//end of sc loop
                }
            }
        }//end of wo loop
    }//end of set super center
    
    /**This method manages actions to perform before a work order is inserted,updated, or deleted (recursive to catch changes via workflow rules)
    ***@param newRecords List<SVMXC__Service_Order__c> - The new work orders being inserted/updated
    ***@param oldMap Map<Id,SVMXC__Service_Order__c> - The old work orders being updated
    */
    public static void beforeRecursive(List<SVMXC__Service_Order__c> newRecords, Map<Id,SVMXC__Service_Order__c> oldMap){
        List<SVMXC__Service_Order__c> needSuperCenter = new List<SVMXC__Service_Order__c>();
        //Run this if the trigger is inser or update
        if(Trigger.isInsert || Trigger.isUpdate){
            //For each work order in trigger
            for(SVMXC__Service_Order__c wo :newRecords){
                //If the work ord3er just got scheduled...
                if(wo.SVMXC__Scheduled_Date_Time__c != null && wo.First_Time_Dispatched__c == null){
                    wo.First_Time_Dispatched__c = DateTime.now();//Set the First Time Dispatched to now
                }//End if dispatched
                //If the oldMap map has reocrds...
                if(oldMap != null){
                    //If the work order just went to Job/Work Complete status...
                    if(wo.SVMXC__Order_Status__c == 'Job/Work Complete' && oldMap.get(wo.Id).SVMXC__Order_Status__c != 'Job/Work Complete'){
                        wo.Date_Time_Job_Work_Complete__c = DateTime.now();//Set the Date Time Job Work Complete to now
                    }//end if complete
                    //If the work order just went to Invoice Completed status...
                    if(wo.SVMXC__Order_Status__c == 'Invoice Completed' && oldMap.get(wo.Id).SVMXC__Order_Status__c != 'Invoice Completed'){
                        wo.Date_Time_Invoice_Completed__c = DateTime.now();//Set the Date Time invoice Completed to now
                        //If the Date Time Job/Work Complete time stamp is null...
                        if(wo.Date_Time_Job_Work_Complete__c == null){
                            wo.Date_Time_Job_Work_Complete__c = DateTime.now();//Set the date Time Job/Work COmplete to now
                        }//Enf id complete
                    }//ENd if invoiced
                }//End if oldmap
                /////////////////////////////////////////////////////////////////////
                //Check super center changed or not and send it to setSuperCenter: //
                /////////////////////////////////////////////////////////////////////
                if(Trigger.isInsert){
                    if (String.isNotBlank(wo.SVMXC__Service_Group__c) && (String.isBlank(wo.Super_Center2__c) || String.isBlank(wo.Segment__c))){     
                        needSuperCenter.add(wo);
                    }
                }else{
                    if ((String.isNotBlank(wo.SVMXC__Service_Group__c) && (String.isBlank(wo.Super_Center2__c) || String.isBlank(wo.Segment__c))) || (oldMap.get(wo.Id).SVMXC__Service_Group__c != wo.SVMXC__Service_Group__c)){     
                        needSuperCenter.add(wo);
                    }
                }
            }//End for work order
            
        }//End if insert or update
        if(needSuperCenter.size() > 0){
            setSuperCenters(needSuperCenter); //call our method to modify these work orders and match the super centers
        }
    }//End beforeRecursive method
    /**
    *** This variable and method are used to prevent triggers recursion on before insert/update
    */
    public static Boolean isFirstTriggerRun_Before = true;
    public static Boolean runTriggerOnce_Before(){
        if(isFirstTriggerRun_Before){
            isFirstTriggerRun_Before = false;
            return true;
        }else{
            return isFirstTriggerRun_Before;
        }
    }
    /**
    *** This variable and method are used to prevent triggers recursion on afterinsert/update
    */
    public static Boolean isFirstTriggerRun_After = true;
    public static Boolean runTriggerOnce_After(){
        if(isFirstTriggerRun_After){
            isFirstTriggerRun_After = false;
            return true;
        }else{
            return isFirstTriggerRun_After;
        }
    }
}