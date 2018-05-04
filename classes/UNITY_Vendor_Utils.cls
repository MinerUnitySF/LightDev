/*321
*   @programer:    Samuel Astol
*   @date:         12/16/2015
*   @description:  Help methods to handle vendors at location.
*/
public class UNITY_Vendor_Utils {
    
    
    
    
     /*
      * Name    : getVendorsSpecific
      * Param 1 : list of account ids ||  WO ids   
      * Param 2 : Sobject type of the Ids 
      * Param 3 : set of trades ids to filter 
      * Param 4 : boolean for retrive only VA   (Max 3 vendors)
      * Param 5 : boolean for create Candidates (Max 3 vendors)
      * Return  : Map< id, list<UNITY_wrapperVendorByTrade>>, map of (account id || WO id ) to list of vendor-trade wrapper 
      */
     public static Map< id, list<UNITY_wrapperVendorByTrade>> getVendorsSpecific(list<id> sobjectIds , SObjectType objectType, Set<id> tradeIds ,boolean onlyVendorAssignments, boolean createVA ){
        
        Map<id,list<UNITY_wrapperVendorByTrade>> toReturn = new Map<id,list<UNITY_wrapperVendorByTrade>>();
        
        // kay   : account id 
        // value : location key
        Map<id,String> accountLocationKeys   = new Map<id,String>();
        
        // kay   : account id 
        // value : location key
        Map<id,String> workOrderLocationKeys = new Map<id,String>();
        
        // kay   : account id 
        // value : account
        Map<id,Account> customers = new Map<id,Account>();
         
        // kay   : account id 
        // value : account
        Map<id,Account> vendors   = new Map<id,Account>();
         
        // kay   : WorkOrder id 
        // value : WorkOrder
        Map<id,WorkOrder> workOrders   = new Map<id,WorkOrder>();
         
        // kay   : location key
        // value : list of vendors id at location 
        Map<String,list<Id>> vendorsPerLocation = new Map<String,list<Id>>();
        
        // kay   : customer id - vendor Id + trade id
        // value : UNITY_Vendor_Preference_By_Trade__c
        Map<String,UNITY_Vendor_Preference_By_Trade__c> preferencesByTrade = new Map<String,UNITY_Vendor_Preference_By_Trade__c>();
        
        // kay   : workOrder id - vendor Id
        // value : UNITY_Vendor_Assignment__c
        Map<String,UNITY_Vendor_Assignment__c> workOrderAssignments = new Map<String,UNITY_Vendor_Assignment__c>();
         
        // kay   : vendor id - trade Id
        // value : UNITY_Vendor_Assignment__c
        Map<id,List<UNITY_Vendor_Trade__c>> vendorTrades = new Map<id,List<UNITY_Vendor_Trade__c>>();
        
        // kay   : workOrder id 
        // value : customer id 
        Map<Id,Id> workOrderIdCustomertId = new Map<Id,Id>();
        
        List<Id> customersId = new List<Id>();
        
        // check if there are records to process
        Boolean areRecordsToProcess = ((sobjectIds!=null)&&(sobjectIds.size()>0));
        
        //  first get the acount related to the Work Orders and the Vendors Assignments
        if(areRecordsToProcess && (objectType == WorkOrder.getSObjectType())){
            
            workOrders = UNITY_Utils.getWorkOrders(sobjectIds);
            
            for(WorkOrder onWorkOrder :workOrders.values()){
                if(onWorkOrder.AccountId!=null){
                    customersId.add(onWorkOrder.AccountId);
                }
            }
            workOrderAssignments = getAssignments(sobjectIds);
        }
       
        if((customersId.size() == 0) && (objectType == Account.getSObjectType())) customersId = sobjectIds;
        
        //  step 1 : get the accounts 
        //  step 2 : relate each account to the loacation key  
        //  step 3 : relate each WO to the account loacation key  
        //  step 4 : get the vendors at location ids   
        //  step 5 : get the vendors accounts 
        //  step 6 : get the vendors trades covered
        //  step 7 : get the vendors preference by trade 
        if(areRecordsToProcess){
            
            //  step 1 : get the accounts 
            customers = UNITY_Utils.getAccounts(customersId);   
            
            //  step 2 : relate each account to the loacation key  
            for(Account onAccount :customers.values()){
                accountLocationKeys.put(onAccount.id, UNITY_Utils.getLocationKey(onAccount.ShippingCountryCode, onAccount.ShippingPostalCode));
            }
            
            //  step 3 : relate each WO to the account loacation key  
            for(WorkOrder onWorkOrder :workOrders.values()){
                workOrderLocationKeys.put(onWorkOrder.id, accountLocationKeys.get(onWorkOrder.AccountId));
            }
            
            //  step 4 : get the vendors at location ids   
            vendorsPerLocation = getVendorPerLocation(accountLocationKeys.values());
            
            List<id> vendorsId = new List<id>();
            for(List<id> ids :vendorsPerLocation.values()){
                vendorsId.addAll(ids);
            }
            
            //  step 5 : get the vendors accounts 
            vendors = UNITY_Utils.getAccounts(vendorsId);   
            //  step 6 : get the vendors trades covered
            vendorTrades  = getTradesCovered(vendors.keySet(),tradeIds);   
            //  step 7 : get the vendors preference by trade 
            preferencesByTrade = getPreferencesByTrade(vendors.keySet(),customers.keySet(),tradeIds);
             system.debug('#### preferencesByTrade '+preferencesByTrade);
        } 
        
        // process Data
        // crate VA if id is required 
        if(objectType == Account.getSObjectType()) 
            toReturn = processData(accountLocationKeys,vendorsPerLocation, vendors, vendorTrades, preferencesByTrade, workOrderAssignments, workOrders,false,false);
        else if(objectType == WorkOrder.getSObjectType()){
            toReturn = processData(workOrderLocationKeys,vendorsPerLocation, vendors, vendorTrades, preferencesByTrade, workOrderAssignments, workOrders,onlyVendorAssignments,createVA);
        }
        
        return toReturn;
    }
                                                                         
    /*
     * Name    : getAssignments
     * Note    : Precess the data to retrive the wrapper and by account or WO 
     * Param 1 : Map< (account id || wo id )  , location key >
     * Param 2 : Map< location key  ,list of vendors id >
     * Param 3 : Map< vendor id , Account>  
     * Param 4 : Map< vendor id ,List of UNITY_Vendor_Trade__c which covers the vendor >
     * Param 5 : Map< account id - vendor id - trade id  , UNITY_Vendor_Preference_By_Trade__c >
     * Param 6 : Map< work order id - vendor id , UNITY_Vendor_Assignment__c >
     * Param 7 : Map< WorkOrder id, WorkOrder >
     * Param 8 : only retrive vendors assigned to WO 
     * Param 9 : create candidate if no VA are found for WO 
     * Return  : Map< wo id - vendor id , UNITY_Vendor_Assignment__c> 
     * 
     */
    public static  Map<id,list<UNITY_wrapperVendorByTrade>> processData(Map<id,String>                                  objectIdLocation, 
                                                                        Map<String,list<id>>                            vendorPerLocation, 
                                                                        Map<id,Account>                                 vendors, 
                                                                        Map<id,List<UNITY_Vendor_Trade__c>>             vendorTrades, 
                                                                        Map<String,UNITY_Vendor_Preference_By_Trade__c> preferencesByTrade,
                                                                        Map<String,UNITY_Vendor_Assignment__c>          workOrderAssignments,
                                                                        Map<id,WorkOrder>                               workOrders,
                                                                        boolean                                         onlyVendorAssignments,
                                                                        boolean                                         createVA){
        
        Map<id,list<UNITY_wrapperVendorByTrade>> toReturn     = new  Map<id,list<UNITY_wrapperVendorByTrade>>();
        Map<id,list<UNITY_wrapperVendorByTrade>> aux_toReturn = new  Map<id,list<UNITY_wrapperVendorByTrade>>();
        Map<id,list<UNITY_Vendor_Assignment__c>> assignments  = new  Map<id,list<UNITY_Vendor_Assignment__c>>();
        Map<String,UNITY_wrapperVendorByTrade>   wrappersToSetAssignment = new  Map<String,UNITY_wrapperVendorByTrade>();
        Set<id>                                  hasWOVA      = new  Set<id>();
        List<UNITY_Vendor_Assignment__c>         assignmentsToInsert     = new  List<UNITY_Vendor_Assignment__c>();
        
                                                                        
        String locationKey = '';
        String workOrderIdVendorId = '';
        String customerIdVendorIdTradeId = '';                                                 
       
        // go for each location 
        for(id objectId :objectIdLocation.keySet()){
            // get the location 
            locationKey = objectIdLocation.get(objectId);
            // check if location has vendor at the location 
            if(vendorPerLocation.get(locationKey)!=null){
                // go for each vendor at location 
                for(id vendorId :vendorPerLocation.get(locationKey)){
                    // check if the vendor has trades
                    if(vendorTrades.get(vendorId) !=null){
                        // go for each trade 
                        for(UNITY_Vendor_Trade__c  onTrade :vendorTrades.get(vendorId)){
                            
                            if(aux_toReturn.get(objectId) == null) aux_toReturn.put(objectId, new list<UNITY_wrapperVendorByTrade>());
                            
                            workOrderIdVendorId  = objectId+'-'+vendorId;
                            
                            // get the account from the WO 
                            if(workOrders.get(objectId)!=null)
                                customerIdVendorIdTradeId = workOrders.get(objectId).accountId+'-'+vendorId+'-'+onTrade.Trade__c;
                            else
                                customerIdVendorIdTradeId = objectId+'-'+vendorId+'-'+onTrade.Trade__c;
                            
                            // get the wrapper object 
                            UNITY_wrapperVendorByTrade wvbt = getWrapperVendorTrade(vendors.get(vendorId), 
                                                                                    onTrade, 
                                                                                    preferencesByTrade.get(customerIdVendorIdTradeId),
                                                                                    workOrderAssignments.get(workOrderIdVendorId),
                                                                                    workOrders.get(objectId));
                            
                            // skip do no use vendor on preference 
                            if( (preferencesByTrade.get(customerIdVendorIdTradeId)==null) ||
                                ((preferencesByTrade.get(customerIdVendorIdTradeId)!=null) && preferencesByTrade.get(customerIdVendorIdTradeId).Type__c != UNITY_Constants.VENDOR_PREFERENCE_DO_NOT_USE)){
                                
                                aux_toReturn.get(objectId).add(wvbt);
                                // store the WO which has VA
                                if(wvbt.assignment != null) hasWOVA.add(objectId);
                            }
                        }
                    }
                }
            }  
            if(workOrders.get(objectId) != null){
                // sort the list of vendors
                aux_toReturn.put(objectId,UNITY_Vendor_Utils.wrapperVendorByTradeFilter(aux_toReturn.get(objectId), UNITY_Constants.VENDORS_RECORDTYPE_MAP.get(workOrders.get(objectId).RecordType.Name), workOrders.get(objectId).UNITY_Trade__c , null, null ));
            }
        }
                                                                         
        // retrive MAX_ASSIGNMENTS VA if it is reiquired 
        Integer MAX_ASSIGNMENTS = 3 ;                                                                   
                                                                            
        if(onlyVendorAssignments){
            // go for each WO id
            for(id objectId :aux_toReturn.keySet()){
                
                integer iter = 0;
                while((iter<MAX_ASSIGNMENTS) && (iter < aux_toReturn.get(objectId).size())){
                    
                    UNITY_wrapperVendorByTrade wvbt = aux_toReturn.get(objectId).get(iter);
                        
                    if(toReturn.get(objectId) == null) toReturn.put(objectId, new list<UNITY_wrapperVendorByTrade>());
                    
                    if(wvbt.assignment != null)
                        toReturn.get(objectId).add(wvbt);
                    else if(createVA && !hasWOVA.contains(objectId)){
                        UNITY_Vendor_Assignment__c newAssignment = createAssignment(workOrders.get(objectId),wvbt.id, UNITY_Constants.VENDOR_ASSIGNMENT_STATUS_CANDIDATE);
                        if(assignments.get(objectId)==null) assignments.put(objectId, new list<UNITY_Vendor_Assignment__c>());
                        assignments.get(objectId).add(newAssignment);
                        wrappersToSetAssignment.put(objectId+'-'+wvbt.id, wvbt); 
                        assignmentsToInsert.add(newAssignment);
                        toReturn.get(objectId).add(wvbt);
                    }
                    
                    iter++;
                }
            } 
            insert assignmentsToInsert;
            
            for(id objectId :assignments.keySet()){
                for(UNITY_Vendor_Assignment__c va :assignments.get(objectId)){
                    wrappersToSetAssignment.get(objectId+'-'+va.Vendor__c).setAssignment(va);
                }
            }
        }else toReturn = aux_toReturn;
                                                                            
        return toReturn;
    }
    

    /*
     * Name    : createAssignment
     * Param 1 : Account 
     * Param 2 : UNITY_Vendor_Trade__c
     * Param 3 : UNITY_Vendor_Preference_By_Trade__c
     * Param 4 : UNITY_Vendor_Assignment__c
     * Return  : UNITY_wrapperVendorByTrade 
     * 
     */
    public static UNITY_wrapperVendorByTrade getWrapperVendorTrade(Account vendor , 
                                                                   UNITY_Vendor_Trade__c trade, 
                                                                   UNITY_Vendor_Preference_By_Trade__c vendorPreferenceByTrade, 
                                                                   UNITY_Vendor_Assignment__c vendorAssignment,
                                                                   WorkOrder onWorkOrder){
        
        UNITY_wrapperVendorByTrade aux = new UNITY_wrapperVendorByTrade();
        aux.id    = vendor.Id;
        aux.name  = vendor.Name;
        aux.phone = vendor.Phone;
        aux.email = vendor.Account_Email__c;
        aux.dispatcherId = vendor.UNITY_Dispatcher__c;
        aux.summaryHours = vendor.UNITY_Hours_of_Operation_Summary__c;
        
        if(trade != null){
            aux.tradeId      = trade.Trade__c;
            aux.tradeName    = trade.Trade__r.Name;
            
            aux.pricesByRecordType.put( 'PM'     , ((trade.Price_PM__c != null)?(double) trade.Price_PM__c : 0) )  ;
            aux.pricesByRecordType.put( 'Project', ((trade.Price_Project__c != null)?(double) trade.Price_Project__c : 0));
            aux.pricesByRecordType.put( 'SR'     , ((trade.Price_SR__c != null)?(double) trade.Price_SR__c : 0));
            aux.pricesByRecordType.put( 'SS'     , ((trade.Price_SS__c != null)?(double) trade.Price_SS__c : 0));
    
            aux.scoreByRecordType.put('PM'     , ((trade.Score_PM__c != null)?(double) trade.Score_PM__c : 0) )  ;
            aux.scoreByRecordType.put('Project', ((trade.Score_Project__c != null)?(double) trade.Score_Project__c : 0));
            aux.scoreByRecordType.put('SR'     , ((trade.Score_SR__c != null)?(double) trade.Score_SR__c : 0));
            aux.scoreByRecordType.put('SS'     , ((trade.Score_SS__c != null)?(double) trade.Score_SS__c : 0));
        }
        
       /*aux.setOperationalHours((String)onData.getSobject( 'Vendor__r' ).get(UNITY_Constants.ACCOUNT_OPERATION_HOURS.get(dayOfTheWeek)[0]),
                                        (String)onData.getSobject( 'Vendor__r' ).get(UNITY_Constants.ACCOUNT_OPERATION_HOURS.get(dayOfTheWeek)[1]));*/
        
        date myDate          = Date.today();
        date weekStart       = myDate.toStartofWeek();
        integer dayOfTheWeek = weekStart.daysBetween(myDate);
        
        aux.setTimeZone(vendor.UNITY_TimeZoneSidKey__c, 
                        (String)vendor.get(UNITY_Constants.ACCOUNT_OPERATION_HOURS.get(dayOfTheWeek)[0]), 
                        (String)vendor.get(UNITY_Constants.ACCOUNT_OPERATION_HOURS.get(dayOfTheWeek)[1])); 
                                
        aux.isMiner = vendor.UNITY_Miner_Regional_Office__c;
        aux.status  = vendor.UNITY_Vendor_Status__c;
            
        aux.setIsRT(vendor.UNITY_Vendor_Type_PM__c,
                    vendor.UNITY_Vendor_Type_Project__c,
                    vendor.UNITY_Vendor_Type_SR__c,
                    vendor.UNITY_Vendor_Type_SS__c);
                
       aux.isMinerPreferred    = vendor.UNITY_Preferred_Vendor__c;
       
       if(vendorPreferenceByTrade != null){
            aux.isCustomerPreferred = (vendorPreferenceByTrade.Type__c == UNITY_Constants.VENDOR_PREFERENCE_PREFERRED);
            aux.ranking = vendorPreferenceByTrade.Ranking__c;
       }
                                                                       
       if(vendorAssignment != null) aux.setAssignment(vendorAssignment);
       
       // set context for WO 
       if(onWorkOrder!=null)
           aux.context(UNITY_Constants.WO_RECORDTYPE_ABBR.get(onWorkOrder.RecordType.Name), 
                       (Double)onWorkOrder.UNITY_Customer_Service_Contract_Price__c , 
                       (Double)onWorkOrder.UNITY_Customer_Margin__c  );
                                                                       
       return aux;
    }
    
    /*
     * Name    : getAssignments
     * Param   : list of WO ids   
     * Return  : Map< wo id - vendor id , UNITY_Vendor_Assignment__c> 
     * 
     */
    public static  Map<String, UNITY_Vendor_Assignment__c> getAssignments(list<id> workOrders){
        
        Map<String, UNITY_Vendor_Assignment__c> toReturn = new Map<String, UNITY_Vendor_Assignment__c>();
        
        Map<id, UNITY_Vendor_Assignment__c> vendorAssignments = new Map<id, UNITY_Vendor_Assignment__c>([SELECT  id,
                                                                                                                 Assignment_Warning__c,
                                                                                                                 Customer__c ,
                                                                                                                 Initial_PO__c ,
                                                                                                                 Initial_PO_Cost__c ,
                                                                                                                 Last_Assigned__c ,
                                                                                                                 OON__c ,
                                                                                                                 PIN__c ,
                                                                                                                 Request_Type__c ,
                                                                                                                 Status__c ,
                                                                                                                 Trade__c ,
                                                                                                                 Vendor__c ,
                                                                                                                 UNITY_Vendor_Email__c ,
                                                                                                                 Work_Order__c,
                                                                                                                 LastModifiedDate
                                                                                                         FROM    UNITY_Vendor_Assignment__c
                                                                                                         WHERE   Work_Order__c IN :workOrders]);
        
        String key = '';
        for(UNITY_Vendor_Assignment__c vendorAssignment :vendorAssignments.values()){
            key = vendorAssignment.Work_Order__c +'-'+vendorAssignment.Vendor__c;
            toReturn.put(key,vendorAssignment);
        }     
        return toReturn;
    }
    
    /*
     * Name    : getPreferencesByTrade
     * Param 1 : Set< vendor(account) ids > 
     * Param 2 : Set< customers(account) ids > 
     * Param 3 : Set< trades(fso skills) ids > 
     * Return  : Map< customer id - vendor id - trade id , UNITY_Vendor_Preference_By_Trade__c> 
     * 
     */
    public static Map<String,UNITY_Vendor_Preference_By_Trade__c> getPreferencesByTrade(Set<id> vendorsId , Set<id> customerId, Set<id> tradeIds){
        
        Map<String,UNITY_Vendor_Preference_By_Trade__c> toReturn = new Map<String,UNITY_Vendor_Preference_By_Trade__c>();
        Map<id, UNITY_Vendor_Preference_By_Trade__c>  preferencesByTrade = new Map<id, UNITY_Vendor_Preference_By_Trade__c>();
        
        if((tradeIds != null)&&(tradeIds.size()>0)){
            preferencesByTrade = new Map<id, UNITY_Vendor_Preference_By_Trade__c>([SELECT id, Type__c, Ranking__c, Vendor__c, Customer__c, Trade__c 
                                                                                   FROM   UNITY_Vendor_Preference_By_Trade__c
                                                                                   WHERE  (Vendor__c IN :vendorsId) AND 
                                                                                          (Customer__c IN :customerId) AND
                                                                                          (Trade__c IN :tradeIds)]);
        }else{
            preferencesByTrade = new Map<id, UNITY_Vendor_Preference_By_Trade__c>([SELECT id, Type__c, Ranking__c, Vendor__c, Customer__c, Trade__c 
                                                                                   FROM   UNITY_Vendor_Preference_By_Trade__c
                                                                                   WHERE  (Vendor__c IN :vendorsId) AND (Customer__c IN :customerId)]);
        }
        
        String key = '';
        for(UNITY_Vendor_Preference_By_Trade__c vpbt :preferencesByTrade.values()){
            key =  vpbt.Customer__c+'-'+vpbt.Vendor__c+'-'+vpbt.Trade__c;
            toReturn.put(key,vpbt);
        }
        return toReturn; 
    }
    
    /*
     * Name    : getPreferencesByTrade
     * Param 1 : Set< vendor(account) ids > 
     * Param 2 : Set< trades(fso skill) ids > 
     * Return  : Map< vendor id , List of UNITY_Vendor_Trade__c covered by the vendor >
     * 
     */
    public static Map<id,List<UNITY_Vendor_Trade__c>> getTradesCovered(Set<id> vendorsId, Set<id> tradeIds){
        
        Map<id,List<UNITY_Vendor_Trade__c>> toReturn = new Map<id,List<UNITY_Vendor_Trade__c>>();
        Map<id,UNITY_Vendor_Trade__c> vendorTrades = new Map<id,UNITY_Vendor_Trade__c>();
        if((tradeIds != null)&&(tradeIds.size()>0)){
            vendorTrades = new Map<id,UNITY_Vendor_Trade__c>([SELECT Id, Name, Trade__c, Trade__r.Name, Vendor__c, 
                                                                     Score_PM__c, 
                                                                     Score_Project__c, 
                                                                     Score_SR__c, 
                                                                     Score_SS__c, 
                                                                     Price_PM__c,
                                                                     Price_Project__c, 
                                                                     Price_SR__c, 
                                                                     Price_SS__c 
                                                              FROM   UNITY_Vendor_Trade__c 
                                                              WHERE  (Vendor__c IN :vendorsId) AND
                                                                     (Trade__c  IN :tradeIds)]);
        }else{
            vendorTrades = new Map<id,UNITY_Vendor_Trade__c>([SELECT  Id, Name, Trade__c, Trade__r.Name, Vendor__c, 
                                                                      Score_PM__c, 
                                                                      Score_Project__c, 
                                                                      Score_SR__c, 
                                                                      Score_SS__c, 
                                                                      Price_PM__c,
                                                                      Price_Project__c, 
                                                                      Price_SR__c, 
                                                                      Price_SS__c 
                                                                FROM  UNITY_Vendor_Trade__c 
                                                                WHERE Vendor__c IN :vendorsId]);
        }
        
        for(UNITY_Vendor_Trade__c  vendorTrade :vendorTrades.values()){
            if(toReturn.get(vendorTrade.Vendor__c)==null) toReturn.put(vendorTrade.Vendor__c,new List<UNITY_Vendor_Trade__c>());
            toReturn.get(vendorTrade.Vendor__c).add(vendorTrade);
        }
            
        return toReturn;
    }
    
    /*
     * Name    : getAccounts
     * Param   : List< location key >
     * Return  : Map< location key  , List of vendor ids > 
     * 
     */
    public static Map<String,List<Id>> getVendorPerLocation(list<String> locations){
        
        Map<String,List<Id>> toReturn =  new Map<String,List<Id>>();
        
        Map<id,UNITY_Vendor_Covered_Location__c> vendorsAtLocation = new Map<id,UNITY_Vendor_Covered_Location__c>([SELECT id, Name , Location_Key__c, Vendor__c
                                                                                                                   FROM  UNITY_Vendor_Covered_Location__c
                                                                                                                   WHERE (Location_Key__c  IN :locations) AND (Vendor__r.UNITY_Do_Not_Use__c = false)]);
        
        for(UNITY_Vendor_Covered_Location__c vendorAtLOcation :vendorsAtLocation.values()){
            if(toReturn.get(vendorAtLOcation.Location_Key__c )== null)toReturn.put(vendorAtLOcation.Location_Key__c,new List<Id>());
            toReturn.get(vendorAtLOcation.Location_Key__c).add(vendorAtLOcation.Vendor__c);
        }
        return toReturn;
    } 
    
    /*
     *   Name    : filterVendorTrade
     *   Note    : fiter vendors by record type and trade, and set context for vendor trade
     *   Param 1 : list<UNITY_wrapperVendorByTrade>
     *   Param 2 : String -> record type abbr (SR,SS,PM,Project)
     *   Param 3 : String -> trade id
     *   Param 4 : double -> customer price from WO        
     *   Param 5 : double -> margin   price form WO 
     *   Return  : list<UNITY_wrapperVendorByTrade>
     */
    public static list<UNITY_wrapperVendorByTrade> wrapperVendorByTradeFilter(list<UNITY_wrapperVendorByTrade> vendors, 
                                                                     String recordType, 
                                                                     String trade ,
                                                                     double customerPrice, 
                                                                     double marginPrice){
        
        list<UNITY_wrapperVendorByTrade> aux_vendors = new list<UNITY_wrapperVendorByTrade>();
        
        if(vendors != null){
            
            for( UNITY_wrapperVendorByTrade  onVendor :vendors){
                // check if the vendors has record type 
                if(onVendor.isRT(recordType) && (onVendor.tradeId == trade)){
                    // set score and price for record type 
                    onVendor.context(recordType,customerPrice,marginPrice);
                    aux_vendors.add(onVendor);
                }
            }
             aux_vendors = sortList(aux_vendors);
        }
        return aux_vendors;
    } 
    
    
    /*
     *   @programer:    Samuel Astol
     *   @date:         12/09/2015
     *   @description:  sort the vendors list 
     *                  order : [Assigned vendors('Accepted','Assigned','Candidate')], 
     *                          [Customer preferred vendors(by ranking)],[miner preferred vendors(by score)], 
     *                          [the others vendors(by score)]      
     */
    public static list<UNITY_wrapperVendorByTrade> sortList( list<UNITY_wrapperVendorByTrade> vendors ){
        
        list<UNITY_wrapperVendorByTrade> aux_vendors = new list<UNITY_wrapperVendorByTrade>();
        
        if(vendors != null){
            
            list<UNITY_wrapperVendorByTrade> byAssignment = new list<UNITY_wrapperVendorByTrade>();
            list<UNITY_wrapperVendorByTrade> byRanking = new list<UNITY_wrapperVendorByTrade>();
            list<UNITY_wrapperVendorByTrade> byMiner = new list<UNITY_wrapperVendorByTrade>();
            list<UNITY_wrapperVendorByTrade> byScore = new list<UNITY_wrapperVendorByTrade>();
            
            for( UNITY_wrapperVendorByTrade  onVendor :vendors){
                
                if(onVendor.hasAssignment()){
                    byAssignment.add(onVendor);
                }else if(onVendor.isCustomerPreferred){
                    byRanking.add(onVendor);
                }else if(onVendor.isMinerPreferred){
                    byMiner.add(onVendor);
                }else{
                    byScore.add(onVendor);
                }
            }
            
            vendors = new list<UNITY_wrapperVendorByTrade>();
            
            byAssignment.sort();
            byRanking.sort();
            byMiner.sort();
            byScore.sort();
            
            aux_vendors.addAll(byAssignment);
            aux_vendors.addAll(byRanking);
            aux_vendors.addAll(byMiner);
            aux_vendors.addAll(byScore);
        
        }
        return aux_vendors;
    }
    
    /*
     * Name    : createAssignment
     * Param 1 : WorkOrder 
     * Param 2 : vendor id 
     * Param 3 : String VA status  
     * Return  : UNITY_Vendor_Assignment__c 
     * 
     */
    public static UNITY_Vendor_Assignment__c createAssignment(WorkOrder onWo , id vendorId , String Status ){
        UNITY_Vendor_Assignment__c newAssignment = new UNITY_Vendor_Assignment__c();
        newAssignment.Request_Type__c  = onWo.RecordType.Name;
        newAssignment.Trade__c         = onWo.UNITY_Trade__c;
        newAssignment.Customer__c      = onWo.AccountId;
        newAssignment.Work_Order__c    = onWo.id;
        newAssignment.Vendor__c        = vendorId;
        newAssignment.Status__c        = Status;
        return  newAssignment;
    }
    
   /*
    * Name    : compareByPreferredOrder
    * Note    : help method to compare by preference  
    * Param 1 : UNITY_wrapperVendorByTrade vendor trade wrapper  
    * Param 2 : UNITY_wrapperVendorByTrade vendor trade wrapper compare to 
    * Return  : Integer
    */
    public static Integer compareByPreferredOrder( UNITY_wrapperVendorByTrade wo, UNITY_wrapperVendorByTrade compareToW ){
            
            if(wo.isCustomerPreferred && !compareToW.isCustomerPreferred){
                return -1;
            }else if(wo.isCustomerPreferred && compareToW.isCustomerPreferred){
                if (wo.ranking == compareToW.ranking) return 0;
                if (wo.ranking >  compareToW.ranking) return 1;  
                if (wo.ranking <  compareToW.ranking) return -1;  
            }else if(wo.isMinerPreferred && !(compareToW.isCustomerPreferred || compareToW.isMinerPreferred) ){
                return -1;
            }else if(wo.isMinerPreferred && compareToW.isMinerPreferred){
                if (wo.score == compareToW.score) return 0;
                if (wo.score > compareToW.score ) return -1;
            }else if((!wo.isMinerPreferred && !wo.isCustomerPreferred)&&(!compareToW.isMinerPreferred && !compareToW.isCustomerPreferred)){
                if (wo.score == compareToW.score) return 0;
                if (wo.score > compareToW.score ) return -1; 
            }
            return 1;
    }
    
    /*
    * @name        : checkOperationHours
    * @argument 1  : integer[] --> [0] = HH , [1] = MM  Start Hour
    * @argument 2  : integer[] --> [0] = HH , [1] = MM  End Hour
    * @argument 3  : integer[] --> [0] = HH , [1] = MM  Current Hour 
    * @return      : boolean (true = candidate in-hours, false =  candidate off-hours)
    * @note        : check if the current hous is between the hours of operation given a Vendor Account
    */
    public static boolean checkOperationHours( integer[] startTime , integer[] endTime , integer[] compareTo ){
        
        // check that we have data to compare with 
        if((startTime != null) && (endTime != null) && (compareTo != null) && (startTime.size() == 2) && (endTime.size() == 2) && (compareTo.size() == 2)){
            // compare HH part 
            if((startTime[0] <= compareTo[0])&&(compareTo[0] <= endTime[0])){
                if((startTime[0] == endTime[0])   && (startTime[1] <= compareTo[1]) && (compareTo[1] <= endTime[1])) return true;
                if((startTime[0] == compareTo[0]) && (startTime[1] <= compareTo[1])) return true;
                if((endTime[0]   == compareTo[0]) && (compareTo[1] <= endTime[1]))   return true;
                if((startTime[0] < compareTo[0])  && (compareTo[0] <  endTime[0]))   return true;
            }
        }
        return false; 
    }
    
    /**
     * Version         1.0
     * 
     * Strategy : find the first technician available
     * Search technicians user under the Miner region office account and 
     * if a technician has open capacity during the work window, 
     * populate the suggested tech and suggested worktime field.
     * following rules apply in determine tech capacity 
            a. The tech has auto-dispatch flag set to yes                                           DONE
            b. The tech has calendar (YTD: Salesforce calendar vs FSO calendar) open for that day, 
                this clause potentially pushable to next sprint                 
            c. Confirmed job (work orders placed on calendar) + existing suggestted work order      DONE
                for that day < capacity                                                             
            d. Loop thru days in the work window                                                    DONE
     */
    public static list<WorkOrder> populateSuggestedTechnician(list<WorkOrder> workOrders){ 
        List<Id> vendorIds = UNITY_Utils.joiningByFieldList(workOrders,'UNITY_Assigned_Vendor__c');
        Map<Id,List<User>> vendorTechniciansMap = new Map<Id,List<User>>();
        List<Id> technicians = new List<Id>();
        
        // obtain the technicians involved in the vendors which are available for auto dispatch
        for(User technician : retrieveUsersConcerningToVendorTrades(vendorIds)) {
            List<User> techniciansForVendor = vendorTechniciansMap.get(technician.AccountId);
            if(techniciansForVendor == null){
                techniciansForVendor = new List<User>();   
                vendorTechniciansMap.put(technician.AccountId, techniciansForVendor);
            }
            if(technician.UNITY_Auto_Dispatch__c) {
                techniciansForVendor.add(technician);
                technicians.add(technician.Id);
            }
        }
        
        Map<Id,Set<Id>> userSkillsMap = new Map<Id,Set<Id>>();
        
        // obtain the skills for each technician saving in a map with key as technician id and value the list of skills.
        for(FSO__SkillUser__c skillUser : [SELECT FSO__Skill__c, FSO__User__c FROM FSO__SkillUser__c 
                                          WHERE FSO__User__c IN : technicians]) {
            Set<Id> skillsForTechnician = userSkillsMap.get(skillUser.FSO__User__c);
            if (skillsForTechnician == NULL) {
                skillsForTechnician = new Set<Id>();
                userSkillsMap.put(skillUser.FSO__User__c, skillsForTechnician);
            }
            skillsForTechnician.add(skillUser.FSO__Skill__c);                        
        }
        
        // keep the capacity used for a job date and technician
        Map<String,Integer> jobDateTechnicianUsedMap = new Map<String,Integer>();
        String jobDateTechnicianKey;
        
        // retrieve the confirmed and unconfirmed work orders
        for(WorkOrder workOrder : [SELECT          Id, WorkOrderNumber,
                                                   UNITY_Trade__c,
                                                   Status,
                                                   UNITY_Suggested_Technician__c,
                                                   UNITY_Suggested_Technician__r.name,
                                                   UNITY_Suggested_Work_Date__c,
                                                   StartDate,
                                                   UNITY_Assigned_Vendor__r.UNITY_TimeZoneSidKey__c,
                                                   OwnerId 
                                           FROM WorkOrder
                                           WHERE UNITY_Assigned_Vendor__c IN :vendorIds AND
                                                ((Status = : UNITY_Constants.WO_STATUS_NEW AND
                                                UNITY_Suggested_Technician__c != NULL AND
                                                UNITY_Suggested_Work_Date__c != NULL) OR
                                                (Status != : UNITY_Constants.WO_STATUS_NEW AND
                                                 StartDate != NULL))]) {
                                                                               
            String technicianInWOKey;
            DateTime jobDateTime;
                                                     
            // wo unconfirmed                                       
            if(workOrder.Status == UNITY_Constants.WO_STATUS_NEW) {
                technicianInWOKey = workOrder.UNITY_Suggested_Technician__c;
                jobDateTime = workOrder.UNITY_Suggested_Work_Date__c;
            } else {
                // wo confirmed
                technicianInWOKey = workOrder.OwnerId;
                jobDateTime = workOrder.StartDate;
            }              
                                                     
            Date localDate = UNITY_Utils.getDateTime(jobDateTime, null, workOrder.UNITY_Assigned_Vendor__r.UNITY_TimeZoneSidKey__c).localDatetime.date();
            jobDateTechnicianKey = jobDateTechnicianKey(localDate,technicianInWOKey);  
                                                     
            //populate jobDateTechnicianUsedMap Map
            integer val = (jobDateTechnicianUsedMap.get(jobDateTechnicianKey) == null)?0:jobDateTechnicianUsedMap.get(jobDateTechnicianKey);
            jobDateTechnicianUsedMap.put(jobDateTechnicianKey, val + 1);                                               
                                                             
        }
        
        // assign the technician to the work, finding the first technician who matches. 
        for(WorkOrder workOrder : workOrders) {
            Datetime dateNow = UNITY_Utils.getDateTime(Datetime.now(), null, workOrder.UNITY_Assigned_Vendor__r.UNITY_TimeZoneSidKey__c).localDatetime;
            Boolean technicianFound = false;
            // iterate over the technicians associated to the vendor
            if((workOrder.UNITY_Assigned_Vendor__c!=null)&&(vendorTechniciansMap.get(workOrder.UNITY_Assigned_Vendor__c) != null)){
                for(User technician : vendorTechniciansMap.get(workOrder.UNITY_Assigned_Vendor__c)) {
                
                    Set<Id> skillsToTechnician = userSkillsMap.get(technician.Id);
                    
                    if((skillsToTechnician!=null) && (skillsToTechnician.contains(workOrder.UNITY_Trade__c))) {
                        
                        //iterate over work window range
                        if((workOrder.UNITY_Work_Window_Begin__c!=null) && (workOrder.UNITY_Work_Window_End__c!=null)){
                            UNITY_Utils.DateTimeZone dtz = UNITY_Utils.getDateTime(workOrder.UNITY_Work_Window_Begin__c, null, workOrder.UNITY_Assigned_Vendor__r.UNITY_TimeZoneSidKey__c);
                            Integer offsetHour = dtz.offsetHour;
                            Datetime beginDatetime = dtz.localDatetime.date();
                            Datetime endDatetime = UNITY_Utils.getDateTime(workOrder.UNITY_Work_Window_End__c, null, workOrder.UNITY_Assigned_Vendor__r.UNITY_TimeZoneSidKey__c).localDatetime.date();
                            if(dateNow > beginDatetime) {
                                beginDatetime = dateNow;
                            }
                            for(Datetime currentDatetime = beginDatetime;  
                                currentDatetime <= endDatetime; 
                                currentDatetime = currentDatetime.AddDays(1)) {
                                String jobDateTechKey = jobDateTechnicianKey(currentDatetime.date(),technician.Id);
                                    
                                //Confirmed job (work orders placed on calendar) + existing suggestted work order 
                                //for that day < capacity    
                                if((jobDateTechnicianUsedMap.get(jobDateTechKey)==null) || (jobDateTechnicianUsedMap.get(jobDateTechKey) < technician.UNITY_Tech_Capacity__c)) {
                                    workOrder.UNITY_Suggested_Technician__c = technician.Id;
                                    workOrder.UNITY_Suggested_Work_Date__c = currentDatetime.addHours(-offsetHour).date();
                                    
                                    // add the suggested technician to the set of wo involved to be consider 
                                    // as a potential hit again.
                                    jobDateTechnicianUsedMap.put(jobDateTechKey, ((jobDateTechnicianUsedMap.get(jobDateTechKey)==null)?0:jobDateTechnicianUsedMap.get(jobDateTechKey))+1);
                                    
                                    technicianFound = true;
                                    break;
                                }
                            }
                        }
                    }
                    
                    if(technicianFound) {
                        // no search in the next technician for this wo.
                        break;
                    }
                }
            }
        }
        
        return workOrders;
    }
    
   /*
    * Retrieve all user ids concerning to the vendor trades, which are partner technician vendors.
    */
    public static List<User> retrieveUsersConcerningToVendorTrades(List<Id> accountIds) {
        // retrieve the users associated to contacts which are related to vendor belongs to trades,
        // which are partner technician vendors
        return [SELECT Id, Contact.AccountId, UNITY_Auto_Dispatch__c,AccountId, UNITY_Tech_Capacity__c FROM User 
                WHERE ContactId IN (SELECT Id FROM Contact WHERE AccountId IN : accountIds)];// AND 
                    //ProfileId IN (SELECT Id FROM Profile 
                    //                               WHERE Name =:UNITY_Constants.PROFILE_PARTNER_TECHNICIAN_VENDOR_NAME)];
                                                   //WHERE Name =:UNITY_Constants.PROFILE_TECHNICIAN_SELF_PERFORM_NAME)];
    }
    

    private static String jobDateTechnicianKey(Date jobDate,Id technicianId) {
        return String.valueOf(jobDate)+technicianId;
    }
    
    
   /*  Name    : createVendorCandidates
    *  Note    : Retrieve all user ids concerning to the vendor trades, which are partner technician vendors.
    *  Param 1 : list<UNITY_wrapperVendorByTrade> , list of vendor trade from which create candidates
    *  Param 2 : WorkOrder , create candidate for WO 
    */
    public static void createVendorCandidates( list<UNITY_wrapperVendorByTrade> vendors, WorkOrder onWo){
        
        Map<String,UNITY_Vendor_Assignment__c> assignments = new Map<String,UNITY_Vendor_Assignment__c>();
            
        for(UNITY_wrapperVendorByTrade vendor :vendors){
            UNITY_Vendor_Assignment__c newAssignment = new UNITY_Vendor_Assignment__c();
            newAssignment.Request_Type__c  = onWo.RecordType.Name;
            newAssignment.Trade__c         = onWo.UNITY_Trade__c;
            newAssignment.Customer__c      = onWo.AccountId;
            newAssignment.Work_Order__c    = onWo.id;
            newAssignment.Vendor__c        = vendor.id;
            newAssignment.Status__c        = 'Candidate';
            assignments.put(vendor.id+'-'+onWo.UNITY_Trade__c,newAssignment);  
        }
        insert assignments.values();
        
        for(UNITY_wrapperVendorByTrade vendor :vendors){
            vendor.setAssignment(assignments.get(vendor.id+'-'+vendor.tradeId));     
        }
    }
    
    
   /*  
    *  Name    : createVendorCandidates
    *  Note    : Search for vendors at the location key, independent from account or WO 
    *  Param 1 : String, location key 
    *  Return  : list<UNITY_wrapperVendorByTrade> 
    */
    public static list<UNITY_wrapperVendorByTrade> getVendorsSpecific(String locationKey){
        
        list<UNITY_wrapperVendorByTrade> toReturn = new list<UNITY_wrapperVendorByTrade>();
        
        // list of vendors at the location 
        list<UNITY_Vendor_Covered_Location__c> aux_vendorlocations = new list<UNITY_Vendor_Covered_Location__c>();
        
        // kay   : account id 
        // value : account
        Map<id,Account> vendors   = new Map<id,Account>();
        
        // kay   : vendor id - trade Id
        // value : UNITY_Vendor_Assignment__c
        Map<id,List<UNITY_Vendor_Trade__c>> vendorTrades = new Map<id,List<UNITY_Vendor_Trade__c>>();
        
        // list of vendor id at the location 
        List<id> vendorsIds = new List<id>();
        
        if(locationKey != null){
           
            aux_vendorlocations = [SELECT id, Vendor__c FROM UNITY_Vendor_Covered_Location__c WHERE Location_Key__c  = :locationKey];
            
            // get vendors id 
            for(UNITY_Vendor_Covered_Location__c var :aux_vendorlocations){
                vendorsIds.add(var.Vendor__c);
            }
            
            vendors = UNITY_Utils.getAccounts(vendorsIds);   
            
            vendorTrades  = getTradesCovered(vendors.keySet(),null); 
            
            for(Id vendorId :vendorTrades.keySet()){
                for(UNITY_Vendor_Trade__c vendorTrade :vendorTrades.get(vendorId)){
                    
                    // get the wrapper object 
                    UNITY_wrapperVendorByTrade wvbt = getWrapperVendorTrade(vendors.get(vendorId), 
                                                                            vendorTrade, 
                                                                            null, null, null);
                    
                    toReturn.add(wvbt);
                }
             }
        }
        return toReturn;
    }
    
    /*  
    *  Name    : getVendorAssignmentWarning
    *  Note    : Search for vendors at the location key, independent from account or WO 
    *  Param 1 : UNITY_wrapperVendorByTrade vendor trade wrapper 
    *  Param 2 : boolean, is vendor out of network ?
    *  Return  : String, warning message 
    */
    public static string getVendorAssignmentWarning( UNITY_wrapperVendorByTrade vendor , boolean isOON ){
        
        string text  = null;
        
        if(vendor.isCandidateOffHours || vendor.willBeCandidateOffHours ) text = 'Off Hour' ;
       
        if(vendor.isCandidateBelowMargin || vendor.willBeCandidateOffHours ) 
            if(text!=null) text += ', Below Margin' ; else text = 'Below Margin';
        
        if(vendor.isRejected) 
            if(text!=null) text += ', Previously Rejected' ; else text = 'Previously Rejected';
        
        if( (vendor.isOON || ((vendor.assignment == null) && isOON)) ) 
            if(text!=null) text += ', Out of Network' ; else text = 'Out of Network';
        
        return text;
    }  
    
}