public class CreatePOandPOLfromWDetails {
    
    public Id woid {get;set;}
    public List<SVMXC__Service_Order_Line__c> wod_list {get;set;}
    public SVMXC__Service_Order_Line__c wo {get;set;}
    public SVMXC__Service_Order__c wox {get;set;}
    public List<WodWrapper> wodw_list {get;set;}
    public List<SVMXC__RMA_Shipment_Order__c> wo_po_list {get;set;}
    public Id miner {get;set;}
    public Id shipment {get;set;}
    public Product2 vendor_labor {get;set;}
    public List<List<WodWrapper>> wodwgroupedbyvendor {get;set;}
    
    public Integer lineNumber {get;set;}
    
    
    public CreatePOandPOLfromWDetails(){
        vendor_labor = [SELECT id,Name FROM Product2 WHERE Name = 'Vendor Labor' limit 1];
        lineNumber = 0 ;        
        woId = ApexPages.currentPage().getParameters().get('id');
        wo = new SVMXC__Service_Order_Line__c();
        wo.SVMXC__Service_Order__c = woId;
        wo_po_list = [SELECT id,Name,Vendor__c FROM SVMXC__RMA_Shipment_Order__c WHERE SVMXC__Service_Order__c = :woId];
        miner = [SELECT Id FROM RecordType  WHERE SobjectType = 'SVMXC__RMA_Shipment_Order__c' AND DeveloperName = 'Miner'].id;
        shipment = [SELECT Id From RecordType  WHERE SobjectType = 'SVMXC__RMA_Shipment_Line__c' AND DeveloperName = 'Shipment'].id;
        wox = [SELECT id,Name,SVMXC__Company__c FROM SVMXC__Service_Order__c WHERE id = :woId];
        
        wod_list = [SELECT SVMXC__Line_Type__c,SVMXC__Line_Status__c,SVMXC__Product__c,SVMXC__Product__r.SVMXC__Product_Cost__c,SVMXC__Service_Order__c,Parts_Order_Line__c,Vendor_Cost_Per_Unit__c,
                    SVMXC__Activity_Type__c,Vendor__c,Vendor__r.Name,Vendor_Status__c,SVMXC__Actual_Quantity2__c, SVMXC__Product__r.Description,
                    SVMXC__Work_Description__c 
                    FROM SVMXC__Service_Order_Line__c 
                    WHERE SVMXC__Service_Order__c = :woId 
                    AND Vendor__c != null AND Parts_Order_Line__c = null 
                    AND SVMXC__Line_Type__c = 'Vendor Services' 
                    AND SVMXC__Line_Status__c != 'Canceled' 
                    AND SVMXC__Line_Status__c != 'Completed' ORDER BY Vendor__c];
        if (wod_list==null){
            wod_list = new List<SVMXC__Service_Order_Line__c>();
        }
        wodw_list = new List<WodWrapper>();
        
        if (wod_list.size()>0)
        for (SVMXC__Service_Order_Line__c wod: wod_list ){
            WodWrapper wodw = new WodWrapper();
            if (wod.SVMXC__Work_Description__c == null || wod.SVMXC__Work_Description__c == '')
                wod.SVMXC__Work_Description__c = wod.SVMXC__Product__r.Description;
            wodw.wod = wod;
            wodw.lin = new SVMXC__RMA_Shipment_Line__c();
            wodw.edit = false;
            wodw.checked = false;
            wodw.lnr = lineNumber+1;
            lineNumber++;
            wodw_list.add(wodw);
        }
        String vendorId;
        String vendorName;
        if (wod_list.size()>0) {
            vendorName = wod_list[0].Vendor__r.Name;
            vendorId = wod_list[0].Vendor__c;
        }
        wodwgroupedbyvendor = new List<List<WodWrapper>>();
        List<WodWrapper> ww_list = new List<WodWrapper>();
        if (wodw_list.size()>0)
        for(WodWrapper ww : wodw_list){
            if (ww.wod.Vendor__c == vendorId){
                ww_list.add(ww);
            }
            else {
                wodwgroupedbyvendor.add(ww_list);
                ww_list = new List<WodWrapper>();
                vendorName = ww.wod.Vendor__r.Name;
                vendorId = ww.wod.Vendor__c;
                ww_list.add(ww);
            }
        }
        if (ww_list.size()>0) wodwgroupedbyvendor.add(ww_list);
        
    }
    public PageReference saveAndClose(){
        quickSave();
        PageReference page = new PageReference('/'+woId);
        page.setRedirect(true);
        return page;
    }
    
    public PageReference quickSave(){
        Boolean createPO;
        createPO = false;
        SVMXC__Service_Order_Line__c wod;
        List<SVMXC__RMA_Shipment_Order__c> po_list = new List<SVMXC__RMA_Shipment_Order__c>();
        for (List<WodWrapper> ww_list :wodwgroupedbyvendor){
            wod = ww_list[0].wod;
            createPO = false;
            
            for (WodWrapper ww : ww_list){
                if (ww.checked) createPO = true;
            } 
            //for (SVMXC__RMA_Shipment_Order__c po: wo_po_list){
            //  if (wod.Vendor__c == po.Vendor__c) createPO = false;
            //}
            if (createPO)   {
                SVMXC__RMA_Shipment_Order__c po = new SVMXC__RMA_Shipment_Order__c();
                po.SVMXC__Service_Order__c = wox.id;
                po.Buyer__c = UserInfo.getUserId();
                po.SVMXC__Order_Status__c = 'Open';
                po.SVMXC__Company__c = wox.SVMXC__Company__c ;
                po.Vendor__c = wod.Vendor__c;
                po.SVMXC__Order_Type__c = 'Drop Ship';
                po.RecordTypeId = miner;
                po_list.add(po);
            }
            
            
        }
        
        insert po_list;
        List<SVMXC__RMA_Shipment_Line__c> pol_list = new List<SVMXC__RMA_Shipment_Line__c>();
        List<SVMXC__Service_Order_Line__c> wods_toupdate = new List<SVMXC__Service_Order_Line__c>();
        for (List<WodWrapper> ww_list:wodwgroupedbyvendor){
            
            for (WodWrapper ww: ww_list){
                if(ww.checked){
                    SVMXC__RMA_Shipment_Line__c pol = new SVMXC__RMA_Shipment_Line__c();
                    pol.SVMXC__Service_Order__c = ww.wod.SVMXC__Service_Order__c;
                    pol.SVMXC__Expected_Quantity2__c = ww.wod.SVMXC__Actual_Quantity2__c;
                    pol.Standard_Cost__c = ww.wod.SVMXC__Product__r.SVMXC__Product_Cost__c;
                    pol.Vendor_Price__c = ww.wod.Vendor_Cost_Per_Unit__c;
                    pol.Product_Cross_Reference__c = ww.lin.Product_Cross_Reference__c;
                    pol.SVMXC__Service_Order_Line__c = ww.wod.id;
                    pol.WOL_Attach__c = true;
                    wods_toupdate.add(ww.wod);
                    if (ww.wod.SVMXC__Activity_Type__c!='Labor'){
                        pol.SVMXC__Product__c = ww.wod.SVMXC__Product__c;
                    }
                    else {
                        pol.SVMXC__Product__c = vendor_labor.id;
                    }
                    /*
                    if (ww.wod.SVMXC__Line_Type__c == 'Vendor Services')
                        pol.SVMXC__Line_Type__c = 'Vendor Services';
                    */
                    pol.SVMXC__Line_Type__c = ww.wod.SVMXC__Line_Type__c;
                    pol.SVMXC__Line_Status__c = 'Open';
                    pol.RecordTypeId = shipment;
                    
                    //for (SVMXC__RMA_Shipment_Order__c po: po_list){
                    //  if (ww.wod.Vendor__c == po.Vendor__c) {
                    //      pol.SVMXC__RMA_Shipment_Order__c = po.id;
                    //      break;
                    //  }
                    //}
                    if (pol.SVMXC__RMA_Shipment_Order__c== null)
                    for (SVMXC__RMA_Shipment_Order__c po: po_list){
                        if (ww.wod.Vendor__c == po.Vendor__c) {
                            pol.SVMXC__RMA_Shipment_Order__c = po.id;
                            break;
                        }
                    }
                    
                    pol_list.add(pol);
                    
                }
            }
        
        
        }
        
        insert pol_list;
        for (Integer i=0;i<pol_list.size();i++){
            
            wods_toupdate[i].Parts_Order_Line__c = pol_list[i].id;
            
        }
        update wods_toupdate;
        PageReference page = new PageReference('/apex/CreatePOandPOLfromWDetails?id='+woId);
        
        page.setRedirect(true);
        return page;
    }
    
    public PageReference selectAll(){
        
        for (List<WodWrapper> ww_list:wodwgroupedbyvendor){
            
            for (WodWrapper ww: ww_list) { 
                ww.checked = true;
            }
        }
        return null;
    }
    
    public class WodWrapper {
        
        public SVMXC__RMA_Shipment_Line__c lin {get;set;}
        public SVMXC__Service_Order_Line__c wod {get;set;}
        public Integer lnr {get;set;}
        public Boolean edit {get;set;}
        public Boolean checked {get;set;}
    }
    
    public Id selectedWodId { get; set; }
    
    public void SetProductDescription() {
        for (WodWrapper wod : wodw_list) {
            if (wod.wod.Id == selectedWodId) {
                if (wod.wod.SVMXC__Product__c != null) {
                    if (wod.wod.SVMXC__Work_Description__c == null || wod.wod.SVMXC__Work_Description__c == '') {
                        wod.wod.SVMXC__Work_Description__c = [SELECT Description FROM Product2 WHERE Id = :wod.wod.SVMXC__Product__c LIMIT 1].Description;
                    }
                }
            }
        }
    }
    
    public void SetProduct() {
        for (WodWrapper wod : wodw_list) {
            if (wod.wod.Id == selectedWodId) {
                wod.wod.SVMXC__Product__c = null;
                if (wod.lin.Product_Cross_Reference__c != null) {
                    wod.wod.SVMXC__Product__c = [SELECT Product__c FROM Product_Cross_Reference__c WHERE Id = :wod.lin.Product_Cross_Reference__c LIMIT 1].Product__c;
                }
            }
        }
        SetProductDescription();
    }
}