public class UNITYPM_PCaseBulkInvoiceCtrl {
  public ApexPages.StandardController controller;
  public String caseId {get; private set;}
  public boolean hasError {get; private set;}
  Public Case prgCase {get; set;}
  Public List<Case> cases {get;set;}
  Public List<case> pmCases {get;set;}
  Public Map<ID, case> pmCasesMap {get;set;}
  Public List<pmCaseInvoiciceWrapper> caseInvPageWrp {get;set;}
  Public Boolean selected {get;set;}
  Public List<pmCaseInvoiciceWrapper> caseInvWrp {get;set;}
  Public Integer count {get;set;}
  public boolean selectedInvoice {get;set;}
  public String warningSelectedInvoice {get;set;}
  public Boolean assetRanking {get;set;}
  public Boolean doRendered {get;set;}
  public string selectedFilterVal {get;set;}
  public string  selectedFilterForDataVal {get;set;}
  public List<SelectOption> dependentFilterOption {get;set;} 
  public Boolean hasData {get;set;}
  public Boolean doNotRendered {get;set;}
  
   public UNITYPM_PCaseBulkInvoiceCtrl(ApexPages.StandardController c){
        this.controller = c;
        SObject s = c.getRecord();
        this.caseId =(String)s.get('Id');  // id.valueOf('5001g000003Buqh'); 
        this.hasError = false;
        this.selected = false;
        this.count = 1;
        this.selectedInvoice = false; 
        this.warningSelectedInvoice = '';
        this.assetRanking = false;
        this.doNotRendered = false;
        
        system.debug('>>> call constractor >>>');
        setProgramCase();
        setPreventativeMaintenanceCase();
   }
  
   public List<SelectOption> getFiltersList () {
     List<SelectOption> optns = new List<Selectoption>();
     List<string> filtersList = new List<string>{'--None--','Case Status','Case Record Type', 'Case Type', 'Invoice Status' }; 
     for (string num: filtersList) {
        optns.add(new selectOption(num, num));
     } 
     return optns;
   }
   
   public void applyFilter(){
      system.debug('>>>> applyFilter >>');
      if (selectedFilterVal == 'Case Status'){
            dependentFilterOption = new List<SelectOption>();
            List<string> caseStatusList = new List<string>{'--None--','In Progress','Service Completed','Invoiced', 'Pending Billing', 'Web/INV', 'Closed', 'Cancelled'}; 
             for (string status: caseStatusList) {
                dependentFilterOption.add(new selectOption(status, status));
             }                 
       }              
       else if (selectedFilterVal == 'Case Record Type'){
          dependentFilterOption = new List<SelectOption>();
            List<string> caseStatusList = new List<string>{'--None--','Non-Work','Service Request','Preventative Maintenance'}; 
             for (string status: caseStatusList) {
                dependentFilterOption.add(new selectOption(status, status));
             }     
       } 
       else if (selectedFilterVal == 'Case Type'){
           dependentFilterOption = new List<SelectOption>();
            List<string> caseStatusList = new List<string>{'--None--','PMO','PMA'}; 
             for (string status: caseStatusList) {
                dependentFilterOption.add(new selectOption(status, status));
             }   
       } 
       else if ( selectedFilterVal == 'Invoice Status'){
           dependentFilterOption = new List<SelectOption>();
            List<string> caseStatusList = new List<string>{'--None--','Invoice Creation','Invoice sent for Manager Approval','Discount - Approved by Manager','Discount - Rejected by Manager','Sent to Customer','Returned to Agent','Invoice Amended','Completed','Cancelled'}; 
             for (string status: caseStatusList) {
                dependentFilterOption.add(new selectOption(status, status));
             }   
       } 
       else if (selectedFilterVal == '--None--'){
           dependentFilterOption = new List<SelectOption>();
            List<string> caseFlterList = new List<string>{'--None--'};
           for (string status: caseFlterList) {
                dependentFilterOption.add(new selectOption(status, status));
            }   
       } 
    } 
    
   public List<SelectOption> getDependentFilterList() {
        return dependentFilterOption;
    } 
  
  /*
    public void applyFilterShowData(){
        system.debug('>>> selectedFilterVal >>>' + selectedFilterVal);
        system.debug('>>> selectedFilterForDataVal >>>' + selectedFilterForDataVal);
        this.hasError = false;
        this.selected = false;
        this.count = 1;
        this.selectedInvoice = false; 
        this.warningSelectedInvoice = '';
        this.assetRanking = false;
        this.doRendered = false;
      
        if (selectedFilterVal =='Case Status' && !selectedFilterForDataVal.contains('None')){
             setPMCaseWithStatusCase(selectedFilterForDataVal);
        }
         if (selectedFilterVal =='Case Record Type' && !selectedFilterForDataVal.contains('None')){
             setPMCaseWithRTCase(selectedFilterForDataVal);
        }     
        if (selectedFilterVal =='Case Type' && !selectedFilterForDataVal.contains('None')){
             setPMCaseWithTypeCase(selectedFilterForDataVal);
        }       
             
       //not in use
          for (pmCaseInvoiciceWrapper casewrp: caseInvWrp){
            system.debug('>>>>case >>>>' + casewrp.cs.Status);
            
            for (invoiceWrapper invoice :casewrp.invwrapper){
             system.debug('>>>>invoice >>>>' + invoice);
             system.debug('>>>>invoice. >>>>' + invoice.invoice);
             
             for ( assetTypePriceRankWrapper asset : invoice.assetPriceWrapper)
                system.debug('>>>>asset >>>>' + asset);
            }
          }
      
    }
    */
  
    private void setProgramCase(){
       this.prgCase = [SELECT ID, UNITY_Customer__c,CaseNumber, Status,UNITYPM_Program_ID__c,RecordTypeId, RecordType.Name, Type, UNITY_Record_Type_Name__c,
                           UNITYPM_Program_Start__c, UNITYPM_Program_End__c, Origin, Priority, UNITY_Customer_WO__c,UNITY_NTE_Threshold__c
                                    FROM Case WHERE ID =:this.caseId];
    }
   
    private void setPreventativeMaintenanceCase(){
       this.pmCasesMap = new Map<ID, Case>();
       this.cases = [SELECT ID, UNITY_Customer__c,CaseNumber, Status,RecordTypeId,RecordType.Name, UNITY_Customer_WO__c,Type, UNITY_Record_Type_Name__c,
                           Origin,Priority, UNITY_Site_Location_Address__c, UNITYPM_Total_PM_Cases__c, Parent.ID, UNITY_NTE_Threshold__c
                                    FROM Case WHERE Parent.ID =:this.prgCase.ID ];
                                    
       for (Case cs : this.cases){
          // if (cs.RecordTypeId == UNITY_Constants.CASE_PREVENTATIVE_MAINTENANCE_RECORDTYPE){
               pmCasesMap.put(cs.id, cs);
           //}
       }
       
       getPMCasesWithInvoices();
    }
   
    //case status filter
    public Map<ID, Case> setPMCaseWithStatusCase(String caseStatus){
       this.pmCasesMap = new Map<ID, Case>();
       this.cases = [SELECT ID, UNITY_Customer__c,CaseNumber, Status,RecordTypeId,RecordType.Name, UNITY_Customer_WO__c,Type, UNITY_Record_Type_Name__c,
                           Origin,Priority, UNITY_Site_Location_Address__c, UNITYPM_Total_PM_Cases__c, Parent.ID, UNITY_NTE_Threshold__c
                                    FROM Case WHERE Parent.ID =:this.prgCase.ID AND Status =:caseStatus];
                                    
       for (Case cs : this.cases){
            this.pmCasesMap.put(cs.id, cs);
       }
       
       if (this.pmCasesMap.size()> 0)
             hasData =true;
      
       return this.pmCasesMap;
   }
  
    //case record type filter 
    public  Map<ID, Case> setPMCaseWithRTCase(String caseRecordType){
       this.pmCasesMap = new Map<ID, Case>();
       this.cases = [SELECT ID, UNITY_Customer__c,CaseNumber, Status,RecordTypeId,RecordType.Name, UNITY_Customer_WO__c,Type, UNITY_Record_Type_Name__c,
                           Origin,Priority, UNITY_Site_Location_Address__c, UNITYPM_Total_PM_Cases__c, Parent.ID, UNITY_NTE_Threshold__c
                                    FROM Case WHERE Parent.ID =:this.prgCase.ID AND RecordType.Name =:caseRecordType];
                                    
       for (Case cs : this.cases){
            this.pmCasesMap.put(cs.id, cs);
       }
    
      return this.pmCasesMap;
   }
   
    //case Type filter
    public  Map<ID, Case> setPMCaseWithTypeCase(String caseType){
       this.pmCasesMap = new Map<ID, Case>();
       if ( caseType == 'PMO' || caseType == 'PMA'){
          this.cases = [SELECT ID, UNITY_Customer__c,CaseNumber, Status,RecordTypeId,RecordType.Name, UNITY_Customer_WO__c,Type, UNITY_Record_Type_Name__c,
                           Origin,Priority, UNITY_Site_Location_Address__c, UNITYPM_Total_PM_Cases__c, Parent.ID, UNITY_NTE_Threshold__c
                                    FROM Case WHERE Parent.ID =:this.prgCase.ID AND Type =:caseType];
       }
       else{
           this.cases = [SELECT ID, UNITY_Customer__c,CaseNumber, Status,RecordTypeId,RecordType.Name, UNITY_Customer_WO__c,Type, UNITY_Record_Type_Name__c,
                           Origin,Priority, UNITY_Site_Location_Address__c, UNITYPM_Total_PM_Cases__c, Parent.ID, UNITY_NTE_Threshold__c
                                    FROM Case WHERE Parent.ID =:this.prgCase.ID]; 
       }
                                    
       for (Case cs : this.cases){
             this.pmCasesMap.put(cs.id, cs);
       }
     
       return this.pmCasesMap;
   }
   
    public  Map<ID, Case> setPMCaseWithOutFilter(){
       this.pmCasesMap = new Map<ID, Case>();
       this.cases = [SELECT ID, UNITY_Customer__c,CaseNumber, Status,RecordTypeId,RecordType.Name, UNITY_Customer_WO__c,Type, UNITY_Record_Type_Name__c,
                           Origin,Priority, UNITY_Site_Location_Address__c, UNITYPM_Total_PM_Cases__c, Parent.ID, UNITY_NTE_Threshold__c
                                    FROM Case WHERE Parent.ID =:this.prgCase.ID ];
                                    
       for (Case cs : this.cases){
             this.pmCasesMap.put(cs.id, cs);
       }
     
       return this.pmCasesMap;
   }
   
    //get all Invoices data
    public void  getPMCasesWithInvoices(){
      caseInvWrp = new  List<pmCaseInvoiciceWrapper>(); 
      List<UNITY_Invoice__c> invList = new List<UNITY_Invoice__c>();
      invList = [SELECT ID, UNITY_Case__c, UNITY_Customer_Service_Contract__c,Name,
                   UNITY_Total_Price_With_Service_Charge__c,UNITY_Final_Price2__c,UNITY_Total_Tax__c,
                   UNITY_Final_Price__c,UNITY_Invoice_Date__c, UNITY_Invoice_Status__c,
                   UNITY_Invoice_Margin__c,UNITY_Invoice_Margin_Amount__c,UNITY_Total_Cost__c,
                   UNITY_Tax_Processed__c,UNITY_Tax_Posted__c, UNITY_Total_Price__c, UNITY_SL_Process_Complete__c,
                   UNITYPM_Number_of_Assets__c,Number_of_Labor_Lines__c,Number_of_Travel_Lines__c,Number_of_Part_Lines__c
                      FROM UNITY_Invoice__c 
                       WHERE UNITY_Invoice_Status__c != 'Invoice Finalized' AND  UNITY_Case__c IN :this.pmCasesMap.keySet() ];
      
       Map <Case, List<UNITY_Invoice__c>> caseInvoiceMap = new Map<Case, List<UNITY_Invoice__c>>();
       Set<ID> invIDs = new Set<ID>();
       
       for (UNITY_Invoice__c inv : invList){
         //map with case + list of invoices 
         Case ct = pmCasesMap.get(inv.UNITY_Case__c);
         if (caseInvoiceMap.containsKey(ct)){
             List<UNITY_Invoice__c>invtemp = caseInvoiceMap.get(ct);
             invtemp.add(inv);
             caseInvoiceMap.put(ct, invtemp );
         }
         else{
            caseInvoiceMap.put(ct, new List<UNITY_Invoice__c> { inv }); 
         }
         
         invIDs.add(inv.ID);
       }
     
       //get asset type and total price for ranking
        List<UNITY_Invoice_Line_Item__c> invPMLines = [SELECT UNITY_Asset_Type__c, UNITY_Total_Price__c, UNITYPM_Is_Preventative_Maintenance__c,UNITY_Invoice__r.ID
                                                       FROM UNITY_Invoice_Line_Item__c 
                                                       WHERE   UNITY_Invoice__c IN:invIDs AND UNITYPM_Is_Preventative_Maintenance__c = true];
                                                       
        Map<ID, List<UNITY_Invoice_Line_Item__c>>invLineMap = new Map<ID, List<UNITY_Invoice_Line_Item__c>>(); 
        
        for (UNITY_Invoice_Line_Item__c line : invPMLines){
            
             if (invLineMap.containsKey(line.UNITY_Invoice__r.ID)){
                 List<UNITY_Invoice_Line_Item__c>invLinetemp = invLineMap.get(line.UNITY_Invoice__r.ID);
                 invLinetemp.add(line);
                 invLineMap.put(line.UNITY_Invoice__r.ID, invLinetemp );
             }
             else{
                invLineMap.put(line.UNITY_Invoice__r.ID, new List<UNITY_Invoice_Line_Item__c> { line }); 
             }
        }
        
        system.debug('### invLineMap #### ' + invLineMap.size());
        
        List<assetTypePriceRankWrapper> assetPriceWrapper = new List<assetTypePriceRankWrapper>();
          
        for (ID invID: invLineMap.keyset()){
            
             List<UNITY_Invoice_Line_Item__c> lines = invLineMap.get(invID);
             Map<String, List<Decimal>> assetPricemap = new Map<String, List<Decimal>>();   
         
             for (UNITY_Invoice_Line_Item__c line: lines){                                              
                if(assetPricemap.containsKey(line.UNITY_Asset_Type__c)) {
                    assetPricemap.get(line.UNITY_Asset_Type__c).add(line.UNITY_Total_Price__c);
                } else {
                    assetPricemap.put(line.UNITY_Asset_Type__c, new List<Decimal> { line.UNITY_Total_Price__c });
                }
              }
            
            
              for (String asset : assetPricemap.keySet()){
                List<Decimal> price = assetPricemap.get(asset);
                if (price.size()> 0){
                  price.sort();
                 
                  Decimal highestRate = price.get(price.size() - 1);
                  Decimal lowestRate = price[0];
                  assetPriceWrapper.add(new assetTypePriceRankWrapper(invID, asset, lowestRate, highestRate));
                  
                  assetRanking = true;
                }
            }
        }
       
       //populate wrapper class to get data on page
       for (Case csid : caseInvoiceMap.keyset()){
          List<UNITY_Invoice__c> invLst =  caseInvoiceMap.get(csid);
          
          List<invoiceWrapper>invWrp = new List<invoiceWrapper>();
             for (UNITY_Invoice__c inv:invLst){
                 
               List<assetTypePriceRankWrapper> assetPriceWrapperList = new List<assetTypePriceRankWrapper>();
               if ( assetPriceWrapper.size() > 0) { 
                   for (assetTypePriceRankWrapper assetWrapper : assetPriceWrapper) {
                       ID iID = assetWrapper.invoiceID;
                       if ( iID == inv.ID ){
                         assetPriceWrapperList.add(new assetTypePriceRankWrapper(assetWrapper.assetType, assetWrapper.lowestRate, assetWrapper.highestRate));
                       }
                   } 
                   
                    assetRanking = true;
                    
                   invWrp.add(new invoiceWrapper( false,inv, assetPriceWrapperList)); 
               }
               else
               {
                 invWrp.add(new invoiceWrapper( false,inv));
               }
             }
         
          caseInvWrp.add(new pmCaseInvoiciceWrapper (csid, invWrp));
          if (caseInvWrp.size() > 0)
               doRendered = true;
          system.debug('>>>   caseInvWrp >>>' + caseInvWrp);
          system.debug('>>>   doRendered >>>' + doRendered);
       }
   }
   
    public List<pmCaseInvoiciceWrapper>  getPMCasesWithInvoiceData(Map<ID, Case> tempCaseInvMap){
     this.hasError = false;
     this.selected = false;
     this.count = 1;
     this.selectedInvoice = false; 
     this.warningSelectedInvoice = '';
     this.assetRanking = false;
        
        system.debug('>>>  getPMCasesWithInvoiceData >> tempCaseInvMap >>>' + tempCaseInvMap);
    
      caseInvWrp = new  List<pmCaseInvoiciceWrapper>();  
      List<UNITY_Invoice__c> invList = new List<UNITY_Invoice__c>();
      invList = [SELECT ID, UNITY_Case__c, UNITY_Customer_Service_Contract__c,Name,
                   UNITY_Total_Price_With_Service_Charge__c,UNITY_Final_Price2__c,UNITY_Total_Tax__c,
                   UNITY_Final_Price__c,UNITY_Invoice_Date__c, UNITY_Invoice_Status__c,
                   UNITY_Invoice_Margin__c,UNITY_Invoice_Margin_Amount__c,UNITY_Total_Cost__c,
                   UNITY_Tax_Processed__c,UNITY_Tax_Posted__c, UNITY_Total_Price__c, UNITY_SL_Process_Complete__c,
                   UNITYPM_Number_of_Assets__c,Number_of_Labor_Lines__c,Number_of_Travel_Lines__c,Number_of_Part_Lines__c
                      FROM UNITY_Invoice__c 
                       WHERE UNITY_Case__c IN :tempCaseInvMap.keySet() ];
      
       Map <Case, List<UNITY_Invoice__c>> caseInvoiceMap = new Map<Case, List<UNITY_Invoice__c>>();
       Set<ID> invIDs = new Set<ID>();
       
       for (UNITY_Invoice__c inv : invList){
         //map with case + list of invoices 
         Case ct = tempCaseInvMap.get(inv.UNITY_Case__c);
         if (caseInvoiceMap.containsKey(ct)){
             List<UNITY_Invoice__c>invtemp = caseInvoiceMap.get(ct);
             invtemp.add(inv);
             caseInvoiceMap.put(ct, invtemp );
         }
         else{
            caseInvoiceMap.put(ct, new List<UNITY_Invoice__c> { inv }); 
         }
         
         invIDs.add(inv.ID);
       }
     
       //get asset type and total price for ranking
        List<UNITY_Invoice_Line_Item__c> invPMLines = [SELECT UNITY_Asset_Type__c, UNITY_Total_Price__c, UNITYPM_Is_Preventative_Maintenance__c,UNITY_Invoice__r.ID
                                                       FROM UNITY_Invoice_Line_Item__c 
                                                       WHERE   UNITY_Invoice__c IN:invIDs AND UNITYPM_Is_Preventative_Maintenance__c = true];
                                                       
        Map<ID, List<UNITY_Invoice_Line_Item__c>>invLineMap = new Map<ID, List<UNITY_Invoice_Line_Item__c>>(); 
        
        for (UNITY_Invoice_Line_Item__c line : invPMLines){
            
             if (invLineMap.containsKey(line.UNITY_Invoice__r.ID)){
                 List<UNITY_Invoice_Line_Item__c>invLinetemp = invLineMap.get(line.UNITY_Invoice__r.ID);
                 invLinetemp.add(line);
                 invLineMap.put(line.UNITY_Invoice__r.ID, invLinetemp );
             }
             else{
                invLineMap.put(line.UNITY_Invoice__r.ID, new List<UNITY_Invoice_Line_Item__c> { line }); 
             }
        }
        
        system.debug('### invLineMap #### ' + invLineMap.size());
        
        List<assetTypePriceRankWrapper> assetPriceWrapper = new List<assetTypePriceRankWrapper>();
          
        for (ID invID: invLineMap.keyset()){
            
            List<UNITY_Invoice_Line_Item__c> lines = invLineMap.get(invID);
            
             Map<String, List<Decimal>> assetPricemap = new Map<String, List<Decimal>>();   
         
             for (UNITY_Invoice_Line_Item__c line: lines){                                              
                if(assetPricemap.containsKey(line.UNITY_Asset_Type__c)) {
                    assetPricemap.get(line.UNITY_Asset_Type__c).add(line.UNITY_Total_Price__c);
                } else {
                    assetPricemap.put(line.UNITY_Asset_Type__c, new List<Decimal> { line.UNITY_Total_Price__c });
                }
              }
            
            
              for (String asset : assetPricemap.keySet()){
                List<Decimal> price = assetPricemap.get(asset);
                if (price.size()> 0){
                  price.sort();
                 
                  Decimal highestRate = price.get(price.size() - 1);
                  Decimal lowestRate = price[0];
                  assetPriceWrapper.add(new assetTypePriceRankWrapper(invID, asset, lowestRate, highestRate));
                  
                  assetRanking = true;
                }
            }
        }
       
       //populate wrapper class to get data on page
     
        for (Case csid : caseInvoiceMap.keyset()){
          List<UNITY_Invoice__c> invLst =  caseInvoiceMap.get(csid);
          
          List<invoiceWrapper>invWrp = new List<invoiceWrapper>();
             for (UNITY_Invoice__c inv:invLst){
                 
               List<assetTypePriceRankWrapper> assetPriceWrapperList = new List<assetTypePriceRankWrapper>();
               if ( assetPriceWrapper.size() > 0) { 
                   for (assetTypePriceRankWrapper assetWrapper : assetPriceWrapper) {
                       ID iID = assetWrapper.invoiceID;
                       if ( iID == inv.ID ){
                         assetPriceWrapperList.add(new assetTypePriceRankWrapper(assetWrapper.assetType, assetWrapper.lowestRate, assetWrapper.highestRate));
                       }
                   } 
                   
                    assetRanking = true;
                    
                   invWrp.add(new invoiceWrapper( false,inv, assetPriceWrapperList)); 
               }
               else
               {
                 invWrp.add(new invoiceWrapper( false,inv));
               }
             }
         
          caseInvWrp.add(new pmCaseInvoiciceWrapper (csid, invWrp));
          if (caseInvWrp.size() > 0)
               doRendered = true;
           else
               doNotRendered = true;
          system.debug('>>>   caseInvWrp >>>' + caseInvWrp);
          system.debug('>>>   doRendered >>>' + doRendered);
       }
       
       return caseInvWrp;
   }
   
    public List<pmCaseInvoiciceWrapper>  getPMCasesWithInvoiceData(Map<ID, Case> tempCaseInvMap , String invoiceStatus){
     this.hasError = false;
     this.selected = false;
     this.count = 1;
     this.selectedInvoice = false; 
     this.warningSelectedInvoice = '';
     this.assetRanking = false;
     
      caseInvWrp = new  List<pmCaseInvoiciceWrapper>();  
      List<UNITY_Invoice__c> invList = new List<UNITY_Invoice__c>();
      invList = [SELECT ID, UNITY_Case__c, UNITY_Customer_Service_Contract__c,Name,
                   UNITY_Total_Price_With_Service_Charge__c,UNITY_Final_Price2__c,UNITY_Total_Tax__c,
                   UNITY_Final_Price__c,UNITY_Invoice_Date__c, UNITY_Invoice_Status__c,
                   UNITY_Invoice_Margin__c,UNITY_Invoice_Margin_Amount__c,UNITY_Total_Cost__c,
                   UNITY_Tax_Processed__c,UNITY_Tax_Posted__c, UNITY_Total_Price__c, UNITY_SL_Process_Complete__c,
                   UNITYPM_Number_of_Assets__c,Number_of_Labor_Lines__c,Number_of_Travel_Lines__c,Number_of_Part_Lines__c
                      FROM UNITY_Invoice__c 
                       WHERE UNITY_Invoice_Status__c =:invoiceStatus  AND UNITY_Case__c IN :tempCaseInvMap.keySet() ];
      
       Map <Case, List<UNITY_Invoice__c>> caseInvoiceMap = new Map<Case, List<UNITY_Invoice__c>>();
       Set<ID> invIDs = new Set<ID>();
       
       for (UNITY_Invoice__c inv : invList){
         //map with case + list of invoices 
         Case ct = tempCaseInvMap.get(inv.UNITY_Case__c);
         if (caseInvoiceMap.containsKey(ct)){
             List<UNITY_Invoice__c>invtemp = caseInvoiceMap.get(ct);
             invtemp.add(inv);
             caseInvoiceMap.put(ct, invtemp );
         }
         else{
            caseInvoiceMap.put(ct, new List<UNITY_Invoice__c> { inv }); 
         }
         
         invIDs.add(inv.ID);
       }
     
       //get asset type and total price for ranking
        List<UNITY_Invoice_Line_Item__c> invPMLines = [SELECT UNITY_Asset_Type__c, UNITY_Total_Price__c, UNITYPM_Is_Preventative_Maintenance__c,UNITY_Invoice__r.ID
                                                       FROM UNITY_Invoice_Line_Item__c 
                                                       WHERE   UNITY_Invoice__c IN:invIDs AND UNITYPM_Is_Preventative_Maintenance__c = true];
                                                       
        Map<ID, List<UNITY_Invoice_Line_Item__c>>invLineMap = new Map<ID, List<UNITY_Invoice_Line_Item__c>>(); 
        
        for (UNITY_Invoice_Line_Item__c line : invPMLines){
            
             if (invLineMap.containsKey(line.UNITY_Invoice__r.ID)){
                 List<UNITY_Invoice_Line_Item__c>invLinetemp = invLineMap.get(line.UNITY_Invoice__r.ID);
                 invLinetemp.add(line);
                 invLineMap.put(line.UNITY_Invoice__r.ID, invLinetemp );
             }
             else{
                invLineMap.put(line.UNITY_Invoice__r.ID, new List<UNITY_Invoice_Line_Item__c> { line }); 
             }
        }
        
        system.debug('### invLineMap #### ' + invLineMap.size());
        
        List<assetTypePriceRankWrapper> assetPriceWrapper = new List<assetTypePriceRankWrapper>();
          
        for (ID invID: invLineMap.keyset()){
            
            List<UNITY_Invoice_Line_Item__c> lines = invLineMap.get(invID);
            
             Map<String, List<Decimal>> assetPricemap = new Map<String, List<Decimal>>();   
         
             for (UNITY_Invoice_Line_Item__c line: lines){                                              
                if(assetPricemap.containsKey(line.UNITY_Asset_Type__c)) {
                    assetPricemap.get(line.UNITY_Asset_Type__c).add(line.UNITY_Total_Price__c);
                } else {
                    assetPricemap.put(line.UNITY_Asset_Type__c, new List<Decimal> { line.UNITY_Total_Price__c });
                }
              }
            
            
              for (String asset : assetPricemap.keySet()){
                List<Decimal> price = assetPricemap.get(asset);
                if (price.size()> 0){
                  price.sort();
                 
                  Decimal highestRate = price.get(price.size() - 1);
                  Decimal lowestRate = price[0];
                  assetPriceWrapper.add(new assetTypePriceRankWrapper(invID, asset, lowestRate, highestRate));
                  
                  assetRanking = true;
                }
            }
        }
       
       //populate wrapper class to get data on page
     
        for (Case csid : caseInvoiceMap.keyset()){
          List<UNITY_Invoice__c> invLst =  caseInvoiceMap.get(csid);
          
          List<invoiceWrapper>invWrp = new List<invoiceWrapper>();
             for (UNITY_Invoice__c inv:invLst){
                 
               List<assetTypePriceRankWrapper> assetPriceWrapperList = new List<assetTypePriceRankWrapper>();
               if ( assetPriceWrapper.size() > 0) { 
                   for (assetTypePriceRankWrapper assetWrapper : assetPriceWrapper) {
                       ID iID = assetWrapper.invoiceID;
                       if ( iID == inv.ID ){
                         assetPriceWrapperList.add(new assetTypePriceRankWrapper(assetWrapper.assetType, assetWrapper.lowestRate, assetWrapper.highestRate));
                       }
                   } 
                   
                    assetRanking = true;
                    
                   invWrp.add(new invoiceWrapper( false,inv, assetPriceWrapperList)); 
               }
               else
               {
                 invWrp.add(new invoiceWrapper( false,inv));
               }
             }
         
          caseInvWrp.add(new pmCaseInvoiciceWrapper (csid, invWrp));
          if (caseInvWrp.size() > 0)
               doRendered = true;
          else {
              doNotRendered = true;
          }
          system.debug('>>>   caseInvWrp >>>' + caseInvWrp);
          system.debug('>>>   doRendered >>>' + doRendered);
       }
       
       return caseInvWrp;
   }
   //===============================PageReference==============================================================
   public void doApplyFilter(){
        system.debug('>>> selectedFilterVal >>>' + selectedFilterVal);
        system.debug('>>> selectedFilterForDataVal >>>' + selectedFilterForDataVal);
        this.hasError = false;
        this.selected = false;
        this.count = 1;
        this.selectedInvoice = false; 
        this.warningSelectedInvoice = '';
        this.assetRanking = false;
        this.doRendered = false;
        Boolean invoiceFilter = false;
        
        Map<ID, Case> tempCaseInvMap = new Map<ID, Case>();
         
        if (selectedFilterVal =='Case Status' && !selectedFilterForDataVal.contains('None')){
            tempCaseInvMap = setPMCaseWithStatusCase(selectedFilterForDataVal);
            
        }
         if (selectedFilterVal =='Case Record Type' && !selectedFilterForDataVal.contains('None')){
             tempCaseInvMap = setPMCaseWithRTCase(selectedFilterForDataVal);
        }     
        if (selectedFilterVal =='Case Type' && !selectedFilterForDataVal.contains('None')){
             tempCaseInvMap = setPMCaseWithTypeCase(selectedFilterForDataVal);
        }
        
        if (selectedFilterVal =='Invoice Status' && !selectedFilterForDataVal.contains('None')){
             tempCaseInvMap = setPMCaseWithOutFilter();
             invoiceFilter= true;
        }
        if (selectedFilterVal.contains('None')){
             tempCaseInvMap = setPMCaseWithOutFilter();
         }
        if ( invoiceFilter){
            this.caseInvWrp = getPMCasesWithInvoiceData(tempCaseInvMap, selectedFilterForDataVal);
        }
        else{
           this.caseInvWrp = getPMCasesWithInvoiceData(tempCaseInvMap);
        }
        hasData = true;
   }
   
   //Finalizing Invoices
   public PageReference doFinalize(){
        List<String> invoiceIds = new List<String>();
         
        for (pmCaseInvoiciceWrapper invSelected: caseInvWrp){
            for (invoiceWrapper iw :invSelected.invwrapper){
            system.debug('>>>>iw >>>>' + iw);
            system.debug('>>>>iw >>>>' + iw.invoice.ID);
               
            system.debug('>>>>iw.Selected >>>>' + iw.Selected);
              if (iw.Selected){
                invoiceIds.add(iw.invoice.ID);
              }
           }
        }
        if ( invoiceIds.size()> 0){
            finalizeInvoices (invoiceIds);
            selectedInvoice = true;
        }
        else {
            //message select invoice
            ApexPages.Message errMag = new ApexPages.Message(ApexPages.Severity.WARNING,'Select Invoice to Finalize.');
            ApexPages.addMessage(errMag);
            selectedInvoice = false;
        }
        
       return null;
   }
   private void finalizeInvoices(List<String> invIds){
      List<UNITY_Invoice__c> invoices = [SELECT Id, 
                    Name, 
                    UNITY_Invoice_Status__c
                   FROM UNITY_Invoice__c WHERE Id In: invIds];
                   
      if (invoices.size()> 0){
        List<UNITY_Invoice__c> invUpdate = new List<UNITY_Invoice__c>();
       
         for ( UNITY_Invoice__c invoice : invoices){
            invoice.UNITY_Invoice_Status__c ='Invoice Finalized';
            invUpdate.add(invoice);
         }
       
       try{  
         if ( invUpdate.size() > 0)
            update invUpdate;
       }
       catch (dmlException exDML){
            String errorMessage ='';
            if (exDML.getMessage().contains('have an GL Cost Account set')){
              errorMessage = 'Invoice does not have an GL Cost Account set.'; 
            }
            else if (exDML.getMessage().contains('have an GL Revenue Account set')){
              errorMessage = 'Invoice does not have an GL Revenue Account set.'; 
            }
            else if (exDML.getMessage().contains('have an GL Tax Account set')){
              errorMessage = 'Invoice does not have an GL Tax Account set.'; 
            }
            else {
                errorMessage = exDML.getMessage();
            }
           ApexPages.Message errMag = new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage);
           ApexPages.addMessage(errMag);
         
         }
         catch (Exception ex){
             String errorMessage ='';
             if (ex.getMessage().contains('have an GL Cost Account set')){
              errorMessage = 'Invoice does not have an GL Cost Account set.'; 
            }
            else if (ex.getMessage().contains('have an GL Revenue Account set')){
              errorMessage = 'Invoice does not have an GL Revenue Account set.'; 
            }
            else if (ex.getMessage().contains('have an GL Tax Account set')){
              errorMessage = 'Invoice does not have an GL Tax Account set.'; 
            }
            else {
               errorMessage = ex.getMessage();
            }
           ApexPages.Message errMag = new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage);
           ApexPages.addMessage(errMag);
         
       }
      }
   }
   
   //Do printing
   public PageReference doPrintInvoice(){
      String idInv ='';
      string idParams ='';
    
      PageReference pageRef= new PageReference('/apex/UNITYPM_BulkCustomerPDFInvoices');
      
      for (pmCaseInvoiciceWrapper invSelected: caseInvWrp){
           for (invoiceWrapper iw :invSelected.invwrapper){
              if (iw.Selected){
                  if (idParams == '')
                     idParams = iw.invoice.ID;
                  else
                      idParams = idParams + ',' + iw.invoice.ID;
                   
                   
                   idInv =iw.invoice.ID; 
              }
           }
       }
         
     if ( idParams != '') {
       selectedInvoice = true;
       pageRef.getParameters().put('id', idInv);
       pageRef.getParameters().put('idParams', idParams);
       pageRef.setRedirect(true);        
       return pageRef; 
     }
     else 
     {
         //message select invoice
          ApexPages.Message errMag = new ApexPages.Message(ApexPages.Severity.WARNING,' Select Invoice to Print.');
          ApexPages.addMessage(errMag);
          selectedInvoice = false;
         return null;
     }
   }
   
   //====================================================================================================
   //wrapper classes
   public class pmCaseInvoiciceWrapper{
       public ID cid {get;set;}
       public Case cs {get;set;}
       public List<UNITY_Invoice__c> invoices {get;set;}
       public List<invoiceWrapper> invwrapper {get;set;}
      
       
       public pmCaseInvoiciceWrapper(){
           
       }
       public pmCaseInvoiciceWrapper(ID cid, List<UNITY_Invoice__c> invoices ){
           this.cid = cid;
           this.invoices = invoices;
       }
        public pmCaseInvoiciceWrapper(Case cs, List<UNITY_Invoice__c> invoices ){
           this.cs = cs;
           this.invoices = invoices;
       }
       
       public pmCaseInvoiciceWrapper(Case cs, List<invoiceWrapper> invwrapper ){
           this.cs = cs;
           this.invwrapper = invwrapper;
       }
   }
   
   public class invoiceWrapper{
       public Boolean selected {get; set;}
       public UNITY_Invoice__c invoice {get;set;}
       public List<assetTypePriceRankWrapper> assetPriceWrapper {get;set;}
        
       public invoiceWrapper(){
       }
       
       public invoiceWrapper (Boolean selected, UNITY_Invoice__c invoice){
           this.selected = selected;
           this.invoice = invoice;
        }
        
        public invoiceWrapper (Boolean selected, UNITY_Invoice__c invoice, List<assetTypePriceRankWrapper> assetPriceWrapper){
           this.selected = selected;
           this.invoice = invoice;
           this.assetPriceWrapper = assetPriceWrapper;
        }   
     }

   public class assetTypePriceRankWrapper{
       public String assetType {get;set;}
       Public Decimal lowestRate {get;set;}
       Public Decimal highestRate {get;set;}
       Public ID invoiceID {get;set;}
       
       public assetTypePriceRankWrapper(ID invoiceID, String assetType,Decimal lowestRate, Decimal highestRate){
         this.invoiceID = invoiceID;
         this.assetType = assetType;  
         this.lowestRate = lowestRate;
         this.highestRate = highestRate;
       }
       
        public assetTypePriceRankWrapper( String assetType, Decimal lowestRate, Decimal highestRate){
         this.assetType = assetType;  
         this.lowestRate = lowestRate;
         this.highestRate = highestRate;
       }
       
   }
}