public class CreateInvoiceandInvoiceDetails {
    public Id woid {get;set;}
    public List<SVMXC__Service_Order_Line__c> wod_list {get;set;}
    public SVMXC__Service_Order_Line__c wo {get;set;}
    public SVMXC__Service_Order__c wox {get;set;}
    public MH_Invoice__c mhi {get;set;}
    public List<WodWrapper> wodw_list {get;set;}
    public List<SVMXC__RMA_Shipment_Order__c> wo_po_list {get;set;}
    
    public Integer lineNumber {get;set;}
    
    
    public CreateInvoiceandInvoiceDetails(){
        
        lineNumber = 0 ;        
        woId = ApexPages.currentPage().getParameters().get('id');
        wo = new SVMXC__Service_Order_Line__c();
        wo.SVMXC__Service_Order__c = woId;
        wo_po_list = [select id,Name,Vendor__c from SVMXC__RMA_Shipment_Order__c where SVMXC__Service_Order__c = :woId];
        //,SVMXC__Group_Member__r.SVMXC__Service_Group__r.Segment__c
        wox = [select id,Name,Location__c,SVMXC__Problem_Description__c ,SVMXC__Contact__c,SVMXC__Company__c,
        SVMXC__Group_Member__r.SVMXC__Service_Group__r.Super_Center__c
        ,SVMXC__Group_Member__r.SVMXC__Service_Group__r.Segment__c
                     from SVMXC__Service_Order__c where id = :woId];
        
        wod_list = [select SVMXC__Line_Type__c,SVMXC__Product__c,SVMXC__Service_Order__c,Parts_Order_Line__c,SVMXC__Line_Status__c,
                            SVMXC__Activity_Type__c,Vendor__c,Vendor__r.Name,Vendor_Status__c,SVMXC__Actual_Quantity2__c,
                            SVMXC__Work_Description__c, SVMXC__Actual_Price2__c,Sales_Tax__c,Total_Line_Price_w_Tax__c, Hide_Line__c 
                            from SVMXC__Service_Order_Line__c 
                            where SVMXC__Service_Order__c = :woId and SVMXC__Line_Status__c='Completed' and Invoice_Detail__c=null ];
        if (wod_list==null){
            wod_list = new List<SVMXC__Service_Order_Line__c>();
        }
        wodw_list = new List<WodWrapper>();
        
        if (wod_list.size()>0)
        for (SVMXC__Service_Order_Line__c wod: wod_list ){
            WodWrapper wodw = new WodWrapper();
            wodw.wod = wod;
            wodw.checked = false;
            wodw.edit = false;
            wodw.lnr = lineNumber+1;
            lineNumber++;
            wodw_list.add(wodw);
        }
        
    }
    public PageReference selectAll(){
        
        
            
            for (WodWrapper ww: wodw_list){
                ww.checked = true;
            }
        
        return null;
    }
    
    public PageReference saveAndClose(){
        quickSave();
        PageReference page;
        if (mhi!=null){
            page = new PageReference('/'+mhi.id);
        }
        else {
            page = new PageReference('/'+woId);
        }
        
        page.setRedirect(true);
        return page;
    }
    
    public PageReference quickSave(){
        
        Boolean createMH;
        createMH = false;
        
        for (WodWrapper ww : wodw_list){
            
            if (ww.checked){
                createMH = true;
                break;
            }
        }
        
        if (createMH){
        
            mhi = new MH_Invoice__c();
            mhi.Account__c = wox.SVMXC__Company__c;
            mhi.Work_Order__c = wox.id;
            
            mhi.Supercenter__c = wox.SVMXC__Group_Member__r.SVMXC__Service_Group__r.Super_Center__c;
            mhi.Segment__c = wox.SVMXC__Group_Member__r.SVMXC__Service_Group__r.Segment__c;
            mhi.Location__c = wox.Location__c;
            mhi.Contact__c = wox.SVMXC__Contact__c;
            mhi.Work_Description__c = wox.SVMXC__Problem_Description__c;
            insert mhi;
        }
        List<MH_Invoice_Details__c> mhid_list = new List<MH_Invoice_Details__c>();
        List<SVMXC__Service_Order_Line__c> wod_toupdate = new List<SVMXC__Service_Order_Line__c>();
        
        for (WodWrapper ww : wodw_list){
            
            if (ww.checked){
                MH_Invoice_Details__c mhid = new MH_Invoice_Details__c();
                mhid.Work_Detail__c = ww.wod.id;
                mhid.Work_Order__c = ww.wod.SVMXC__Service_Order__c;
                mhid.Line_Type__c = ww.wod.SVMXC__Line_Type__c;
                mhid.Activity_Type__c = ww.wod.SVMXC__Activity_Type__c;
                mhid.Part__c = ww.wod.SVMXC__Product__c;
                mhid.Line_Qty__c = ww.wod.SVMXC__Actual_Quantity2__c;
                mhid.Line_Price_Per_Unit__c = ww.wod.SVMXC__Actual_Price2__c;
                //mhid.Sales_Tax__c = ww.wod.Sales_Tax__c;
                mhid.Total_Line_Price__c = ww.wod.Total_Line_Price_w_Tax__c;
                mhid.Hide_Line_c__c = ww.wod.Hide_Line__c;
                mhid.Invoice__c = mhi.id;
                mhid_list.add(mhid);
                wod_toupdate.add(ww.wod);
            }
        }
        
        insert mhid_list;
        
        for (Integer i = 0;i<mhid_list.size();i++){
            wod_toupdate.get(i).Invoice_Detail__c = mhid_list.get(i).id;
        }
        update wod_toupdate;
        /*
        PageReference page = new PageReference('/apex/CreateInvoiceandInvoiceDetails?id='+woId);
        page.setRedirect(true);
        return page;
        */
        if (mhi != null){
		   PageReference pr = Page.CallAvataxInvoice;
		   pr.getParameters().put('iid', mhi.Id);
	       pr.setRedirect(true);
	       return pr;
	    }
	    return null;
    }
    
    public class WodWrapper {
        
        public SVMXC__Service_Order_Line__c wod {get;set;}
        public Integer lnr {get;set;}
        
        public Boolean edit {get;set;}
        public Boolean checked {get;set;}
    }
}