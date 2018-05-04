public class BulkEditWorkOrderDetails {

        public Id woId {get;set;}
        public SVMXC__Service_Order_Line__c wo {get;set;}
        public List<SVMXC__Service_Order_Line__c> wod_list {get;set;}
        public List<WorkOrderDetailsWrapper> wodw_list {get;set;}
        public Id rtusagec {get;private set;}
        public Integer slnr {get;set;}
        public Id productId {get;set;}
        public String lineType {get;set;}
        public Integer lineNumber {get;set;}
        public BulkEditWorkOrderDetails(){
                lineNumber = 0 ;                
                woId = ApexPages.currentPage().getParameters().get('id');
                wo = new SVMXC__Service_Order_Line__c();
                wo.SVMXC__Service_Order__c = woId;
                rtusagec = [Select Id From RecordType  Where SobjectType = 'SVMXC__Service_Order_Line__c' and DeveloperName = 'UsageConsumption'].id;
                
                wod_list = [select SVMXC__Line_Type__c,SVMXC__Product__c,SVMXC__Line_Status__c ,SVMXC__Consumed_From_Location__c,Vendor_Cost_Per_Unit__c,
                                                        SVMXC__Actual_Price2__c,Deliver_Date__c,SVMXC__Use_Price_From_Pricebook__c,
                                                        SVMXC__Activity_Type__c,Vendor__c,Vendor_Status__c,SVMXC__Actual_Quantity2__c,
                                                        SVMXC__Work_Description__c from SVMXC__Service_Order_Line__c where SVMXC__Service_Order__c = :woId AND RecordTypeId =: rtusagec];
                wodw_list = new List<WorkOrderDetailsWrapper>();
                
                for (SVMXC__Service_Order_Line__c wod: wod_list ){
                        WorkOrderDetailsWrapper wodw = new WorkOrderDetailsWrapper();
                        wodw.wod = wod;
                        wodw.edit = false;
                        if (wod.SVMXC__Line_Type__c == 'Parts' || wod.SVMXC__Line_Type__c == 'Vendor Services') {
                                wodw.showPart = true;
                        }
                        else {
                                wodw.showPart = false;
                        }
                        wodw.lnr = lineNumber+1;
                        lineNumber++;
                        wodw_list.add(wodw);
                        
                }
                
                System.debug('wodw list size -->' +wodw_list.size());
        }
        public void add10MoreLines(){
                for (Integer i=0;i<10;i++){
                        WorkOrderDetailsWrapper wodw = new WorkOrderDetailsWrapper();
                        SVMXC__Service_Order_Line__c wod = new SVMXC__Service_Order_Line__c();
                        wod.RecordTypeId = rtusagec;
                        wod.SVMXC__Service_Order__c = woId;
                        wod.SVMXC__Use_Price_From_Pricebook__c = true;
                        wodw.wod = wod;
                        wodw.edit = false;
                        wodw.lnr = lineNumber+1;
                        lineNumber++;
                        wodw_list.add(wodw);
                }
        }
        public void emptyMethod(){
                
                for (WorkOrderDetailsWrapper wodw :wodw_list){
                        
                        if (wodw.lnr==slnr && wodw.wod.SVMXC__Product__c != null) {
                                Product2 p2 =[select id, SVMXC__Product_Cost__c, Description from Product2 where id =:wodw.wod.SVMXC__Product__c limit 1];
                                System.debug('actual price -->'+p2.SVMXC__Product_Cost__c);
                                wodw.wod.Vendor_Cost_Per_Unit__c = p2.SVMXC__Product_Cost__c;
                                if ((wodw.wod.SVMXC__Work_Description__c == null) || (wodw.wod.SVMXC__Work_Description__c == ''))
                                	wodw.wod.SVMXC__Work_Description__c = p2.Description;
                                
                                PriceBook2 pb2 = [select id from PriceBook2 where isStandard = true and isActive = true];
                                PriceBookEntry pbe;
                                List<PriceBookEntry> pbe_list;
                                if (pb2!=null )
                                        
                                        pbe_list = [select UnitPrice from PriceBookEntry where Product2Id = :p2.id and Pricebook2Id = :pb2.id];
                                        if (pbe_list.size()>0) pbe = pbe_list[0];
                                if (pbe!=null && pbe.UnitPrice!=null){
                                        System.debug('unit price -->'+pbe.UnitPrice);
                                        wodw.wod.SVMXC__Actual_Price2__c = pbe.UnitPrice;
                                }
                                break;
                        }
                }
        }
        public void togglePart(){
                System.debug('line type -->'+lineType);
                System.debug('selected Id -->' +slnr);
                for (WorkOrderDetailsWrapper wodw :wodw_list){
                        
                        if (wodw.lnr==slnr){
                                if (wodw.wod.SVMXC__Line_Type__c!=null){
                                        wodw.wod.SVMXC__Line_Status__c = 'Open';
                                }
                                if (wodw.wod.SVMXC__Line_Type__c == 'Parts' || wodw.wod.SVMXC__Line_Type__c =='Vendor Services'){
                                        wodw.showPart = true;
                                        
                                        System.debug('selected --> true');
                                }
                                else {
                                        wodw.showPart = false;
                                        System.debug('selected --> false');
                                }
                                
                        }
                
                }
                
        }
        public PageReference saveAndClose(){
                
                quickSave();
                PageReference page = new PageReference('/'+woId);
                page.setRedirect(true);
                return page;
        }
        
        public void quickSave(){
                
                List<SVMXC__Service_Order_Line__c> tosavewods = new List<SVMXC__Service_Order_Line__c>();
                for (WorkOrderDetailsWrapper wodw :wodw_list){
                        
                        if (wodw.wod.SVMXC__Line_Type__c!=null ||
                                wodw.wod.SVMXC__Product__c!=null ||
                                wodw.wod.SVMXC__Activity_Type__c!=null ||
                                wodw.wod.Vendor__c!=null ||
                                wodw.wod.Vendor_Status__c!=null ||
                                wodw.wod.SVMXC__Actual_Quantity2__c!=null ||
                                wodw.wod.SVMXC__Work_Description__c!=null ||
                                
                                wodw.wod.Vendor_Cost_Per_Unit__c!=null ||
                                wodw.wod.SVMXC__Actual_Price2__c!=null ||
                                wodw.wod.Deliver_Date__c!=null 
                                
                                ) {
                                        wodw.wod.SVMXC__Use_Price_From_Pricebook__c = false;
                                        tosavewods.add(wodw.wod);
                                
                                }
                                
                }
                
                upsert tosavewods;
        }
        
        
        public class WorkOrderDetailsWrapper{
                
                public Integer lnr {get;set;}
                public SVMXC__Service_Order_Line__c wod {get;set;}
                public Boolean edit {get;set;}
                public Boolean showPart {get;set;}
        }
}