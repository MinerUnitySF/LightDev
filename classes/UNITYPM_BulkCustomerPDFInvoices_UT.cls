@isTest
public class UNITYPM_BulkCustomerPDFInvoices_UT {
    
  	//Setup Product and Pricebook Info
    public static Id PRICEBOOKENTRYID_T;
    public static Id PRICEBOOKENTRYID_L;
    public static Id PRICEBOOKENTRYID_P;
    public static Id PRICEBOOKENTRYID_F;
    public static Id PRODUCTID_T;
    public static Id PRODUCTID_L;
    public static Id PRODUCTID_P;
    public static Id PRODUCTID_F;
    private static String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
    private static String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
    private static String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
	private static String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
    private static String usageRecRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
	private static String purchaseOrdRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        private static String oRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
    private static Account cust;
    private static Account vend;
    private static Account bu;
	private static WorkOrder wo;
    
    static{
        //Create Product & pricebook
        Map<String,String> prodMapP = TestDataProvider.getProductAndPriceBookEntry(1,'Part');
        for(String s :prodMapP.keySet()){
            PRICEBOOKENTRYID_P = (Id)prodMapP.get(s);
            PRODUCTID_P = (Id)s;
        }
        Map<String,String> prodMapL = TestDataProvider.getProductAndPriceBookEntry(1,'Labor');
        for(String s :prodMapL.keySet()){
            PRICEBOOKENTRYID_L = (Id)prodMapL.get(s);
            PRODUCTID_L = (Id)s;
        }
        Map<String,String> prodMapT = TestDataProvider.getProductAndPriceBookEntry(1,'Travel');
        for(String s :prodMapT.keySet()){
            PRICEBOOKENTRYID_T = (Id)prodMapT.get(s);
            PRODUCTID_T = (Id)s;
        }
         Map<String,String> prodMapF = TestDataProvider.getProductAndPriceBookEntry(1,'Freight');
        for(String s :prodMapF.keySet()){
            PRICEBOOKENTRYID_F = (Id)prodMapF.get(s);
            PRODUCTID_F = (Id)s;
        }
    }
  
    @testSetup
    public static void init(){
        TestDataProvider.unityTestSetup();        
    }
     private static testMethod void test3(){
        Account bu;
        List<Account> accounts = [SELECT Id,RecordTypeId,Account_Email__c FROM Account];
        
        for(Account a :accounts){           
            if(a.RecordTypeId == buRTId)
                bu = a;
        }  
       List<Account> accts = new List<Account>();
        Account cust = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];
        cust.Account_Status__c = 'Active';
        cust.UNITY_Customer_Team__c = 'Team 1';
        cust.UNITY_MNS_Customer_Team__c = 'Team 1';
        cust.UNITY_Tier_Level__c = 'Tier 1';
        accts.add(cust);
        
        Account custSite = TestDataProvider.getAccounts(1,'Customer', 'Site/Location')[0];
        custSite.Account_Status__c = 'Active';
        custSite.UNITY_Customer_Team__c = 'Team 1';
        custSite.UNITY_MNS_Customer_Team__c = 'Team 1';
        custSite.UNITY_Tier_Level__c = 'Tier 1';
        accts.add(custSite);
	
        Account buMNS = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];buMNS.UNITY_Business_Unit__c = 'MNS';accts.add(buMNS);
        insert accts;
        
        //create vendor account 
         String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
         
	    Account vendor;
        Account account = [SELECT Id,RecordTypeId,Account_Email__c,UNITYPM_PIN__c,UNITY_Vendor_Type_PM__c FROM Account where RecordTypeId =:vendRTId];
        vendor = account;
        vendor.UNITY_Vendor_Type_PM__c = true;
        vendor.Account_Email__c = 'vendor@fggt.com';
        vendor.UNITYPM_PIN__c = '123';
	    update vendor;
	    
	      //create vendor 2 account 
	    Account vendor2;
        Account account2 = [SELECT Id,RecordTypeId,Account_Email__c,UNITYPM_PIN__c,UNITY_Vendor_Type_PM__c FROM Account where RecordTypeId =:vendRTId];
        vendor2 = account2;
        vendor2.UNITY_Vendor_Type_PM__c = true;
        vendor2.Account_Email__c = 'vendor2@fggt.com';
        vendor2.UNITYPM_PIN__c = '456';
	    update vendor2;
	    
        
        //create service contracts
        List<UNITY_Service_Contract__c> scList = new List<UNITY_Service_Contract__c>();
        
        UNITY_Service_Contract__c testServiceContract1 = new UNITY_Service_Contract__c( UNITY_Account__c = cust.Id, UNITY_Margin__c = 10, 
        							UNITY_Invoicing_Method__c = 'Email', RecordTypeId = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE,  UNITY_IS_Active__c = true,
        							UNITY_Business_Unit__c = 'MNS', UNITYPM_PMO_NTE__c = 500.00);

        scList.add(testServiceContract1);
        
        UNITY_Service_Contract__c testServiceContract2 = new UNITY_Service_Contract__c( UNITY_Account__c = custSite.Id, UNITY_Margin__c = 10, 
        							UNITY_Invoicing_Method__c = 'Email', RecordTypeId = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE,  UNITY_IS_Active__c = true,
        							UNITY_Business_Unit__c = 'MNS', UNITYPM_PMO_NTE__c = 500.00);

        scList.add(testServiceContract2);
       

        UNITY_Service_Contract__c testServiceContract3 = new UNITY_Service_Contract__c( UNITY_Account__c = custSite.Id, UNITY_Margin__c = 10, 
        							UNITY_Invoicing_Method__c = 'Email', RecordTypeId = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE,  UNITY_IS_Active__c = true,
        							UNITY_Business_Unit__c = 'MNS', UNITYPM_PMO_NTE__c = 500.00);
        							
         scList.add(testServiceContract3);

         UNITY_Service_Contract__c testVendorServiceContract = new UNITY_Service_Contract__c( UNITY_Account__c = vendor.Id, 
        						   RecordTypeId = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE,  UNITY_IS_Active__c = true,
        							UNITY_Business_Unit__c = 'MNS', UNITYPM_PMO_NTE__c = 0.00);
     
         scList.add(testVendorServiceContract);
          
         UNITY_Service_Contract__c testVendorServiceContract2 = new UNITY_Service_Contract__c( UNITY_Account__c = vendor2.Id, 
        						   RecordTypeId = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE,  UNITY_IS_Active__c = true,
        							UNITY_Business_Unit__c = 'MNS', UNITYPM_PMO_NTE__c = 0.00);

         scList.add(testVendorServiceContract2);      

        insert scList;	    
	   
	    FSO__Location__c location = new FSO__Location__c(
            FSO__Account__c = bu.Id,
            FSO__Type__c = 'Warehouse',
            UNITY_Business_Unit__c = 'NSBS',
            UNITY_Business_Unit_Account__c = bu.Id,
            FSO__Street__c = '9045 IMPERIAL HWY #2',
            FSO__City__c = 'DOWNEY',
            FSO__State__c = 'CA',
            FSO__Country__c = 'US',
            FSO__Zip__c = '90242-2711',
            FSO__Geolocation__Latitude__s = 33.917342,
            FSO__Geolocation__Longitude__s = 118.1383648
        );
        insert location;
        FSO__LocationStock__c lStock = new FSO__LocationStock__c(
            FSO__Location__c = location.Id,
            FSO__Product__c = PRODUCTID_P,
            FSO__Quantity__c = 10,
            UNITY_MAC__c = 15
        );
        insert lStock;
        
	    
        Case c = new Case();
        c.AccountId = cust.Id;
        c.UNITY_Customer__c = cust.Id;
        c.RecordTypeId = UNITY_Constants.CASE_PROGRAM_CASE_RECORDTYPE;
        c.Status = 'New';
        c.UNITY_Business_Unit__c = 'MNS';
        c.UNITY_Business_Unit_Account__c = buMNS.Id;
        c.UNITY_Skill_Broad__c = 'Glass';
        c.UNITY_Customer_IVR_Pin__c ='12345';
        c.UNITY_Miner_IVR_Phone_Number__c = '9497894562';
		insert c;
        
        Case c2 = new Case();
        c2.AccountId = custSite.Id;
        c2.UNITY_Customer__c = custSite.Id;
        c2.UNITY_Business_Unit__c = 'MNS';
        c2.UNITY_Business_Unit_Account__c = buMNS.Id;
        c2.UNITY_Skill_Broad__c = 'Glass';
        c2.RecordTypeId = UNITY_Constants.CASE_PREVENTATIVE_MAINTENANCE_RECORDTYPE;
        c2.ParentId = c.Id;
        c2.Status = 'New';
       
	    insert c2;
	    
	    c2.UNITY_Customer_IVR_Pin__c ='12345';
        c2.UNITY_Miner_IVR_Phone_Number__c = '9497894562';
        
	    update c2;
	    
	     Case c3 = [SELECT id,UNITY_Customer_IVR_Pin__c, UNITY_Miner_IVR_Phone_Number__c
	              from Case where id =:c2.ID] ;
	    
	      //Create an agent
        User agent = TestDataProvider.getUser('Agent', 'One', 'NMS Technician');
        insert agent;
        
        User agent2 = TestDataProvider.getUser('Agent2', 'One2', 'NMS Technician');
        insert agent2;
         
	    Test.startTest();
	    
	    UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);	  
	     
	    WorkOrder wo = [SELECT Id, UNITY_Business_Unit__c, Status,UNITY_Assigned_Vendor__c,
	                                 UNITY_Customer_IVR_Pin__c,UNITY_Miner_IVR_Phone_Number__c,
	                                      UNITY_Accepted_Vendor__c,UNITY_Vendor_Status__c,UNITY_Work_Description__c,
	                                      UNITY_Work_Window_Begin__c,UNITY_Work_Window_End__c,UNITY_Agent__c,RecordTypeId,
	                                      UNITY_Vendor_Contract__c, UNITY_Vendor_Email__c
	                                    FROM WorkOrder 
	                                    WHERE CaseId = :c2.Id LIMIT 1 ]; 
	    
	     system.debug('>>>  neli  work order >>>> ' + wo);
	    
	    WorkOrder wo1 = [SELECT Id, UNITY_Business_Unit__c, Status,UNITY_Assigned_Vendor__c,
	                                 UNITY_Customer_IVR_Pin__c,UNITY_Miner_IVR_Phone_Number__c,
	                                      UNITY_Accepted_Vendor__c,UNITY_Vendor_Status__c,UNITY_Work_Description__c,
	                                      UNITY_Work_Window_Begin__c,UNITY_Work_Window_End__c,UNITY_Agent__c,RecordTypeId,
	                                      UNITY_Vendor_Contract__c, UNITY_Vendor_Email__c
	                                    FROM WorkOrder WHERE ID =:wo.ID];                  
	       
	    system.assert(c2.RecordTypeId == UNITY_Constants.CASE_PREVENTATIVE_MAINTENANCE_RECORDTYPE); 
    	system.assert(wo != null);
	    system.assert(wo.Status == 'New');
	    system.assert(wo.UNITY_Assigned_Vendor__c == null);
        system.assert(wo.RecordTypeId == UNITY_Constants.wo_PREVENTATIVE_MAINTENANCE_RECORDTYPE); 
        
         vendor.UNITY_Service_Contract__c= testVendorServiceContract.ID;
         vendor2.UNITY_Service_Contract__c= testVendorServiceContract2.ID;
         
          //add wolis
          List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
           WorkOrderLineItem wolich = new WorkOrderLineItem ();
                wolich.WorkOrderId = wo.ID;
                wolich.UNITY_PM_WOLI__c = false;
                wolich.FSO__IsRequired__c = true;
                wolich.RecordTypeId =UNITY_Constants.WOLI_WORK_ORDER_LINE_ITEM_RECORDTYPE; 
                wolich.Description =Datetime.now().format() + ' : Tech Check-In'; 
                wolich.FSO__IsCompleted__c = true;
                 wolich.Status = 'In Progress';
                wolich.SFPS_FS_Task_Type__c = 'Check-In';
                wolis.add(wolich);
         
              wolich = new WorkOrderLineItem ();         
	            wolich.WorkOrderId = wo.ID;
                wolich.UNITY_PM_WOLI__c = false;
                wolich.FSO__IsRequired__c = true;
                wolich.RecordTypeId =UNITY_Constants.WOLI_WORK_ORDER_LINE_ITEM_RECORDTYPE; 
                wolich.Description =Datetime.now().format() + ' : Tech Check-Out';
                wolich.FSO__IsCompleted__c = true;
                wolich.Status = 'In Progress';
                wolich.SFPS_FS_Task_Type__c = 'Check-Out';
                wolis.add(wolich);
         
         insert wolis;     
       
          wolis = new List<WorkOrderLineItem>();
              wolich = new WorkOrderLineItem ();
                wolich.WorkOrderId = wo.ID;
                wolich.UNITY_PM_WOLI__c = false;
                wolich.FSO__IsRequired__c = true;
                wolich.RecordTypeId =UNITY_Constants.WOLI_WORK_ORDER_LINE_ITEM_RECORDTYPE; 
                DateTime dt1 = DateTime.now() + Double.valueOf(10) / 1440;
                wolich.Description =dt1.format() + ' : Tech Check-In'; 
                wolich.FSO__IsCompleted__c = true;
                wolich.Status = 'Completed';
                wolich.SFPS_FS_Task_Type__c = 'Check-In';
                wolis.add(wolich);
        
            wolich = new WorkOrderLineItem ();         
	            wolich.WorkOrderId = wo.ID;
                wolich.UNITY_PM_WOLI__c = false;
                wolich.FSO__IsRequired__c = true;
                wolich.RecordTypeId =UNITY_Constants.WOLI_WORK_ORDER_LINE_ITEM_RECORDTYPE;                
                DateTime dt2 = DateTime.now() + Double.valueOf(20) / 1440;
                wolich.Description =dt2.format() + ' : Tech Check-Out';
                wolich.FSO__IsCompleted__c = true;
                wolich.Status = 'Completed';
                wolich.SFPS_FS_Task_Type__c = 'Check-Out';
                wolis.add(wolich);
           insert wolis;   
       
	     List<WorkOrderLineItem> woliInsertList = [select ID,RecordTypeId,UNITY_PM_WOLI__c from WorkOrderLineItem where WorkOrderId =:wo.ID];
	       
	     system.assert(woliInsertList.size()== 4);
	     
         UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
         
	    //assign vendor
	     wo.UNITY_Assigned_Vendor__c = vendor.Id;
         wo.UNITY_Vendor_Status__c = 'Assigned';  
	     wo.UNITY_Work_Description__c = 'Test Test Test';
	     wo.UNITY_Agent__c = agent.Id;
	     wo.UNITY_Vendor_Email__c = vendor.Account_Email__c;
	     wo.UNITY_Vendor_Contract__c = testVendorServiceContract.ID;
	     wo.UNITY_Vendor_PIN__c =vendor.UNITYPM_PIN__c;
	     
	     update wo;
	     
	     system.assert( wo.UNITY_Assigned_Vendor__c == vendor.Id);
	     system.assert( wo.UNITY_Vendor_Status__c == 'Assigned');
	     system.assert( wo.UNITY_Vendor_Contract__c ==testVendorServiceContract.ID);
	     system.assert( wo.UNITY_Vendor_Email__c ==vendor.Account_Email__c);
	     system.assert( wo.UNITY_Vendor_PIN__c == vendor.UNITYPM_PIN__c); 
	     
	    
	     wo.UNITY_Accepted_Vendor__c = vendor.Id;
	     wo.UNITY_Vendor_Status__c = 'Accepted';
	     wo.UNITY_Work_Window_Begin__c = DateTime.now();
         wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
	     update wo;
	     
	      UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
        
        List<Order> ords = new List<Order>();
        Order o = new Order();
        o.RecordTypeId = oRTId;
        o.AccountId = cust.Id;
        o.UNITY_Vendor__c = wo.UNITY_Accepted_Vendor__c;
        o.Type = 'Usage Request PO';
        o.UNITY_Business_Unit__c = 'NSBS';
        o.UNITY_Business_Unit_Account__c = buMNS.Id;
        o.Status = 'Draft';
        o.FSO__WorkOrder__c = wo.Id;
        o.EffectiveDate = Date.today();
        o.UNITY_NTE__c = 200;       
        ords.add(o);
        insert ords;
        
        List<OrderItem> oLines = new List<Orderitem>();
        OrderItem oItem = new orderItem();
        oItem.OrderId = ords[0].Id;
        oItem.PricebookEntryId = PRICEBOOKENTRYID_T;
        oItem.Quantity = 2;
        oItem.UnitPrice = 10;
        oItem.UNITY_Activity_Type__c = 'Standard Labor';
        oItem.UNITY_Type__c = 'Labor - Service';
        OrderItem oItem2 = new orderItem();
        oItem2.OrderId = ords[0].Id;
        oItem2.PricebookEntryId = PRICEBOOKENTRYID_P;
        oItem2.Quantity = 2;
        oItem2.UnitPrice = 10;
        oItem2.UNITY_Activity_Type__c = 'Parts - Service and Remodel';
        oItem2.UNITY_Type__c = 'Parts';
        oLines.add(oItem);
        oLines.add(oItem2);
        insert oLines;
        
        Order o1 = new Order();
        o1.RecordTypeId = oRTId;
        o1.AccountId = cust.Id;
        o1.UNITY_Vendor__c = wo.UNITY_Accepted_Vendor__c;
        o1.Type = 'Purchase Order';
        o1.UNITY_Business_Unit__c = 'NSBS';
        o1.UNITY_Business_Unit_Account__c = bu.Id;
        o1.Status = 'Draft';
        o1.FSO__WorkOrder__c = wo.Id;
        o1.EffectiveDate = Date.today();
        o1.UNITY_NTE__c = 200;
        ords.add(o1);        
         
         OrderItem oi = new OrderItem(
            UNITY_Type__c = 'Parts',
            UNITY_Activity_Type__c = 'Parts - New Construction',
            PricebookEntryId = PRICEBOOKENTRYID_P,
            OrderId = o.Id,
            Quantity = 5,
            UnitPrice = 10,
            UNITY_Cost__c = 12,
            UNITY_Part_Source__c = bu.Id,
            UNITY_Part_Location__c = location.Id
        );
        insert oi;  
        
        List<OrderItem> oLines2 = new List<Orderitem>();
        OrderItem oItem1 = new orderItem();
        oItem1.OrderId = o.Id;
        oItem1.PricebookEntryId = PRICEBOOKENTRYID_T;
        oItem1.Quantity = 2;
        oItem1.UnitPrice = 10;
        oItem1.UNITY_Activity_Type__c = 'Standard Labor';
        oItem1.UNITY_Type__c = 'Labor - Service';
        OrderItem oItem3 = new orderItem();
        oItem3.OrderId =o.Id;
        oItem3.PricebookEntryId = PRICEBOOKENTRYID_P;
        oItem3.Quantity = 2;
        oItem3.UnitPrice = 10;
        oItem3.UNITY_Activity_Type__c = 'Parts - Service and Remodel';
        oItem3.UNITY_Type__c = 'Parts';
        oLines2.add(oItem1);
        oLines2.add(oItem3);
        insert oLines2;        
        
      
        o.Status = 'Parts Order Required';
        update o;      
        
        o.UNITY_Tracking_Number__c = '111';
        o.UNITY_Shipping_Provider__c = 'FedEx';
        o.UNITY_Shipping_Method__c = 'Ground';
        o.UNITY_Expected_Arrival_Date__c = Date.today() + 3;
        update o;        
       
        oi.UNITY_Actual_Ship_Date__c = Date.today();
        oi.UNITY_Actual_Quantity__c = 10;
        update oi;
         
         o.Status = 'Final';
         update o;
         
         UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
         
	      wo.FSO__Check_In_Date__c = DateTime.now();    
          wo.UNITY_Check_Out_Date_Cust__c = string.valueOf(DateTime.now().addMinutes(60));
	      wo.FSO__Completed_Date__c =DateTime.now().addMinutes(60);
	      wo.UNITY_Vendor_Status__c = 'IVR Check Out - Agent Review Needed';
	      wo.UNITY_Override_Attach_Compliance_Reason__c = 'All PM paperwork received and processed';
	      wo.UNITY_Attachment_Compliant__c = true;
	      update wo;
	     
	     system.assert( wo.UNITY_Override_Attach_Compliance_Reason__c != null);
	      
	     wo.SFPS_FS_AllTasks_Completed__c = 'Complete';
	     wo.UNITY_Next_Step__c = 'Completion Confirmed';
	     update wo;	     
	      
         wo.Status = 'Completed';
         wo.SFPS_FS_OverallStatus__c = 'Completed';
         update wo;      
        
        c2.Status = 'Service Completed';
        update c2;
        
        List<UNITY_Invoice__c> invoices = [SELECT Id, UNITY_Case__c FROM UNITY_Invoice__c where UNITY_Case__c =:c2.Id];
        system.debug ('>>> neli  invoices >>>' + invoices);
        system.assertEquals(1, invoices.size());       
      
        
        List<UNITY_Invoice_Line_Item__c> invoiceLineItems = new List<UNITY_Invoice_Line_Item__c>();
        for(OrderItem oil :oLines2){
            UNITY_Invoice_Line_Item__c ili = new UNITY_Invoice_Line_Item__c();
            ili.UNITY_Invoice__c = invoices[0].Id;
            ili.UNITY_Total_Price__c = 100;
            ili.UNITY_Cost__c = 50;
            ili.UNITY_Sales_Tax__c = null;
            ili.UNITY_PO_Price__c = 100; 
            ili.UNITY_Quantity__c = oil.Quantity;
            ili.UNITY_Adjusted_Quantity__c = oil.Quantity;
            ili.Product__c = PRODUCTID_P;
            ili.UNITY_Tax_Code__c = null;
            ili.UNITY_Is_Vendor_Supply__c = false;
            ili.UNITY_Activity_Type__c = oil.UNITY_Activity_Type__c;
            ili.UNITY_Type__c = oil.UNITY_Type__c;
            invoiceLineItems.add(ili);
        }
        insert invoiceLineItems;
        
        List<UNITY_Invoice_Line_Item__c> ilis = [SELECT Id, UNITY_Invoice__c FROM UNITY_Invoice_Line_Item__c where UNITY_Invoice__c  =:invoices[0].Id];
         system.assertEquals(7, ilis.size());      
      
         List<UNITY_Invoice_Line_Item__c> ilisUpdate  = new  List<UNITY_Invoice_Line_Item__c> ();
        for ( UNITY_Invoice_Line_Item__c invl :ilis){
            invl.UNITYPM_Is_Preventative_Maintenance__c = true;
            ilisUpdate.add(invl);
        }
        update ilisUpdate;
        
        PageReference pr = Page.UNITYPM_BulkCustomerPDFInvoices;
        pr.getParameters().put('id', String.valueOf(invoices[0].Id));
        pr.getParameters().put('idParams', String.valueOf(invoices[0].ID));
        Test.setCurrentPage(pr);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(invoices[0]);
        UNITYPM_BulkCustomerPDFInvoicesCtrl controller = new UNITYPM_BulkCustomerPDFInvoicesCtrl(sc);
        
      
        
	    Test.StopTest();  
   }
}