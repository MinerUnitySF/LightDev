/*
 * Name : UNITY_AssetAvailability
 * Note : Handle Asset History
 * Date : 05/12/2016
 */
public with sharing class UNITY_AssetAvailability {

    private static String CASE_KEY = 'cases';
    private static String ASSET_HISTORY_KEY = 'assetHistories';
    private static Map<Id,Case> case_processed   = new Map<Id,Case>();
    private static Map<String,Map<Datetime,Decimal>>        accountIdAssetId_totalCostToAdd = new Map<String,Map<Datetime,Decimal>> ();
    private static Map<String,UNITY_Asset_History__c>       asset_history_processed         = new Map<String,UNITY_Asset_History__c>();
    private static Map<String,List<UNITY_Asset_History__c>> root_asset_history              = new Map<String,List<UNITY_Asset_History__c>>();


    // Contructor 
    public UNITY_AssetAvailability() {}

    /*
     * Name : calculateAvailability
     * Note : Main method to hanlde bulk casese  
     */
    public static void calculateAvailability(Set<Id> casesId) {

        Date                    MIN_START_DATE              = Date.today();
        // account id + , + asset id 
        String                  accountId_assetId_key       = '';
        // all assets related to WOLI.Asset and WOLI.Asset.Root_Parent
        Set<Id>                 all_assets                  = new Set<Id>();
        // all accounts related to Case -> WO ->  WOLI with Assets
        Set<Id>                 accountIds                  = new Set<Id>();
        // all the invices ids related to the cases
        Set<Id>                 all_invoices                = new Set<Id>();
        // key set for [account Id+','+asset Id] string
        Set<String>             accountId_assetId           = new Set<String>();
        // key   : child asset Id 
        // value : root asset Id 
        Map<Id,Id>              childAssetId_rootAssetId         = new Map<Id,Id>();
        // Set of Invice ids grouped by Case Id
        Map<Id,Set<Id>>         caseId_assetsId             = new Map<Id,Set<Id>>();
        // Set of Child Assets grouped by WO where WO -> WOLI -> Asset
        Map<Id,Set<Id>>         assets_related_to_woli      = new Map<Id,Set<Id>>();
        // Set of Root Assets grouped by Case where  Case -> WO -> WOLI -> Asset -> Root Asset
        Map<Id,Set<Id>>         root_assets_related_to_woli = new Map<Id,Set<Id>>();
        // account id -> Fiscal Year detail 
        Map<Id,FiscalYear>      accountId_fiscalYear        = new Map<Id,FiscalYear>();
        // Set of Invoices id grouped by key Case Id
        Map<String,Set<Id>>     caseId_invoiceIds           = new Map<String,Set<Id>>();
        // Set of Cases id grouped by key (account id + , + asset id)
        Map<String,Set<Id>>     accountIdAssetId_casesId    = new Map<String,Set<Id>>();

        // key   : case id 
        // value : 
        //         asset id + '_for_' + wo id        ->  when InvouceLI.asset != null && InvouceLI.WOLI != null
        //         asset id + '_split_for_' + wo id  ->  when InvouceLI.asset == null && InvouceLI.WOLI != null
        //         asset id + '_split_case' + wo id  ->  when InvouceLI.asset == null && InvouceLI.WOLI == null

        Map<Id,Map<String,Decimal>> caseId_totalCosts       = new Map<Id,Map<String,Decimal>>();
        

        // key   = Account id +','+ Asset id 
        // value = List of asset histories
        Map<String,List<UNITY_Asset_History__c>>  accAsset_assetHistoryMap = new Map<String,List<UNITY_Asset_History__c>>();
        
        // Query all the cases | apply "WHERE" condition to get the right records 
        // Get the child WOs that way retrive the Service Time
        // Get the child Invoices for calculate the Total cost Ownership
        Map<Id,Case> casesMap = getCases(casesId);

        // Collect Data from Case Map
        for(Case onCase :casesMap.values()){

            // Init the map for ILI
            if(caseId_totalCosts.get(onCase.Id)==null) caseId_totalCosts.put(onCase.Id , new Map<String,Decimal>());

            // Get invoice ids gruped by case
            if(caseId_invoiceIds.get(onCase.Id)==null)caseId_invoiceIds.put(onCase.Id,new Set<Id>());
            for(UNITY_Invoice__c invoice :onCase.Invoices__r){
                all_invoices.add(invoice.Id);
                caseId_invoiceIds.get(onCase.Id).add(invoice.Id);
            }
            System.debug('#####all_invoices: ' + all_invoices);
            // Get the min downTime date and that way retrive all the Asset history after it
            if((onCase.AccountId!=null) && (accountId_fiscalYear.get(onCase.AccountId)==null)){
                accountId_fiscalYear.put(onCase.AccountId, new FiscalYear(Integer.valueOf(onCase.Account.UNITY_Fiscal_Year_Start_Month__c),onCase.Account.UNITY_Fiscal_Year_Based_On__c));
                if(MIN_START_DATE >= accountId_fiscalYear.get(onCase.AccountId).yearStrat) 
                    MIN_START_DATE = accountId_fiscalYear.get(onCase.AccountId).yearStrat;
            }
        }

        // Query Invoices Line Item
        Map<Id,UNITY_Invoice_Line_Item__c> invoiceLIMap = getILI(all_invoices);

        for(UNITY_Invoice_Line_Item__c invoiceLI :invoiceLIMap.values()){
            Map<String,Decimal> totalCostMap = storingTotalCostHandle(invoiceLI,caseId_totalCosts.get(invoiceLI.UNITY_Invoice__r.UNITY_Case__c));
            System.debug('##### totalCostMap.values().size(): ' + totalCostMap.values().size());
            if(totalCostMap.values().size() > 0){
                for(String key: totalCostMap.keySet()){
                    System.debug('##### totalCostMap[key]: ' + key);
                    System.debug('##### totalCostMap.get(key): ' + totalCostMap.get(key));
                    caseId_totalCosts.get(invoiceLI.UNITY_Invoice__r.UNITY_Case__c).put(key,totalCostMap.get(key));
                }
            }
            //storingTotalCostHandle(invoiceLI, caseId_totalCosts.get(invoiceLI.UNITY_Invoice__r.UNITY_Case__c));
        }

        // Query all the WOLIs
        Map<Id,WorkOrderLineItem> woliMap = getWOLI(casesMap.keySet());

        // Collect Data from woli map 
        for(WorkOrderLineItem onWOLI :woliMap.values()){
            // check first if we have a relationship to Asset
            if(onWOLI.AssetId != null){

                accountId_assetId_key = onWOLI.WorkOrder.AccountId+','+onWOLI.AssetId;
                
                if(assets_related_to_woli.get(onWOLI.WorkOrderId) == null )
                    assets_related_to_woli.put(onWOLI.WorkOrderId, new Set<Id>());
                    
                if(accountIdAssetId_casesId.get(accountId_assetId_key) == null )
                    accountIdAssetId_casesId.put(accountId_assetId_key, new Set<Id>());

                if(caseId_assetsId.get(onWOLI.WorkOrder.CaseId) == null )
                    caseId_assetsId.put(onWOLI.WorkOrder.CaseId, new Set<Id>());
                
                all_assets.add(onWOLI.AssetId);
                accountIds.add(onWOLI.WorkOrder.AccountId);
                accountId_assetId.add(accountId_assetId_key);
                caseId_assetsId.get(onWOLI.WorkOrder.CaseId).add(onWOLI.AssetId);
                assets_related_to_woli.get(onWOLI.WorkOrderId).add(onWOLI.AssetId);
                accountIdAssetId_casesId.get(accountId_assetId_key).add(onWOLI.WorkOrder.CaseId);
                
                accAsset_assetHistoryMap.put(accountId_assetId_key, new List<UNITY_Asset_History__c>());
                
                // for this Asset level we will calculate only the down-time 
                if((onWOLI.Asset.RootAssetId != null)&&(onWOLI.Asset.RootAssetId != onWOLI.AssetId)){
                    
                    accountId_assetId_key = onWOLI.WorkOrder.AccountId+','+onWOLI.Asset.RootAssetId;

                    if(root_assets_related_to_woli.get(onWOLI.WorkOrder.CaseId) == null )
                        root_assets_related_to_woli.put(onWOLI.WorkOrder.CaseId, new Set<Id>());
                    
                    if(accountIdAssetId_casesId.get(accountId_assetId_key) == null )
                        accountIdAssetId_casesId.put(accountId_assetId_key, new Set<Id>());
                

                    accAsset_assetHistoryMap.put(accountId_assetId_key, new List<UNITY_Asset_History__c>());

                    all_assets.add(onWOLI.Asset.RootAssetId);
                    accountId_assetId.add(accountId_assetId_key);
                    childAssetId_rootAssetId.put(onWOLI.AssetId, onWOLI.Asset.RootAssetId);
                    //caseId_assetsId.get(onWOLI.WorkOrder.CaseId).add(onWOLI.Asset.RootAssetId);
                    accountIdAssetId_casesId.get(accountId_assetId_key).add(onWOLI.WorkOrder.CaseId);
                    root_assets_related_to_woli.get(onWOLI.WorkOrder.CaseId).add(onWOLI.Asset.RootAssetId);
                }
            }
        }

        Map<Id,UNITY_Asset_History__c> assetHistoryMap = getAssetHistory(all_assets, accountIds, MIN_START_DATE);
        
        // Collect Data from Asset History Records 
        for(UNITY_Asset_History__c assetHitory :assetHistoryMap.values()){
            accountId_assetId_key = assetHitory.UNITY_Account__c+','+assetHitory.UNITY_Asset__c;

            if(accAsset_assetHistoryMap.get(accountId_assetId_key)==null)
                accAsset_assetHistoryMap.put(accountId_assetId_key, new List<UNITY_Asset_History__c>());

            accAsset_assetHistoryMap.get(accountId_assetId_key).add(assetHitory);
        }
        system.debug('>>> sam caseId_totalCosts '+caseId_totalCosts);
        for(String accId_assetId :accountId_assetId){
            // Get the Account Id and the Asset Id 
            String assetId   = accId_assetId.split(',')[1];
            String accountId = accId_assetId.split(',')[0];

            system.debug('>>> accId_assetId '+accId_assetId);
            // Process the Service Time and Down-Time for the Asset 
            handleY(  assetId,
                      accountId,
                      childAssetId_rootAssetId.get(assetId),
                      casesMap,
                      caseId_totalCosts,
                      caseId_assetsId,
                      assets_related_to_woli,
                      accountIdAssetId_casesId.get(accId_assetId),
                      accAsset_assetHistoryMap.get(accId_assetId),
                      accountId_fiscalYear.get(accountId) );

            
        }
        system.debug('>>> accountIdAssetId_totalCostToAdd '+accountIdAssetId_totalCostToAdd);
        system.debug('>>> root_asset_history '+root_asset_history);
        for(String accountIdAssetId :accountIdAssetId_totalCostToAdd.keySet()){
            for(DateTime compare :accountIdAssetId_totalCostToAdd.get(accountIdAssetId).keySet()){
                rollup(accountIdAssetId,accountIdAssetId_totalCostToAdd.get(accountIdAssetId).get(compare),compare);
            }
        }

        if(!case_processed.isEmpty()) update case_processed.values();
        if(!asset_history_processed.isEmpty()) upsert asset_history_processed.values();
    }

    /*
     * Name   : handleX
     * Note   : Handle Service Time and Down-Time one Asset 
     * Param 1: Asset Id
     * Param 2: Account Id
     * Param 3: Map Of Cases
     * Param 4: Set of Asset related to WO by WO -> WOLI -> Asset
     * Param 5: Case Ids related to the asset by WO -> WOLI -> Asset
     * Param 6: Asset History related to the asset and customer account
     * Param 7: Customer Fistal Year Details
     */
    private static void handleY(  Id                assetId,
                                  Id                accountId,
                                  Id                rootAssetId,
                                  Map<Id,Case>      casesMap,
                                  Map<Id,Map<String,Decimal>> totalCostByCase,
                                  Map<Id,Set<Id>>   caseId_assetsId,
                                  Map<Id,Set<Id>>   childAssets,
                                  Set<Id>           caseIds,
                                  List<UNITY_Asset_History__c> assetHistories,
                                  FiscalYear        customerFiscalYear) {

        Date     aux_up_time_date;
        Date     aux_down_time_date;
        String   aux_new_asset_history_key = null;
        String   aux_root_asset_history_key= null;
        Boolean  aux_is_root               = false;
        Boolean  aux_use_case_times;
        Integer  aux_count_assets_in_wo    = 0;
        Decimal  aux_splitted_no           = 0;
        Decimal  aux_splitted_by_wo        = 0;
        Decimal  aux_splitted_by_case      = 0;
        Decimal  aux_total_cost_to_add     = 0;
        Decimal  aux_down_time_duration    = 0;
        Decimal  aux_service_time_duration = 0;
        DateTime aux_compare_date;
        Map<String,Decimal>    aux_total_cost_data;
        UNITY_Asset_History__c aux_asset_history = null;
        
        if((caseIds!=null) && !caseIds.isEmpty())
            for(Id caseId: caseIds){
                Case onCase = casesMap.get(caseId);
                aux_count_assets_in_wo    = 0;
                aux_splitted_no           = 0;
                aux_splitted_by_wo        = 0;
                aux_splitted_by_case      = 0;
                aux_total_cost_to_add     = 0;
                aux_down_time_duration    = 0;
                aux_service_time_duration = 0;
                aux_compare_date          = ((onCase.UNITY_Asset_Down_At__c==null)?DateTime.now():onCase.UNITY_Asset_Down_At__c);
                aux_use_case_times        = ((onCase.UNITY_Asset_Down_At__c!=null) &&(onCase.UNITY_Asset_Up_At__c!=null));
                aux_total_cost_data       = totalCostByCase.get(caseId);
                system.debug('>>> sam iter caseId '+caseId);
                system.debug('>>> sam aux_total_cost  '+aux_total_cost_data); 
                system.debug('>>> sam caseId_assetsId '+caseId_assetsId); 
                if((assetHistories!=null) && (!assetHistories.isEmpty())) 
                    for(UNITY_Asset_History__c assetHistory :assetHistories){
                        if((assetHistory.UNITY_Start_Date__c <= aux_compare_date)&&(aux_compare_date <= assetHistory.UNITY_End_Date__c)){
                            aux_asset_history = assetHistory;
                            if(aux_asset_history.UNITY_Down_Time__c    == null) aux_asset_history.UNITY_Down_Time__c    = 0;
                            if(aux_asset_history.UNITY_Service_Time__c == null) aux_asset_history.UNITY_Service_Time__c = 0;
                            if(aux_asset_history.UNITY_Total_Cost_Ownership__c == null) aux_asset_history.UNITY_Total_Cost_Ownership__c = 0;
                        }
                    }
    
                if(aux_asset_history == null) {
                    aux_asset_history = new UNITY_Asset_History__c();
                    aux_asset_history.UNITY_Asset__c      = assetId;
                    aux_asset_history.UNITY_Account__c    = accountId;
                    aux_asset_history.UNITY_End_Date__c   = customerFiscalYear.getYearEnd(aux_compare_date); 
                    aux_asset_history.UNITY_Down_Time__c  = 0;
                    aux_asset_history.UNITY_Start_Date__c = customerFiscalYear.getYearStart(aux_compare_date);
                    aux_asset_history.UNITY_FiscalYear__c = customerFiscalYear.getAssetHitoryYear(aux_compare_date);
                    aux_asset_history.UNITY_Service_Time__c = 0;
                    aux_asset_history.UNITY_Total_Cost_Ownership__c = 0;
                    // update list by reference   
                    assetHistories.add(aux_asset_history);
                }
                
                if(aux_use_case_times){
                    aux_down_time_duration = onCase.UNITY_Asset_Down_Time__c;
                    aux_asset_history.UNITY_Down_Time__c += aux_down_time_duration;
                }else{
                    aux_down_time_duration = 0;
                }
                
                for(WorkOrder wo :onCase.WorkOrders){

                    if(!aux_use_case_times && (wo.SFPS_FS_TotalServiceTime__c != null)) aux_down_time_duration += wo.SFPS_FS_TotalServiceTime__c;
                    
                    if((childAssets.get(wo.id)!=null) && childAssets.get(wo.id).contains(assetId)){
    
                        aux_asset_history.UNITY_Service_Time__c += ((wo.SFPS_FS_TotalServiceTime__c!=null)?wo.SFPS_FS_TotalServiceTime__c:0);

                        //aux_count_assets_in_wo = childAssets.get(wo.id).size();

                        if(aux_total_cost_data.get('split_for_'+wo.Id)!=null){
                            aux_splitted_by_wo += (aux_total_cost_data.get('split_for_'+wo.Id)/childAssets.get(wo.id).size());
                            //aux_asset_history.UNITY_Total_Cost_Ownership__c += (aux_total_cost.get('split_for_'+wo.Id)/aux_count_assets_in_wo);
                        }
                        
                        if(aux_total_cost_data.get(assetId+'_for_wo_'+wo.Id)!=null){
                            aux_splitted_no += aux_total_cost_data.get(assetId+'_for_wo_'+wo.Id);
                            //aux_asset_history.UNITY_Total_Cost_Ownership__c += aux_total_cost.get(assetId+'_for_wo_'+wo.Id);
                        }    
                    }
                }
                
                if(!aux_use_case_times) aux_asset_history.UNITY_Down_Time__c += aux_down_time_duration;
                
                if((caseId_assetsId.get(caseId)!=null)&&(caseId_assetsId.get(caseId).contains(assetId))&&(aux_total_cost_data.get('split_for_case')!=null)){

                    aux_splitted_by_case = (aux_total_cost_data.get('split_for_case')/caseId_assetsId.get(caseId).size());

                    /*aux_asset_history.UNITY_Total_Cost_Ownership__c += 
                        (((caseId_assetsId.get(caseId)!=null)&&(!caseId_assetsId.get(caseId).isEmpty()))?
                             (aux_total_cost.get('split_for_case')/caseId_assetsId.get(caseId).size()):0);*/
                }
                
                System.debug('#####<IRI> aux_splitted_by_wo: '+aux_splitted_by_wo);
                System.debug('#####<IRI> aux_splitted_no: '+aux_splitted_no);
                System.debug('#####<IRI> aux_splitted_by_case: '+aux_splitted_by_case);
                
                aux_total_cost_to_add = (aux_splitted_by_wo + aux_splitted_no + aux_splitted_by_case);

                aux_asset_history.UNITY_Total_Cost_Ownership__c += aux_total_cost_to_add;

                aux_new_asset_history_key  = accountId+','+assetId+','+aux_asset_history.UNITY_Start_Date__c.format();
                aux_root_asset_history_key = accountId+','+assetId;

                if(rootAssetId != null){
                    if(accountIdAssetId_totalCostToAdd.get(accountId+','+rootAssetId) == null)
                        accountIdAssetId_totalCostToAdd.put(accountId+','+rootAssetId,new Map<DateTime,Decimal>{aux_compare_date => aux_total_cost_to_add});
                    else{
                        Decimal aux_val = accountIdAssetId_totalCostToAdd.get(accountId+','+rootAssetId).get(aux_compare_date);
                        if(aux_val == null)
                            accountIdAssetId_totalCostToAdd.get(accountId+','+rootAssetId).put(aux_compare_date, aux_total_cost_to_add);
                        else
                            accountIdAssetId_totalCostToAdd.get(accountId+','+rootAssetId).put(aux_compare_date, aux_val + aux_total_cost_to_add );
                    }
                }
                    
    
                if(rootAssetId==null) aux_is_root = true;
                
                system.debug('>>> aux_is_root '+aux_is_root);
                system.debug('>>> (root_asset_history.get(aux_root_asset_history_key) '+(root_asset_history.get(aux_root_asset_history_key)==null));
                if(aux_is_root && (root_asset_history.get(aux_root_asset_history_key)==null))
                    root_asset_history.put(aux_root_asset_history_key, new List<UNITY_Asset_History__c>{aux_asset_history});
                else if(aux_is_root && (root_asset_history.get(aux_root_asset_history_key)!=null))
                    root_asset_history.get(aux_root_asset_history_key).add(aux_asset_history);
/*
                if(aux_is_root && root_asset_history.get(aux_root_asset_history_key)==null)
                    root_asset_history.put(aux_root_asset_history_key, new List<UNITY_Asset_History__c>{aux_asset_history});
                else if(!aux_is_root && ) rollup(aux_root_asset_history_key, aux_total_cost_to_add, aux_compare_date);
                */
                if((aux_asset_history.Id!=null)&&!asset_history_processed.keySet().contains(aux_asset_history.Id)){
                    asset_history_processed.put(aux_asset_history.Id,aux_asset_history);

                }else if((aux_asset_history.Id==null)&&(asset_history_processed.get(aux_new_asset_history_key)==null)){
                    asset_history_processed.put(aux_new_asset_history_key,aux_asset_history);
                } 
                onCase.UNITY_Service_Data_Processed__c = true;
                if(!case_processed.KeySet().contains(onCase.Id)) case_processed.put(onCase.Id,onCase);
               
            }
    }

    private static void rollup(String  rootAssetKey, Decimal toAdd, DateTime compare_date){
        system.debug(rootAssetKey);
        system.debug(toAdd);
        system.debug(compare_date);
        if(root_asset_history.get(rootAssetKey)!=null)
            for(UNITY_Asset_History__c ah :root_asset_history.get(rootAssetKey)){
                if((ah.UNITY_Start_Date__c <= compare_date)&&(compare_date <= ah.UNITY_End_Date__c)){
                    if(ah.UNITY_Total_Cost_Ownership__c == null) ah.UNITY_Total_Cost_Ownership__c = 0;
                    ah.UNITY_Total_Cost_Ownership__c += toAdd;
                }
            }
    }

    
    // Help inner class to handle fiscal year 
    public class FiscalYear{
        
        Date    yearEnd   {get;set;}
        Date    yearStrat {get;set;}
        String  base  {get;set;}
        Integer month {get;set;}
        

        public FiscalYear(Date s, Date e){
            this.yearEnd    = e;
            this.yearStrat  = s; 
        }

        public FiscalYear(Integer month, String base){

            this.base  = base;
            this.month = month;
            Date aux_end;
            if(base == 'Starting Month'){ 
                this.yearStrat = Date.newInstance(Date.today().year(), month, 1);
                this.yearEnd   = this.yearStrat.addMonths(12).addDays(-1);
            }else if(base == 'Ending Month'){
                this.yearEnd   = Date.newInstance(Date.today().year(), month, Date.daysInMonth(Date.today().year(),month));
                this.yearStrat = Date.newInstance(Date.today().year(), month+1, 1).addMonths(-12);
            }
        }

        public Integer getAssetHitoryYear(DateTime s){
            if(this.base == 'Starting Month')
                return this.getYearStart(s).year();
            else if (this.base == 'Ending Month')
                return this.getYearEnd(s).year();

            return null;
        }

        public Date getYearStart(DateTime s){
            if((this.yearStrat<=s)&&(s<=this.yearEnd))
                return this.yearStrat;
            else if(s<this.yearStrat)
                return this.yearStrat.addMonths(-12);
            else if(this.yearEnd<s)
                return this.yearStrat.addMonths(12);

            return null;
        }

        public Date getYearEnd(DateTime s){
            if((this.yearStrat<=s)&&(s<=this.yearEnd))
                return this.yearEnd;
            else if(s<this.yearStrat)
                return this.yearEnd.addMonths(-12);
            else if(this.yearEnd<s)
                return this.yearEnd.addMonths(12);

            return null;
        }
    }



    private static Map<String,Decimal> storingTotalCostHandle(UNITY_Invoice_Line_Item__c invoiceLI, Map<String,Decimal> referenceMap){
        Map<String,Decimal> tempRefMap = new Map<String,Decimal>();
        String  aux_key = '';
        Decimal totalCost = ((invoiceLI.UNITY_Ownership_Cost__c==null)?0:invoiceLI.UNITY_Ownership_Cost__c);

        if((invoiceLI.UNITY_Asset__c!=null) && (invoiceLI.UNITY_WorkOrder__c!=null)){

            aux_key = invoiceLI.UNITY_Asset__c+'_for_wo_'+invoiceLI.UNITY_WorkOrder__c;

            //if(referenceMap.get(aux_key)==null) referenceMap.put(aux_key,0);
            if(tempRefMap.get(aux_key)==null) tempRefMap.put(aux_key,0);
            Decimal temp = referenceMap.containsKey(aux_key) ? referenceMap.get(aux_key) : 0;
            tempRefMap.put(aux_key, totalCost + temp);
            //referenceMap.put(aux_key, totalCost + referenceMap.get(aux_key));
            
        }else if((invoiceLI.UNITY_Asset__c==null) && (invoiceLI.UNITY_WorkOrder__c!=null)){

            aux_key = 'split_for_'+invoiceLI.UNITY_WorkOrder__c;
            
            //if(referenceMap.get(aux_key)==null) referenceMap.put(aux_key,0);
            if(tempRefMap.get(aux_key)==null) tempRefMap.put(aux_key,0);
            Decimal temp = referenceMap.containsKey(aux_key) ? referenceMap.get(aux_key) : 0;
            tempRefMap.put(aux_key, totalCost + temp);
            //referenceMap.put(aux_key, totalCost + referenceMap.get(aux_key));
                
        }else if((invoiceLI.UNITY_Asset__c==null) && (invoiceLI.UNITY_WorkOrder__c==null)){
            
            aux_key = 'split_for_case';
            
            //if(referenceMap.get(aux_key)==null) referenceMap.put(aux_key,0);
            if(tempRefMap.get(aux_key)==null) tempRefMap.put(aux_key,0);
            Decimal temp = referenceMap.containsKey(aux_key) ? referenceMap.get(aux_key) : 0;
            tempRefMap.put(aux_key, totalCost + temp);
            //referenceMap.put(aux_key, totalCost + referenceMap.get(aux_key));
        }
        
        return tempRefMap;
    }


    private static Map<Id,UNITY_Invoice_Line_Item__c> getILI(Set<Id> invoicesIds){
      return new Map<Id,UNITY_Invoice_Line_Item__c>([ SELECT  Id, 
                                                              UNITY_Asset__c,
                                                              UNITY_WorkOrder__c,
                                                              UNITY_Ownership_Cost__c,
                                                              UNITY_Invoice__r.UNITY_Case__c
                                                      FROM    UNITY_Invoice_Line_Item__c 
                                                      WHERE   UNITY_Invoice__c IN :invoicesIds ]);
    }

    private static Map<Id,WorkOrderLineItem> getWOLI(Set<Id> caseIds){
      return new Map<Id,WorkOrderLineItem>([SELECT  Id, 
                                                    AssetId,
                                                    WorkOrderId,
                                                    WorkOrder.CaseId,
                                                    Asset.RootAssetId,
                                                    WorkOrder.AccountId
                                            FROM    WorkOrderLineItem 
                                                    WHERE    WorkOrder.CaseId IN :caseIds 
                                                    AND AssetId <> null ]);
    }

    private static Map<Id,UNITY_Asset_History__c> getAssetHistory(Set<Id> all_assets, Set<Id> accountIds, Date minDate ){
      return new Map<Id,UNITY_Asset_History__c>(    [SELECT Id, 
                                                            UNITY_Asset__c,
                                                            UNITY_Account__c,
                                                            UNITY_End_Date__c,
                                                            UNITY_Down_Time__c,
                                                            UNITY_Start_Date__c,
                                                            UNITY_Service_Time__c,
                                                            UNITY_Total_Cost_Ownership__c
                                                    FROM    UNITY_Asset_History__c 
                                                    WHERE   (UNITY_Asset__c IN :all_assets) 
                                                            AND (UNITY_Account__c IN :accountIds)
                                                            AND  UNITY_Start_Date__c >= :minDate]);
    }

    private static Map<Id,Case> getCases(Set<Id> caseIds){
      return new Map<Id,Case>([SELECT Id, 
                                      AssetId,
                                      AccountId,
                                      UNITY_Asset_Down__c, 
                                      UNITY_Asset_Up_At__c,
                                      UNITY_Asset_Down_At__c,
                                      UNITY_Asset_Down_Time__c,
                                      UNITY_Service_Data_Processed__c,
                                      Account.UNITY_TimeZoneSidKey__c,
                                      Account.UNITY_Fiscal_Year_Based_On__c,
                                      Account.UNITY_Fiscal_Year_Start_Month__c,
                                      (SELECT Id, SFPS_FS_TotalServiceTime__c FROM WorkOrders),
                                      (SELECT Id FROM Invoices__r WHERE UNITY_Invoice_Status__c = 'Invoice Finalized')
                              FROM     Case 
                              WHERE    (id IN :caseIds) 
                                      AND (Status = 'Closed') 
                                      AND (UNITY_Service_Data_Processed__c = false)
                                      AND (Account.UNITY_Fiscal_Year_Based_On__c <> null)
                                      AND (Account.UNITY_Fiscal_Year_Start_Month__c <> null)]);
    }

    
}