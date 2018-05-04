public class UNITY_VendorsFromWOController {

    // context account id
    private Id onWorkOrderId                {get;set;}
    
    // context account  
    private WorkOrder onWorkOrder   {get;set;}
    
    // list of vendors which cover the customer location and are customer preferred and they are not marked as do not use in the account record
    private list<UNITY_wrapperVendorByTrade> totalList{get;set;}
    
    // key   :  vendors Id + trade id
    // value :  wrapper vendor 
    private Map<String, UNITY_wrapperVendorByTrade> vendorTrade_to_vendor{get;set;}
    
    // vendor id to assign as 'Candidate' or 'Assigned'
    public  String vendorIdToAssign {get;set;}
    
    // enable or disable "Assign" btn
    public  boolean showAssignBtn   {get;set;}
    
    public  boolean isVendorAssigned   {get;set;}
    
    public  String reviewPOVendorId {get;set;}

    // values from filters
    public  String locationKeyF     {get;set;}
    public  String tradeIdF         {get;set;}
    public  String requestTypeAbbrF {get;set;}
    public  String statusF          {get;set;}
    public  String warningMessage   {get;set;}
    // Vendor Status on Account  
    public List<String> statusOptions{get;set;}
    
    // key   : abbr type 
    // value : request type name 
    public  Map<String,String > requestTypes {get;set;}
    
    // key   : trade id 
    // value : trade name
    public  Map<String,String > trades {get;set;}
    
    // list of trades id, order to display to the Agent. The first value added need to be the selected one
    public  List<String>        tradesIds {get;set;}
    
    // detect when Agent search out of network 
    public  Boolean outscope        {get;set;}
    
    // list of vendors to display to the Agent
    public list<UNITY_wrapperVendorByTrade>  vendors {get;set;}
    
    // list of vendors to display to the Agent who are Out of Network but they have assigment records linked to th WO
    public list<UNITY_wrapperVendorByTrade>  vendorsOutScope {get;set;}
        
    // flag when no vandors to display 
    public  Boolean notVendorsToShow{get;set;}
    
    // indicates if the Aget can search OON
    public boolean canSearch{get;set;}
    
    private Set<id> vendorsOutScopeIds{get;set;}
    
    public  boolean allowedCountryCode{get;set;}
    
    // key   : location key 
    // value : key   : trade id 
    //         value : trade name
    // note :  help to remember the trades per location covered 
    private Map<String,Map<String,String>> aux_locationKey_trades  {get;set;} 
    
    // values from work order 
    private String locationKey{get;set;}
    private String tradeId{get;set;}
    private String requestTypeAbbr{get;set;}
  
    
    
    // *** Constructor  *** //
    public UNITY_VendorsFromWOController(ApexPages.StandardController stdController ){
        
        this.onWorkOrderId          = stdController.getId();
        this.trades                 = new Map<String,String>();
        this.requestTypes           = new Map<String,String>();
        this.aux_locationKey_trades = new Map<String,Map<String,String>>();
        this.vendorTrade_to_vendor  = new Map<String, UNITY_wrapperVendorByTrade>();
        this.totalList              = new list<UNITY_wrapperVendorByTrade>();
        this.vendors                = new list<UNITY_wrapperVendorByTrade>();
        this.vendorsOutScope        = new list<UNITY_wrapperVendorByTrade>();
        this.tradesIds              = new List<String>();
        this.statusOptions          =  new list<String>();
        this.vendorIdToAssign       = '';
        this.showAssignBtn          = true;
        this.notVendorsToShow       = false;
        this.canSearch              = false;
        this.outscope               = false; 
        this.isVendorAssigned       = false;
       
        // Get vendor status picklist values from vendors account object 
        list<Schema.PicklistEntry> accountStatusValues  =  Account.getSObjectType().getDescribe().fields.getMap().get('UNITY_Vendor_Status__c').getDescribe().getPickListValues();
        
        for (Schema.PicklistEntry var :accountStatusValues){
           this.statusOptions.add(var.getValue());
        }
        this.statusOptions.sort();
      
        
        // check if the Agent can perform some actions on the WO, like expand the search of vendors on the WO and assign the vendor to it.
        this.evaluateWO();
        
        if(this.onWorkOrder != null){
            
            // store the work order values
            this.locationKey     = UNITY_Utils.getLocationKey(onWorkOrder.Account.shippingCountryCode, onWorkOrder.Account.ShippingPostalCode);
            this.tradeId         = onWorkOrder.UNITY_Trade__c;
            this.requestTypeAbbr = UNITY_Constants.WO_RECORDTYPE_ABBR.get(onWorkOrder.RecordType.Name);

             
            // store the filters values by default from the WO, and dorpdown lists
            this.locationKeyF     = UNITY_Utils.getLocationKey(onWorkOrder.Account.shippingCountryCode, onWorkOrder.Account.ShippingPostalCode);
            this.tradeIdF         = onWorkOrder.UNITY_Trade__c;
            this.requestTypeAbbrF = UNITY_Constants.WO_RECORDTYPE_ABBR.get(onWorkOrder.RecordType.Name);
            this.statusF = 'Active';
            
            this.tradesIds.add(onWorkOrder.UNITY_Trade__c);
            this.trades.put(onWorkOrder.UNITY_Trade__c, onWorkOrder.UNITY_Trade__r.Name);
            this.aux_locationKey_trades.put(this.locationKeyF, new Map<string,String>{onWorkOrder.UNITY_Trade__c=>onWorkOrder.UNITY_Trade__r.Name});
            
            this.requestTypes.put(UNITY_Constants.WO_RECORDTYPE_ABBR.get(onWorkOrder.RecordType.Name), onWorkOrder.RecordType.Name);
          
        }     
    }
    
    /*
     *  Name  : showAllVendors
     *  Note  : get all vendors at location ,then filter them      
     */
    public void showAllVendors(){
        
        this.evaluateWO(); 
        
        //this.getVendors(this.locationKeyF);
        this.getVendors(new list<id>{this.onWorkOrder.AccountId},false,false);
        //checkWOVendorStatus();
        
        filterByAccountVendorStatus();
        
        
    }

    /*
     *  Name  : showAllVendors
     *  Note  : query all vendors at location and get the assignments and sort them             
     */  
    public void nextOperations(){
        
        getVendors(new list<id>{this.onWorkOrder.AccountId},true,true);
        
        filterByAccountVendorStatus();
    } 
    
   /*
    *   Name  :  Samuel Astol
    *   Note  :  Action for assign btn on the page, create a new record of UNITY_Vendor_Assignment__c, 
    *            and set status 'Candidate' if record is created or 'Assigned' if record is updated          
    */
    public void assignVendor(){
        
        this.evaluateWO();
        
        this.reviewPOVendorId     = this.vendorIdToAssign;
        isVendorAssigned          = false;
        
        UNITY_wrapperVendorByTrade vendorW = vendorTrade_to_vendor.get(this.vendorIdToAssign+'-'+this.tradeIdF);
        
        if(vendorW != null){
            
            String warning = this.warningMessage;
            
            // we just need to create the new assignment record if it does not exist, if it exist the return null 
            // when the Vendor Status is updated on the WO record then the trigger should update the Vendor Assignment record too 
            try{
                
                this.reviewPOCreation(true);
                
                Order reviewOrder = (((vendorW.assignment!=null)&&(vendorW.assignment.Initial_PO__c!=null))?[SELECT id, Status FROM Order WHERE id = :vendorW.assignment.Initial_PO__c]:null);
                
                if((reviewOrder != null) && (reviewOrder.Status != 'Final') && onWorkOrder.UNITY_PO_Review_Pending__c ){
                     throw new VendorAssignmentException('When PO Pending Review flag is ON, PO has to be created first and final status.');
                }else if(reviewOrder.Status != 'Final'){
                     throw new VendorAssignmentException('PO Status should be Final before Assign.');
                }
                
                if(onWorkOrder.UNITY_Dispatch_Attempts__c==null) onWorkOrder.UNITY_Dispatch_Attempts__c = 1;
                    else onWorkOrder.UNITY_Dispatch_Attempts__c++;
                onWorkOrder.UNITY_Vendor_Status__c         = 'Assigned';
                onWorkOrder.UNITY_Assigned_Vendor__c       =  (id)vendorW.id;
                onWorkOrder.UNITY_Vendor_Last_Assigned__c  =  UNITY_Utils.getDateTime();
                onWorkOrder.UNITY_OON_Vendor_Assigned__c   =  (((isSearchingOutScope() && (vendorTrade_to_vendor.get(vendorW.id+'-'+this.tradeId)==null))  || vendorW.isOON )? true : false);
                onWorkOrder.UNITY_Vendor_Assignment_Warning__c = warning;
                update onWorkOrder;
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Vendor Assigned. Closing tab in 5 seconds...'));
                showAssignBtn = false;
                isVendorAssigned = true;
                
            }catch(Exception e){
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Vendor does not cover the Work Order details. '+vendorTrade_to_vendor.keySet()));
        }
    } 
    
    public DateTime getDateTime(){
        return  DateTime.now(); 
    }  
    
    public void assignAction(){
        this.getVendorAssignmentWarning();
        this.assignVendor();
    }  
    
    public void createPO(){
        try{
            this.reviewPOCreation(false);
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    } 
    
    
    /*
     *   Name  : getVendorAssignmentWarning     
     *   Note  : get warning before assign vendor          
     */
    public void getVendorAssignmentWarning(){
        
        string text  = null;
        UNITY_wrapperVendorByTrade vendor = vendorTrade_to_vendor.get(this.vendorIdToAssign+'-'+this.tradeIdF);
        
        if(vendor!=null){
            vendor.setWillBeCandidateOffHours();
            boolean isOON =  (isSearchingOutScope() && (vendorTrade_to_vendor.get(vendor.id+'-'+this.tradeId)==null));
            
            if(vendor.isCandidateOffHours || vendor.willBeCandidateOffHours ) text = 'Off Hour' ;
           
            if(vendor.isCandidateBelowMargin || vendor.willBeCandidateOffHours ) 
                if(text!=null) text += ', Below Margin' ; else text = 'Below Margin';
            
            if(vendor.isRejected) 
              if(text!=null) text += ', Previously Rejected' ; else text = 'Previously Rejected';
            
            if( (vendor.isOON || ((vendor.assignment == null) && isOON)) ) 
              if(text!=null) text += ', Out of Network' ; else text = 'Out of Network';
        }  
        warningMessage = text;
    }  
    
    /*
     *   Name  :  evaluateWO
     *   Note  :  verify that the Agent can : Expand search on WO, assign a new vendor from other location, trade and request type              
     */
    public void evaluateWO(){
        
        // get the least version of the WO record 
        onWorkOrder = getUpdatedFields(onWorkOrderId);
        
        // flag that indicates if the Agent can expand the search.
        if(onWorkOrder.UNITY_OON_Vendor_Eligible__c) canSearch = true ; else canSearch = false;
        
        // flag if the Agent can assign vendor to the WO.
        showAssignBtn = availableAssignmentAction();
           
    }  
    
    /*
     *  Name  :  availableAssignmentAction
     *  Note  :  verify that the Agent can assign vendor to the WO.        
     */
    public boolean availableAssignmentAction(){
        
        set<String> aux_status =  new set<String>{UNITY_Constants.WO_STATUS_ASSIGNED,UNITY_Constants.WO_STATUS_ACCEPTED};
        
        if( this.allowedCountryCode && (aux_status.contains(onWorkOrder.UNITY_Vendor_Status__c) || (!onWorkOrder.UNITY_OON_Vendor_Approved__c && isSearchingOutScope())) ){
            return false;
        }
        
        return true;
        
    }
    
    /*
     *   Name :  isSearchingOutScope
     *   Note :  verify if the Agent is searching out of scope of WO details (location,trade, request type)          
     */
    public boolean isSearchingOutScope(){
        
        boolean aux = false;
        if( (this.locationKeyF != this.locationKey) || (this.tradeIdF != this.tradeId) || (this.requestTypeAbbrF != this.requestTypeAbbr) ){
            aux =  true;
        }
        this.outscope = aux;
        
        return aux;
    }
    
    /*
     *   Name  :  getUpdatedFields
     *   Note  :  get least fields values          
     */
    public WorkOrder getUpdatedFields(id woId){
        
        list<WorkOrder> wOrders = new list<WorkOrder>();
        WorkOrder toReturn = null;
        
        wOrders =  [SELECT UNITY_Trade__c,
                              UNITY_Vendor_Status__c,
                              UNITY_Trade__r.Name , 
                              RecordType.Name,
                              Account.Name,
                              AccountId,
                              Account.ShippingPostalCode , 
                              Account.ShippingCountryCode,
                              UNITY_PO_Review_Pending__c,
                              UNITY_Assigned_Vendor__c,
                              UNITY_PO_Template__c,
                              UNITY_Dispatch_Attempts__c,
                              UNITY_Customer_Service_Contract_Price__c,
                              UNITY_Customer_Margin__c,
                              UNITY_OON_Vendor_Eligible__c ,UNITY_OON_Vendor_Assigned__c,
                              UNITY_OON_Vendor_Approved__c ,UNITY_Vendor_Assignment_Warning__c,
                              UNITY_Vendor_Contract__c,
                              UNITY_Business_Unit__c
                       FROM  WorkOrder
                       WHERE id = :woId ];

        if(wOrders.size()>0){
            toReturn = wOrders.get(0);
            if(!UNITY_Constants.allowVendorCountries.contains(wOrders.get(0).Account.ShippingCountryCode)){
                this.allowedCountryCode = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Complete the Shipping Address for '+wOrders.get(0).Account.Name+', be sure the Account is in one of this countries '+UNITY_Constants.allowVendorCountries));
            }else{
                this.allowedCountryCode = true;
            }
        }
        return   toReturn;
    }
    
    /*
     *   Name  :  filterByAccountVendorStatus
     *   Note  :  filter by status of the accounts         
     */
    public void filterByAccountVendorStatus(){
        
        list<UNITY_wrapperVendorByTrade>  aux = new list<UNITY_wrapperVendorByTrade>();
        
        for(integer index = 0 ; index < vendors.size() ; index ++){
            
            if(this.vendors.get(index).status == statusF){
                aux.add(this.vendors.get(index));
            }
        }
        this.vendors = new list<UNITY_wrapperVendorByTrade>(aux);
        
        vendors.sort();
    } 
    
    /*
     *   Name  :  applyFilter
     *   Note  :  action btn "go"         
     */
    public void applyFilter(){
        
        evaluateWO(); 
        
        if(isSearchingOutScope()) getVendors(this.locationKeyF);
          else getVendors(new list<id>{this.onWorkOrder.AccountId},false,false);
        
        filterByAccountVendorStatus();
        
        
    }
    
    /*
     *   Name  :  Samuel Astol
     *   Param :  String location key 
     *   Note  :  get vendors by location        
     */    
    private void getVendors(String locationKey){
        
        if(locationKey != null){
            
            this.totalList = UNITY_Vendor_Utils.getVendorsSpecific(locationKey);
            this.handleList(this.totalList,false,false);
        }
        
    }
    
   /*
    *   Name    :  getVendors
    *   Param 1 :  list< account ids >
    *   Param 2 :  boolean, create VA records
    *   Note    :  get all vendors at the location            
    */
    public void getVendors(list<id> ids, boolean onlyAssignmentRecords, boolean createVA){
        
        //Map< id, list<UNITY_wrapperVendorByTrade>> aux_map = UNITY_Vendor_Utils.getVendorsSpecific(ids, createVA);
        Map< id, list<UNITY_wrapperVendorByTrade>> aux_map = UNITY_Vendor_Utils.getVendorsSpecific(ids, Account.getSObjectType(), null, false, false );  
        if( aux_map.get(ids.get(0)) != null ){
            
            this.handleList( aux_map.get(ids.get(0)),onlyAssignmentRecords, createVA);
        }
        
    }
    
   /*
    *   Name    :  handleList
    *   Param 1 :  list<UNITY_wrapperVendorByTrade>
    *   Param 2 :  boolean, create VA records
    *   Note    :  
    */
    public void handleList(list<UNITY_wrapperVendorByTrade> dataList,boolean onlyWithAssignments, boolean createVA){
        
        List<String> aux_trades  = new List<String>();
        String       aux_tradeId = '';
        list<UNITY_wrapperVendorByTrade>aux_vendors = new  list<UNITY_wrapperVendorByTrade>();
        list<UNITY_wrapperVendorByTrade>aux_vendors_to_create_candidates_from = new  list<UNITY_wrapperVendorByTrade>();
        
        if(dataList != null && (dataList.size()>0)){
            
            this.totalList  = dataList;
            
            this.vendors            = new  list<UNITY_wrapperVendorByTrade>();
            this.vendorsOutScope    = new  list<UNITY_wrapperVendorByTrade>();
            this.vendorsOutScopeIds = new  Set<id>();
            
            // store the trade by location 
            for(UNITY_wrapperVendorByTrade var :dataList){
                
                this.trades.put(var.tradeId, var.tradeName);
                
                this.vendorTrade_to_vendor.put(var.id+'-'+var.tradeId, var);
                if(this.aux_locationKey_trades.get(this.locationKeyF)==null)this.aux_locationKey_trades.put(this.locationKeyF, new Map<String,String>());
                if(this.aux_locationKey_trades.get(this.locationKeyF).get(var.tradeId) == null)this.aux_locationKey_trades.get(this.locationKeyF).put(var.tradeId,var.tradeName);
            }
            
            // if there are trades which covers the location 
            if(this.aux_locationKey_trades.get(this.locationKeyF).get(this.tradeIdF) != null){
                
                this.tradesIds  = new  List<String>();
                this.trades     = new  Map<String,String>();
                tradesIds.add(this.tradeIdF);
                for(String tid :this.aux_locationKey_trades.get(this.locationKeyF).keySet()){
                    if(tid!=this.tradeIdF ){
                      tradesIds.add(tid);  
                    }
                }
                this.trades = this.aux_locationKey_trades.get(this.locationKeyF);
                // filter the vendors and set context for WO
                aux_vendors = UNITY_Vendor_Utils.wrapperVendorByTradeFilter(dataList,this.requestTypeAbbrF,this.tradeIdF , (double)onWorkOrder.UNITY_Customer_Service_Contract_Price__c, (double)onWorkOrder.UNITY_Customer_Margin__c);
            }
            
        }
        
        this.vendors = checkForAssignments(aux_vendors,onlyWithAssignments,createVA);
        
        if(this.vendors.size() == 0)
            notVendorsToShow = true; 
        else {
            notVendorsToShow = false;
        }   
        
        
    }
    
   /*
    *   Name    :  checkForAssignments
    *   Param 1 :  list<UNITY_wrapperVendorByTrade>
    *   Param 2 :  boolean, return with assignments 
    *   Param 3 :  boolean, create VA records 
    *   Note    :  
    */
    public list<UNITY_wrapperVendorByTrade> checkForAssignments(list<UNITY_wrapperVendorByTrade> aux_vendors,boolean onlyWithAssignmnets, boolean shouldCreateAssignmnets){
      
        list<UNITY_wrapperVendorByTrade> toReturn = new list<UNITY_wrapperVendorByTrade>();
        list<UNITY_wrapperVendorByTrade> aux_vendors_to_create_candidates_from = new list<UNITY_wrapperVendorByTrade>();
        
      list<UNITY_Vendor_Assignment__c> vendorAssignmenst = [SELECT id,Status__c, LastModifiedDate ,Customer__c , OON__c,Initial_PO__c,
                                                              Vendor__c, Vendor__r.name, Vendor__r.phone,Vendor__r.Account_Email__c,
                                                              Work_Order__c, Trade__c , Request_Type__c, Last_Assigned__c 
                                                              FROM UNITY_Vendor_Assignment__c 
                                                              WHERE (Work_Order__c = :onWorkOrderId ) AND
                                                                    (Trade__c      = :onWorkOrder.UNITY_Trade__c)
                                                              ORDER BY Status__c ];
        
        integer  aux_max   =  3;
        integer  aux_index =  0;
        
        if(vendorAssignmenst.size()>0){
            for(UNITY_Vendor_Assignment__c var :vendorAssignmenst){
                if(!var.OON__c){
                    if(this.vendorTrade_to_vendor.get(var.Vendor__c +'-'+var.Trade__c)!=null){
                        this.vendorTrade_to_vendor.get(var.Vendor__c +'-'+var.Trade__c).setAssignment(var);
                        toReturn.add(this.vendorTrade_to_vendor.get(var.Vendor__c +'-'+var.Trade__c));                        
                    }
                }else{
                    if(!isSearchingOutScope()){
                        this.vendorsOutScopeIds.add(var.Vendor__c);
                        UNITY_wrapperVendorByTrade vOut = new UNITY_wrapperVendorByTrade();
                        vOut.name  = var.Vendor__r.name;
                        vOut.id    = var.Vendor__c;
                        vOut.phone = var.Vendor__r.phone;
                        vOut.email = var.Vendor__r.Account_Email__c;
                        vOut.setAssignment(var);
                        this.vendorTrade_to_vendor.put(var.Vendor__c +'-'+var.Trade__c,vOut);
                        this.vendorsOutScope.add(vOut);
                    }else if(this.vendorTrade_to_vendor.get(var.Vendor__c +'-'+this.tradeIdF)!=null){
                        this.vendorTrade_to_vendor.get(var.Vendor__c +'-'+this.tradeIdF).setAssignment(var);
                    }
                }
            }
        }
        
        if(shouldCreateAssignmnets && (toReturn.size()==0) && (!isSearchingOutScope())){
            while( (aux_index < aux_vendors.size()) && (aux_vendors_to_create_candidates_from.size() < aux_max) ){
                aux_vendors_to_create_candidates_from.add(aux_vendors.get(aux_index));
                aux_index++;
            } 
            if(aux_vendors_to_create_candidates_from.size() > 0) UNITY_Vendor_Utils.createVendorCandidates(aux_vendors_to_create_candidates_from, onWorkOrder);
            toReturn = aux_vendors_to_create_candidates_from;
        }
        
        if(!onlyWithAssignmnets){
            toReturn = aux_vendors;
        }
        return toReturn;
    }
    
    /*
     * Name  : createPO
     * Param : UNITY_wrapperVendorByTrade, vendor wrapper 
     * Note  :
     * 
     */
    public Order createPO(UNITY_wrapperVendorByTrade vendorW){
         
         Order toReturn = null;
         
         //try{
             Map<String,Object> order_fields = new Map<String,Object>();
             order_fields.put('FSO__WorkOrder__c'    , onWorkOrder.id);
             order_fields.put('UNITY_Vendor__c'      , vendorW.id);
             order_fields.put('UNITY_PO_Template__c' , onWorkOrder.UNITY_PO_Template__c);
             order_fields.put('Status'               , 'Draft'); 
             order_fields.put('EffectiveDate'        , Date.today());    
             order_fields.put('AccountId'            , onWorkOrder.AccountId);    
             order_fields.put('UNITY_Business_Unit__c', onWorkOrder.UNITY_Business_Unit__c);
             toReturn = (Order)UNITY_Utils.createObject(Order.getSObjectType(),order_fields);
             insert toReturn;
         /*}catch(Exception e){
             
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
             
         }*/
         return toReturn; 
    } 
    
    /*
     * Name  : createAssignment
     * Param : UNITY_wrapperVendorByTrade, vendor wrapper 
     * Note  :
     * 
     */
    public UNITY_Vendor_Assignment__c createAssignment(UNITY_wrapperVendorByTrade vendorW){
         
         UNITY_Vendor_Assignment__c onVA = null;
         
         //try{
             onVA = new UNITY_Vendor_Assignment__c();
             onVA.Request_Type__c  = onWorkOrder.RecordType.Name;
             onVA.Trade__c         = onWorkOrder.UNITY_Trade__c;
             onVA.Customer__c      = onWorkOrder.AccountId;
             onVA.Work_Order__c    = onWorkOrder.id;
             onVA.Vendor__c        = vendorW.id;
             onVA.Status__c        = 'Candidate';
             onVA.OON__c           = isSearchingOutScope();
             insert onVA;
         /*}catch(DmlException e){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
         }*/
         return onVA; 
    } 
    
    /*
     * Name  : reviewPO
     * Note  : Review conditions for create PO
     */
     public boolean reviewPOCreation(boolean updateToFinal){
        
        boolean toReturn = false;
        
        UNITY_wrapperVendorByTrade vendorW = vendorTrade_to_vendor.get(this.reviewPOVendorId+'-'+this.tradeIdF);
        
        if(vendorW !=null){
            
            if(vendorW.assignment == null) vendorW.assignment = this.createAssignment(vendorW);
            
            boolean existOrder = ((vendorW.assignment != null) && (vendorW.assignment.Initial_PO__c != null)) ;
            
            Order onOrder = null;
            
            if(!existOrder){   
                    onOrder = createPO(vendorW);
                    existOrder = ((onOrder != null) && (onOrder.id != null));
                    if(existOrder){ 
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Purchase Order created.'));
                        vendorW.assignment.Initial_PO__c = onOrder.id;
                        update vendorW.assignment;
                    }
                    
                    if(updateToFinal && existOrder && !onWorkOrder.UNITY_PO_Review_Pending__c){
                        Order aux_order = new Order();
                        aux_order.id = onOrder.id;
                        aux_order.Status = 'Final';
                        update aux_order;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Purchase Order Status updated to Final.'));
                    }
             }
            
             toReturn = existOrder;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No vendor details founds.'));
        }
        return toReturn;
    }
    
    private class VendorAssignmentException Extends Exception{}
}