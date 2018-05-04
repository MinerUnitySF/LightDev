@isTest
private class UNITYPM_WorkOrderTriggerHandler_Miner_UT {  
      
    public static Id PRICEBOOKENTRYID_T;
    public static Id PRICEBOOKENTRYID_L;
    public static Id PRICEBOOKENTRYID_P;
    public static Id PRODUCTID;
     private static String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
     private static String oRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
         
    static{
        //Create Product & pricebook
        Map<String,String> prodMapP = TestDataProvider.getProductAndPriceBookEntry(1,'Part');
        for(String s :prodMapP.keySet()){
            PRICEBOOKENTRYID_P = (Id)prodMapP.get(s);
            PRODUCTID = (Id)s;
        }
        Map<String,String> prodMapL = TestDataProvider.getProductAndPriceBookEntry(1,'Labor');
        for(String s :prodMapL.keySet()){
            PRICEBOOKENTRYID_L = (Id)prodMapL.get(s);
        }
        Map<String,String> prodMapT = TestDataProvider.getProductAndPriceBookEntry(1,'Travel');
        for(String s :prodMapT.keySet()){
            PRICEBOOKENTRYID_T = (Id)prodMapT.get(s);
        }
    }
    @testSetup
    public static void init(){
        TestDataProvider.unityTestSetup();
    }    

/*
	private static testMethod void test1() {
      TestDataProvider.unityTestSetup();
        
        Account cust;
        Account vend;
        Account bu;
        
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        
        String progCaseId = UNITY_Constants.CASE_PROGRAM_CASE_RECORDTYPE;
        String pmCaseId = UNITY_Constants.CASE_PREVENTATIVE_MAINTENANCE_RECORDTYPE;
        
        String woPMId = UNITY_Constants.WO_PREVENTATIVE_MAINTENANCE_RECORDTYPE;
        
        String usageRecRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String purchaseOrdRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;

        Test.startTest();
		User admin = TestDataProvider.getUser('Tim', 'System_Admin', 'System Administrator');
        
        //Get the accounts
        List<Account> accounts = [SELECT Id,RecordTypeId,Account_Email__c FROM Account];
        
        for(Account a :accounts){
            if(a.RecordTypeId == custRTId)
                cust = a;
            if(a.RecordTypeId == vendRTId)
                vend = a;
            if(a.RecordTypeId == buRTId)
                bu = a;
        }

		Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Test';
        c.Email='test@test.com';
        c.AccountId = vend.Id;
        insert c;
        
        createPMuser(admin, c, 'test1@dkfjlf.com.d1', 'test1@dkfjlf.com');
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        
	}
  */
   private static testMethod void test2(){
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
	

       // Account buNSBS = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];buNSBS.UNITY_Business_Unit__c = 'NSBS';accts.add(buNSBS);
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
	    
         Case c4 = new Case();
        c4.AccountId = custSite.Id;
        c4.UNITY_Customer__c = custSite.Id;
        c4.UNITY_Business_Unit__c = 'MNS';
        c4.UNITY_Business_Unit_Account__c = buMNS.Id;
        c4.UNITY_Skill_Broad__c = 'Glass';
        c4.RecordTypeId = UNITY_Constants.CASE_PREVENTATIVE_MAINTENANCE_RECORDTYPE;
        c4.ParentId = c.Id;
        c4.Status = 'New';
       
	    insert c4;
       
	    c2.UNITY_Customer_IVR_Pin__c ='12345';
        c2.UNITY_Miner_IVR_Phone_Number__c = '9497894562';
        
	    update c2;
	    
	     Case c3 = [SELECT id,UNITY_Customer_IVR_Pin__c, UNITY_Miner_IVR_Phone_Number__c
	              from Case where id =:c2.ID] ;
	    
	      //Create an agent
        User agent = TestDataProvider.getUser('Agent', 'One', 'NMS Technician');
        insert agent;
        
	    Test.startTest();
	    
	    UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
	    
	    system.debug('>>>  neli  case c >>>> ' + c);
	    system.debug('>>>  neli  case c2 >>>> ' + c2);
	     system.debug('>>>  neli  case c3 >>>> ' + c3);
	     
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
	                                    
	                                    
	      system.debug('>>>  neli  work order1 >>>> ' + wo1);
	      system.debug('>>>  neli  work order1  UNITY_Miner_IVR_Phone_Number__c>>>> ' + wo1.UNITY_Miner_IVR_Phone_Number__c);
	      system.debug('>>>  neli  work order1 UNITY_Customer_IVR_Pin__c >>>> ' + wo1.UNITY_Customer_IVR_Pin__c);
	      system.debug('>>>  neli  work order1 >>>> UNITY_Vendor_Email__c ' + wo1.UNITY_Vendor_Email__c);
	      
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
	     system.debug('>>>> neli woliInsertList  >>>>' + woliInsertList.size());
	     
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
	     
	     //changed vendor:
	     wo.UNITY_Assigned_Vendor__c = vendor2.Id;
         wo.UNITY_Vendor_Status__c = 'Assigned';  
	     wo.UNITY_Work_Description__c = 'Test2 Test2';
	     wo.UNITY_Agent__c = agent.Id;
	     wo.UNITY_Vendor_Email__c = vendor2.Account_Email__c;
	     wo.UNITY_Vendor_Contract__c = testVendorServiceContract2.ID;
	     wo.UNITY_Vendor_PIN__c = vendor2.UNITYPM_PIN__c;
	     
	     update wo;
	    
	      system.assert( wo.UNITY_Assigned_Vendor__c == vendor2.Id);
	      system.assert( wo.UNITY_Vendor_Status__c == 'Assigned');
	      system.assert( wo.UNITY_Vendor_Contract__c == testVendorServiceContract2.ID);
	      system.assert( wo.UNITY_Vendor_PIN__c == vendor2.UNITYPM_PIN__c);
	     
	    UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
       
	     wo.UNITY_Accepted_Vendor__c = vendor2.Id;
	     wo.UNITY_Vendor_Status__c = 'Accepted';
	     wo.UNITY_Work_Window_Begin__c = DateTime.now();
         wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
	     update wo;
	     
	      wo.FSO__Check_In_Date__c = DateTime.now();          
	      wo.FSO__Completed_Date__c =DateTime.now().addMinutes(60);
	      wo.UNITY_Vendor_Status__c = 'IVR Check Out - Agent Review Needed';
	      wo.UNITY_Override_Attach_Compliance_Reason__c = 'All PM paperwork received and processed';
	      wo.UNITY_Attachment_Compliant__c = true;
	      update wo;
	     
	     system.assert( wo.UNITY_Override_Attach_Compliance_Reason__c != null);
	      
	     wo.SFPS_FS_AllTasks_Completed__c = 'Complete';
	     wo.UNITY_Next_Step__c = 'Completion Confirmed';
	     update wo;
	     
         UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
       
          wo.Status = 'Completed';
          wo.SFPS_FS_OverallStatus__c = 'Completed';
          update wo;
          
         system.debug('>>>  neli  wo.UNITY_Override_Attach_Compliance_Reason__c >>>> ' + wo.UNITY_Override_Attach_Compliance_Reason__c);
         system.debug('>>>  neli  wo.Status >>>> ' + wo.Status);
         system.debug('>>>  neli  wo.SFPS_FS_OverallStatus__c >>>> ' + wo.SFPS_FS_OverallStatus__c);
       
          UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
	      wo.SFPS_FS_AllTasks_Completed__c = 'Partially Complete';
	      wo.UNITY_Next_Step__c = 'Requires another trip';
	      update wo;
	      
	     system.assert( wo.SFPS_FS_AllTasks_Completed__c != null);
	     system.assert( wo.UNITY_Next_Step__c != null);
	      
         UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
       
	      wo.SFPS_FS_AllTasks_Completed__c = 'PM Complete';
	      wo.UNITY_Next_Step__c = 'Waiting for checklists';
          wo.UNITY_Work_Description__c = '';
	      update wo;
       
          
          wo.CaseID = c4.ID;
          update wo;
       
         Test.StopTest();    
	    
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
            FSO__Product__c = PRODUCTID,
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
         
         
	    Test.StopTest();
	    
	    
   }
    
    private static testMethod void test4(){
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
	

       // Account buNSBS = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];buNSBS.UNITY_Business_Unit__c = 'NSBS';accts.add(buNSBS);
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
	   
	      //Create an agent
        User agent = TestDataProvider.getUser('Agent', 'One', 'NMS Technician');
        insert agent;
        
	    Test.startTest();
	    
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
	    
         Case c4 = new Case();
        c4.AccountId = custSite.Id;
        c4.UNITY_Customer__c = custSite.Id;
        c4.UNITY_Business_Unit__c = 'MNS';
        c4.UNITY_Business_Unit_Account__c = buMNS.Id;
        c4.UNITY_Skill_Broad__c = 'Glass';
        c4.RecordTypeId = UNITY_Constants.CASE_PREVENTATIVE_MAINTENANCE_RECORDTYPE;
        c4.ParentId = c.Id;
        c4.Status = 'New';
       
	    insert c4;
       
	    c2.UNITY_Customer_IVR_Pin__c ='12345';
        c2.UNITY_Miner_IVR_Phone_Number__c = '9497894562';        
	    update c2;
	    
         c4.UNITY_Customer_IVR_Pin__c ='12345';
        c4.UNITY_Miner_IVR_Phone_Number__c = '9497894562';        
	    update c4;
        
	     Case c3 = [SELECT id,UNITY_Customer_IVR_Pin__c, UNITY_Miner_IVR_Phone_Number__c
	              from Case where id =:c2.ID] ;
	    
         c3.UNITY_Customer_IVR_Pin__c ='12345';
        c3.UNITY_Miner_IVR_Phone_Number__c = '9497894562';        
	    update c3;
        
	    
	    UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
	    
	    WorkOrder wo = [SELECT Id, UNITY_Business_Unit__c, Status,UNITY_Assigned_Vendor__c,
	                                 UNITY_Customer_IVR_Pin__c,UNITY_Miner_IVR_Phone_Number__c,
	                                      UNITY_Accepted_Vendor__c,UNITY_Vendor_Status__c,UNITY_Work_Description__c,
	                                      UNITY_Work_Window_Begin__c,UNITY_Work_Window_End__c,UNITY_Agent__c,RecordTypeId,
	                                      UNITY_Vendor_Contract__c, UNITY_Vendor_Email__c
	                                    FROM WorkOrder 
	                                    WHERE CaseId = :c2.Id LIMIT 1 ]; 
	   
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
	     
	     //changed vendor:
	     wo.UNITY_Assigned_Vendor__c = vendor2.Id;
         wo.UNITY_Vendor_Status__c = 'Assigned';  
	     wo.UNITY_Work_Description__c = 'Test2 Test2';
	     wo.UNITY_Agent__c = agent.Id;
	     wo.UNITY_Vendor_Email__c = vendor2.Account_Email__c;
	     wo.UNITY_Vendor_Contract__c = testVendorServiceContract2.ID;
	     wo.UNITY_Vendor_PIN__c = vendor2.UNITYPM_PIN__c;
	     
	     update wo;
	    
	      system.assert( wo.UNITY_Assigned_Vendor__c == vendor2.Id);
	      system.assert( wo.UNITY_Vendor_Status__c == 'Assigned');
	      system.assert( wo.UNITY_Vendor_Contract__c == testVendorServiceContract2.ID);
	      system.assert( wo.UNITY_Vendor_PIN__c == vendor2.UNITYPM_PIN__c);
	     
	    UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
       
	     wo.UNITY_Accepted_Vendor__c = vendor2.Id;
	     wo.UNITY_Vendor_Status__c = 'Accepted';
	     wo.UNITY_Work_Window_Begin__c = DateTime.now();
         wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
	     update wo;
	     
	      wo.FSO__Check_In_Date__c = DateTime.now();          
	      wo.FSO__Completed_Date__c =DateTime.now().addMinutes(60);
	      wo.UNITY_Vendor_Status__c = 'IVR Check Out - Agent Review Needed';
	      wo.UNITY_Override_Attach_Compliance_Reason__c = 'All PM paperwork received and processed';
	      wo.UNITY_Attachment_Compliant__c = true;
	      update wo;
	     
	     system.assert( wo.UNITY_Override_Attach_Compliance_Reason__c != null);
	      
	     wo.SFPS_FS_AllTasks_Completed__c = 'Complete';
	     wo.UNITY_Next_Step__c = 'Completion Confirmed';
	     update wo;
	     
         UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
       
          wo.Status = 'Completed';
          wo.SFPS_FS_OverallStatus__c = 'Completed';
          update wo;
          
         system.debug('>>>  neli  wo.UNITY_Override_Attach_Compliance_Reason__c >>>> ' + wo.UNITY_Override_Attach_Compliance_Reason__c);
         system.debug('>>>  neli  wo.Status >>>> ' + wo.Status);
         system.debug('>>>  neli  wo.SFPS_FS_OverallStatus__c >>>> ' + wo.SFPS_FS_OverallStatus__c);
       
          UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
	      wo.SFPS_FS_AllTasks_Completed__c = 'Partially Complete';
	      wo.UNITY_Next_Step__c = 'Requires another trip';
	      update wo;
	      
	     system.assert( wo.SFPS_FS_AllTasks_Completed__c != null);
	     system.assert( wo.UNITY_Next_Step__c != null);
	      
         UNITY_Constants.executionsPerTrigger.put('UNITYPM_WorkOrderTriggerHandler_Miner',1);
       
	      wo.Status = 'Canceled';
          wo.UNITY_Cancel_Reason__c = 'Part Not Arrived';
	      update wo;       
       
        
         
        UNITY_WorkOrderLineItemTriggerHandler.isFirstTriggerRun_AfterUpdate = true;        
        UNITY_WorkOrderLineItemTriggerHandler.runTriggerOnce_AfterUpdate();
        UNITY_WorkOrderLineItemTriggerHandler.isFirstTriggerRun_AfterUpdate = false;        
        UNITY_WorkOrderLineItemTriggerHandler.runTriggerOnce_AfterUpdate();
        
        UNITY_WorkOrderLineItemTriggerHandler.isFirstTriggerRun_AfterInsert = true;
        UNITY_WorkOrderLineItemTriggerHandler.runTriggerOnce_AfterInsert();
        UNITY_WorkOrderLineItemTriggerHandler.isFirstTriggerRun_AfterInsert = false;
        UNITY_WorkOrderLineItemTriggerHandler.runTriggerOnce_AfterInsert();
        
        UNITY_WorkOrderLineItemTriggerHandler.isFirstTriggerRun_AfterDelete = true;
        UNITY_WorkOrderLineItemTriggerHandler.runTriggerOnce_AfterDelete();
        UNITY_WorkOrderLineItemTriggerHandler.isFirstTriggerRun_AfterDelete = false;
        UNITY_WorkOrderLineItemTriggerHandler.runTriggerOnce_AfterDelete();
        
         Test.StopTest();    
	    
   }


   private static void createPMuser(User runAsUser, Contact c, String username, String email){        
        
        system.runAs(runAsUser){
            Profile p = [select Id,name from Profile where Name = 'UNITY_PM' limit 1];
            
            User user = new User();
            user.ProfileID = p.id;
            user.EmailEncodingKey = 'ISO-8859-1';
            user.LanguageLocaleKey = 'en_US';
            user.TimeZoneSidKey = 'America/New_York';
            user.LocaleSidKey = 'en_US';
            user.FirstName = 'first';
            user.LastName = 'last';
            user.Username = username;   
            user.Alias = 't1';
            user.Email = email;
            user.IsActive = true;
            user.ContactId = c.Id;
            insert user;
        }
    }
}