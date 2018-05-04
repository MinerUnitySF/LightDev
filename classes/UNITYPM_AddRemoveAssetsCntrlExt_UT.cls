@isTest
public class UNITYPM_AddRemoveAssetsCntrlExt_UT {
    public static Id PRICEBOOKENTRYID_T;
    public static Id PRICEBOOKENTRYID_L;
    public static Id PRICEBOOKENTRYID_P;
    public static Id PRODUCTID;
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
    //Setup test data
    @testSetup
    public static void init(){
        TestDataProvider.unityTestSetup();
    }

    public static TestMethod void test1(){
        //Get the accounts
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String urRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String poRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        List<Account> accounts = [SELECT Id,RecordTypeId,Account_Email__c FROM Account];
        Account cust;
        Account vend;
        Account bu;
        for(Account a :accounts){
            if(a.RecordTypeId == custRTId)
                cust = a;
            if(a.RecordTypeId == vendRTId)
                vend = a;
            if(a.RecordTypeId == buRTId)
                bu = a;
        }
         
        test.startTest();   
      
         
        //Get the case
        Case c = [SELECT Id FROM Case LIMIT 1];
        
        WorkOrder wo = new WorkOrder();
        wo.AccountId = cust.Id;
        wo.UNITY_Accepted_Vendor__c = vend.Id;
        wo.UNITY_Business_Unit_Account__c = bu.Id;
        wo.UNITY_Business_Unit__c = 'NSBS';
        wo.UNITY_Customer__c = cust.Id;
        wo.UNITY_Skill_Broad__c = 'Glass';
        wo.UNITY_Skill_Group__c = 'Glass Installation/Repair';
        wo.UNITY_Skill_Type__c = 'Glass, Board up, Mirrors & Displays';
        wo.Priority = '24 Hour Response';
        wo.Status = 'New';
        wo.RecordTypeId = woRTId;
        wo.CaseId = c.Id;
        insert wo;
        
        wo.UNITY_Assigned_Vendor__c = vend.Id;      
        wo.Subject='Test';
        wo.UNITY_Work_Window_Begin__c = Datetime.now();  
        wo.UNITY_Vendor_Status__c = 'Accepted';         
         update wo;
        
        wo= [SELECT ID,Account.ID, WorkOrderNumber, UNITY_Vendor_Status__c, UNITY_Assigned_Vendor__c
                               FROM WorkOrder
                                    WHERE id =: wo.ID];
        
        List<Asset> assets = new List <Asset>();
	    
	    Asset asset1 = new Asset(Name = 'Test1', Description ='Test1 asset1', AccountId = cust.Id, UNITY_Asset_Type__c= 'Dock');
        assets.add(asset1);
        Asset asset2 = new Asset(Name = 'Test2',  Description ='Test2 asset2',  AccountId = cust.Id, UNITY_Asset_Type__c ='Dock');
        assets.add(asset2);
        Asset asset3 = new Asset(Name = 'Test3',  Description ='Test3 asset3',  AccountId = cust.Id, UNITY_Asset_Type__c = 'Forklift');
        assets.add(asset3);        
        Asset asset4 = new Asset(Name = 'Test asset4',  Description ='Test asset4',  AccountId = cust.Id, UNITY_Asset_Type__c = 'Forklift');
        assets.add(asset4);
        
         insert assets;
         assets = [select id, name , Description, AccountId, UNITY_Asset_Type__c from asset];      
       
        
         List<FSO__WorkPlan__c> workPlanList = new List<FSO__WorkPlan__c>();
         FSO__WorkPlan__c wp1 = new FSO__WorkPlan__c(Name ='wp1', UNITY_Asset_Type__c ='Dock', UNITY_Group_Assets__c = true);
	     workPlanList.add(wp1);
	    
	     FSO__WorkPlan__c wp2 = new FSO__WorkPlan__c(Name ='wp2', UNITY_Asset_Type__c ='Forklift', UNITY_Group_Assets__c = false);
	     workPlanList.add(wp2);  
          insert workPlanList;
        
         List <FSO__WorkPlanItem__c> wpil = new List<FSO__WorkPlanItem__c>();
	    FSO__WorkPlanItem__c  wpi1 = new FSO__WorkPlanItem__c (Name = 'wpi1', FSO__Description__c ='wpi1', UNITY_Render_Type__c='Yes/No', FSO__WorkPlan__c = wp1.ID);
	    wpil.add(wpi1);
	     
	    FSO__WorkPlanItem__c  wpi2 = new FSO__WorkPlanItem__c (Name = 'wp2', FSO__Description__c ='wp2', UNITY_Render_Type__c='Yes/No', FSO__WorkPlan__c = wp2.ID);
	    wpil.add(wpi2);
	      insert wpil;
        
        List<UNITYPM_Work_Order_Assets_junction__c> wolis = new List<UNITYPM_Work_Order_Assets_junction__c>();
         for (Asset a :assets){
            UNITYPM_Work_Order_Assets_junction__c woli = new UNITYPM_Work_Order_Assets_junction__c ();
            if (a.UNITY_Asset_Type__c == 'Dock' ){
	            woli.Work_Order__c = wo.ID;
	            woli.Asset__c = a.ID;
	            woli.Work_Plan__c = wp1.ID;
	          
                wolis.add(woli);
	         }              
         }
        insert wolis;
        
                
        PageReference pr = Page.UNITYPM_AddRemoveAssetsPage;
    	pr.getParameters().put('id',  String.valueOf(wo.Id));
        Test.setCurrentPage(pr);
         
        ApexPages.StandardController sc = new ApexPages.StandardController(wo);
        UNITYPM_AddRemoveWOAssetsCntrlExt controller = new UNITYPM_AddRemoveWOAssetsCntrlExt(sc);
        
        List<UNITYPM_WorkPlanAssetsWrapper> wrpList = controller.getExistingwOLIs();
        system.debug('>>> nelie wrpList >>>>' + wrpList.size());
        
        List<UNITYPM_WorkPlanAssetsWrapper> wrpDisplayList = controller.getRecordsToDisplay();
       // system.assert( wrpDisplayList.size() > 0);
         system.debug('>>> nelie wrpDisplayList >>>>' + wrpDisplayList.size());
        
        List<SelectOption> numList = controller.getNumbersList();
       // system.assert( numList.size() > 0);
        system.debug('>>> nelie numList >>>>' + numList.size());
        
        List<SelectOption> assetsList = controller.getDefaultAssetsList();       
        //system.assert( assetsList.size() > 0);
        system.debug('>>> nelie assetsList >>>>' + assetsList.size());
        
        controller.accountID = cust.Id;
        controller.workOrderNumber = wo.WorkOrderNumber;
        controller.selectedAssetVal = 'Dock';
        controller.selectedNumVal = '5';
        
        controller.addDefaultAssets();
        
        asset asl = [select id, name , Description, AccountId, UNITY_Asset_Type__c from asset where UNITY_Asset_Type__c ='Dock' limit 1];
        FSO__WorkPlan__c wp = [select id, UNITY_Asset_Type__c from FSO__WorkPlan__c where UNITY_Asset_Type__c ='Dock'];
        
        List<String> selectedAssets = new List<String> ();
        String s = '{aId =' + asl.ID + ',wpId =' + wp.ID + ',aselected =1}';
        selectedAssets.add(s);
        UNITYPM_AddRemoveWOAssetsCntrlExt.handleAssetsSubmit(selectedAssets, wo.ID);
        
        
        test.stoptest();
    }    
   
    public static TestMethod void test2(){        
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
        
		Account custSite2 = TestDataProvider.getAccounts(1,'Customer', 'Site/Location')[0];
        custSite2.Account_Status__c = 'Active';
        custSite2.UNITY_Customer_Team__c = 'Team 1';
        custSite2.UNITY_MNS_Customer_Team__c = 'Team 1';
        custSite2.UNITY_Tier_Level__c = 'Tier 1';
        accts.add(custSite2);
       
        
        Test.startTest();
        //Account buNSBS = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];buNSBS.UNITY_Business_Unit__c = 'NSBS';accts.add(buNSBS);
        Account buMNS = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];buMNS.UNITY_Business_Unit__c = 'MNS';accts.add(buMNS);
        
        insert accts;
          
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
         
	    Account vend;
        Account account = [SELECT Id,RecordTypeId,Account_Email__c,UNITYPM_PIN__c,UNITY_Vendor_Type_PM__c FROM Account where RecordTypeId =:vendRTId];
        vend = account;
        vend.UNITY_Vendor_Type_PM__c = true;
        vend.Account_Email__c = 'vendor@fggt.com';
        vend.UNITYPM_PIN__c = '123';
	    update vend;
         
         List<UNITY_Service_Contract__c> scList = new List<UNITY_Service_Contract__c>();
          
         UNITY_Service_Contract__c testVendorServiceContract = new UNITY_Service_Contract__c( UNITY_Account__c = vend.Id, 
        						   RecordTypeId = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE,  UNITY_IS_Active__c = true,
        							UNITY_Business_Unit__c = 'MNS', UNITYPM_PMO_NTE__c = 0.00);
        
        scList.add(testVendorServiceContract);
        
        UNITY_Service_Contract__c testServiceContract1 = new UNITY_Service_Contract__c( UNITY_Account__c = cust.Id, UNITY_Margin__c = 10, 
        							UNITY_Invoicing_Method__c = 'Email', RecordTypeId = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE,  UNITY_IS_Active__c = true,
        							UNITY_Business_Unit__c = 'MNS', UNITYPM_PMO_NTE__c = 500.00);

        scList.add(testServiceContract1);
        
        UNITY_Service_Contract__c testServiceContract2 = new UNITY_Service_Contract__c( UNITY_Account__c = custSite.Id, UNITY_Margin__c = 10, 
        							UNITY_Invoicing_Method__c = 'Email', RecordTypeId = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE,  UNITY_IS_Active__c = true,
        							UNITY_Business_Unit__c = 'MNS', UNITYPM_PMO_NTE__c = 500.00);

        scList.add(testServiceContract2);
        
        UNITY_Service_Contract__c testServiceContract3 = new UNITY_Service_Contract__c( UNITY_Account__c = custSite2.Id, UNITY_Margin__c = 10, 
        							UNITY_Invoicing_Method__c = 'Email', RecordTypeId = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE,  UNITY_IS_Active__c = true,
        							UNITY_Business_Unit__c = 'MNS', UNITYPM_PMO_NTE__c = 500.00);

        scList.add(testServiceContract3);

        UNITY_Service_Contract__c testServiceContract4 = new UNITY_Service_Contract__c( UNITY_Account__c = custSite.Id, UNITY_Margin__c = 10, 
        							UNITY_Invoicing_Method__c = 'Email', RecordTypeId = UNITY_Constants.SC_PREVENTATIVE_MAINTENANCE_RECORDTYPE,  UNITY_IS_Active__c = true,
        							UNITY_Business_Unit__c = 'MNS', UNITYPM_PMO_NTE__c = 500.00);

        scList.add(testServiceContract4);        

        insert scList;
                
        Case c = new Case();
        c.AccountId = cust.Id;
        c.UNITY_Customer__c = cust.Id;
        c.RecordTypeId = UNITY_Constants.CASE_PROGRAM_CASE_RECORDTYPE;
        c.Status = 'New';
        c.UNITY_Business_Unit__c = 'MNS';
        c.UNITY_Business_Unit_Account__c = buMNS.Id;
        c.UNITY_Skill_Broad__c = 'Glass';
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
    
    
    	WorkOrder wo = [SELECT Id, UNITY_Business_Unit__c FROM WorkOrder WHERE CaseId = :c2.Id LIMIT 1];
    	system.assert(wo != null);

		
		system.assert(c2.RecordTypeId == UNITY_Constants.CASE_PREVENTATIVE_MAINTENANCE_RECORDTYPE);    	

		UNITY_Constants.executionsPerTrigger.put('UNITYPM_CaseTriggerHandler_Miner',1);	
    	c2.AccountId = custSite2.Id;
    	update c2;


    	wo = [SELECT Id, UNITY_Customer__c,UNITY_Accepted_Vendor__c,UNITY_Business_Unit_Account__c,UNITY_Business_Unit__c,
              UNITY_Skill_Broad__c,UNITY_Skill_Group__c,UNITY_Skill_Type__c,Priority,Status
                                         FROM WorkOrder WHERE CaseId = :c2.Id LIMIT 1];    	
		system.assert(wo.UNITY_Customer__c == custSite2.Id); 

        
        wo.UNITY_Accepted_Vendor__c = vend.Id;
       // wo.UNITY_Business_Unit_Account__c = bu.Id;
        //wo.UNITY_Business_Unit__c = 'NSBS';        
       // wo.UNITY_Skill_Broad__c = 'Glass';
       // wo.UNITY_Skill_Group__c = 'Glass Installation/Repair';
       //wo.UNITY_Skill_Type__c = 'Glass, Board up, Mirrors & Displays';
        wo.Priority = '24 Hour Response';      
        update wo;
        
        wo.UNITY_Assigned_Vendor__c = vend.Id;      
        wo.Subject='Test';
        wo.UNITY_Work_Window_Begin__c = Datetime.now();  
        wo.UNITY_Vendor_Status__c = 'Accepted';         
         update wo;
        
        wo= [SELECT ID,Account.ID, WorkOrderNumber, UNITY_Vendor_Status__c, UNITY_Assigned_Vendor__c
                               FROM WorkOrder
                                    WHERE id =: wo.ID];
        
        List<Asset> assets = new List <Asset>();
	    
	    Asset asset1 = new Asset(Name = 'Test1', Description ='Test1 asset1', AccountId = cust.Id, UNITY_Asset_Type__c= 'Dock');
        assets.add(asset1);
        Asset asset2 = new Asset(Name = 'Test2',  Description ='Test2 asset2',  AccountId = cust.Id, UNITY_Asset_Type__c ='Dock');
        assets.add(asset2);
        Asset asset3 = new Asset(Name = 'Test3',  Description ='Test3 asset3',  AccountId = cust.Id, UNITY_Asset_Type__c = 'Forklift');
        assets.add(asset3);        
        Asset asset4 = new Asset(Name = 'Test asset4',  Description ='Test asset4',  AccountId = cust.Id, UNITY_Asset_Type__c = 'Forklift');
        assets.add(asset4);
        
         insert assets;
         assets = [select id, name , Description, AccountId, UNITY_Asset_Type__c from asset];      
       
        
         List<FSO__WorkPlan__c> workPlanList = new List<FSO__WorkPlan__c>();
         FSO__WorkPlan__c wp1 = new FSO__WorkPlan__c(Name ='wp1', UNITY_Asset_Type__c ='Dock', UNITY_Group_Assets__c = true);
	     workPlanList.add(wp1);
	    
	     FSO__WorkPlan__c wp2 = new FSO__WorkPlan__c(Name ='wp2', UNITY_Asset_Type__c ='Forklift', UNITY_Group_Assets__c = false);
	     workPlanList.add(wp2);  
          insert workPlanList;
        
         List <FSO__WorkPlanItem__c> wpil = new List<FSO__WorkPlanItem__c>();
	    FSO__WorkPlanItem__c  wpi1 = new FSO__WorkPlanItem__c (Name = 'wpi1', FSO__Description__c ='wpi1', UNITY_Render_Type__c='Yes/No', FSO__WorkPlan__c = wp1.ID);
	    wpil.add(wpi1);
	     
	    FSO__WorkPlanItem__c  wpi2 = new FSO__WorkPlanItem__c (Name = 'wp2', FSO__Description__c ='wp2', UNITY_Render_Type__c='Yes/No', FSO__WorkPlan__c = wp2.ID);
	    wpil.add(wpi2);
	      insert wpil;
        
        List<UNITYPM_Work_Order_Assets_junction__c> wolis = new List<UNITYPM_Work_Order_Assets_junction__c>();
         for (Asset a :assets){
            UNITYPM_Work_Order_Assets_junction__c woli = new UNITYPM_Work_Order_Assets_junction__c ();
            if (a.UNITY_Asset_Type__c == 'Dock' ){
	            woli.Work_Order__c = wo.ID;
	            woli.Asset__c = a.ID;
	            woli.Work_Plan__c = wp1.ID;
	          
                wolis.add(woli);
	         }              
         }
        insert wolis;
        
                
        PageReference pr = Page.UNITYPM_AddRemoveAssetsPage;
    	pr.getParameters().put('id',  String.valueOf(wo.Id));
        Test.setCurrentPage(pr);
         
        ApexPages.StandardController sc = new ApexPages.StandardController(wo);
        UNITYPM_AddRemoveWOAssetsCntrlExt controller = new UNITYPM_AddRemoveWOAssetsCntrlExt(sc);
        
        List<UNITYPM_WorkPlanAssetsWrapper> wrpList = controller.getExistingwOLIs();
        system.debug('>>> nelie wrpList >>>>' + wrpList.size());
        
        List<UNITYPM_WorkPlanAssetsWrapper> wrpDisplayList = controller.getRecordsToDisplay();
       // system.assert( wrpDisplayList.size() > 0);
         system.debug('>>> nelie wrpDisplayList >>>>' + wrpDisplayList.size());
        
        List<SelectOption> numList = controller.getNumbersList();
       // system.assert( numList.size() > 0);
        system.debug('>>> nelie numList >>>>' + numList.size());
        
        List<SelectOption> assetsList = controller.getDefaultAssetsList();       
        //system.assert( assetsList.size() > 0);
        system.debug('>>> nelie assetsList >>>>' + assetsList.size());
        
        controller.accountID = cust.Id;
        controller.workOrderNumber = wo.WorkOrderNumber;
        controller.selectedAssetVal = 'Dock';
        controller.selectedNumVal = '5';
        
        controller.addDefaultAssets();
        
        asset asl = [select id, name , Description, AccountId, UNITY_Asset_Type__c from asset where UNITY_Asset_Type__c ='Dock' limit 1];
        FSO__WorkPlan__c wp = [select id, UNITY_Asset_Type__c from FSO__WorkPlan__c where UNITY_Asset_Type__c ='Dock'];
        
        List<String> selectedAssets = new List<String> ();
        String s = '{aId =' + asl.ID + ',wpId =' + wp.ID + ',aselected =1}';
        selectedAssets.add(s);
        UNITYPM_AddRemoveWOAssetsCntrlExt.handleAssetsSubmit(selectedAssets, wo.ID);  
    }
    
        public static TestMethod void test3(){
        //Get the accounts
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String urRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String poRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        List<Account> accounts = [SELECT Id,RecordTypeId,Account_Email__c FROM Account];
        Account cust;
        Account vend;
        Account bu;
        for(Account a :accounts){
            if(a.RecordTypeId == custRTId)
                cust = a;
            if(a.RecordTypeId == vendRTId)
                vend = a;
            if(a.RecordTypeId == buRTId)
                bu = a;
        }
         
        test.startTest();   
      
         
        //Get the case
        Case c = [SELECT Id FROM Case LIMIT 1];
        
        WorkOrder wo = new WorkOrder();
        wo.AccountId = cust.Id;
        wo.UNITY_Accepted_Vendor__c = vend.Id;
        wo.UNITY_Business_Unit_Account__c = bu.Id;
        wo.UNITY_Business_Unit__c = 'NSBS';
        wo.UNITY_Customer__c = cust.Id;
        wo.UNITY_Skill_Broad__c = 'Glass';
        wo.UNITY_Skill_Group__c = 'Glass Installation/Repair';
        wo.UNITY_Skill_Type__c = 'Glass, Board up, Mirrors & Displays';
        wo.Priority = '24 Hour Response';
        wo.Status = 'New';
        wo.RecordTypeId = woRTId;
        wo.CaseId = c.Id;
        insert wo;
        
        wo.UNITY_Assigned_Vendor__c = vend.Id;      
        wo.Subject='Test';
        wo.UNITY_Work_Window_Begin__c = Datetime.now();  
        wo.UNITY_Vendor_Status__c = 'Accepted';         
         update wo;
        
        wo= [SELECT ID,Account.ID, WorkOrderNumber, UNITY_Vendor_Status__c, UNITY_Assigned_Vendor__c
                               FROM WorkOrder
                                    WHERE id =: wo.ID];
        
        List<Asset> assets = new List <Asset>();
	    
	    Asset asset1 = new Asset(Name = 'Test1', Description ='Test1 asset1', AccountId = cust.Id, UNITY_Asset_Type__c= 'Dock');
        assets.add(asset1);
        Asset asset2 = new Asset(Name = 'Test2',  Description ='Test2 asset2',  AccountId = cust.Id, UNITY_Asset_Type__c ='Dock');
        assets.add(asset2);
        Asset asset3 = new Asset(Name = 'Test3',  Description ='Test3 asset3',  AccountId = cust.Id, UNITY_Asset_Type__c = 'Forklift');
        assets.add(asset3);        
        Asset asset4 = new Asset(Name = 'Test asset4',  Description ='Test asset4',  AccountId = cust.Id, UNITY_Asset_Type__c = 'Forklift');
        assets.add(asset4);
        
         insert assets;
         assets = [select id, name , Description, AccountId, UNITY_Asset_Type__c from asset];      
       
        
         List<FSO__WorkPlan__c> workPlanList = new List<FSO__WorkPlan__c>();
         FSO__WorkPlan__c wp1 = new FSO__WorkPlan__c(Name ='wp1', UNITY_Asset_Type__c ='Dock', UNITY_Group_Assets__c = true);
	     workPlanList.add(wp1);
	    
	     FSO__WorkPlan__c wp2 = new FSO__WorkPlan__c(Name ='wp2', UNITY_Asset_Type__c ='Forklift', UNITY_Group_Assets__c = false);
	     workPlanList.add(wp2);  
          insert workPlanList;
        
         List <FSO__WorkPlanItem__c> wpil = new List<FSO__WorkPlanItem__c>();
	    FSO__WorkPlanItem__c  wpi1 = new FSO__WorkPlanItem__c (Name = 'wpi1', FSO__Description__c ='wpi1', UNITY_Render_Type__c='Yes/No', FSO__WorkPlan__c = wp1.ID);
	    wpil.add(wpi1);
	     
	    FSO__WorkPlanItem__c  wpi2 = new FSO__WorkPlanItem__c (Name = 'wp2', FSO__Description__c ='wp2', UNITY_Render_Type__c='Yes/No', FSO__WorkPlan__c = wp2.ID);
	    wpil.add(wpi2);
	      insert wpil;
        
        List<UNITYPM_Work_Order_Assets_junction__c> wolis = new List<UNITYPM_Work_Order_Assets_junction__c>();
         for (Asset a :assets){
            UNITYPM_Work_Order_Assets_junction__c woli = new UNITYPM_Work_Order_Assets_junction__c ();
            if (a.UNITY_Asset_Type__c == 'Dock' ){
	            woli.Work_Order__c = wo.ID;
	            woli.Asset__c = a.ID;
	            woli.Work_Plan__c = wp1.ID;
	          
                wolis.add(woli);
	         }              
         }
        insert wolis;
        
                
        PageReference pr = Page.UNITYPM_AddRemoveAssetsPage;
    	pr.getParameters().put('id',  String.valueOf(wo.Id));
        Test.setCurrentPage(pr);
         
        ApexPages.StandardController sc = new ApexPages.StandardController(wo);
        UNITYPM_AddRemoveWOAssetsCntrlExt controller = new UNITYPM_AddRemoveWOAssetsCntrlExt(sc);
        
        List<UNITYPM_WorkPlanAssetsWrapper> wrpList = controller.getExistingwOLIs();
        system.debug('>>> nelie wrpList >>>>' + wrpList.size());
        
        List<UNITYPM_WorkPlanAssetsWrapper> wrpDisplayList = controller.getRecordsToDisplay();
       // system.assert( wrpDisplayList.size() > 0);
         system.debug('>>> nelie wrpDisplayList >>>>' + wrpDisplayList.size());
        
        List<SelectOption> numList = controller.getNumbersList();
       // system.assert( numList.size() > 0);
        system.debug('>>> nelie numList >>>>' + numList.size());
        
        List<SelectOption> assetsList = controller.getDefaultAssetsList();       
        //system.assert( assetsList.size() > 0);
        system.debug('>>> nelie assetsList >>>>' + assetsList.size());
        
        controller.accountID = cust.Id;
        controller.workOrderNumber = wo.WorkOrderNumber;
        controller.selectedAssetVal = 'Dock';
        controller.selectedNumVal = '5';
        
        controller.addDefaultAssets();
        
        asset asl = [select id, name , Description, AccountId, UNITY_Asset_Type__c from asset where UNITY_Asset_Type__c ='Dock' limit 1];
        FSO__WorkPlan__c wp = [select id, UNITY_Asset_Type__c from FSO__WorkPlan__c where UNITY_Asset_Type__c ='Dock'];
        
        List<String> selectedAssets = new List<String> ();
        String s = '{aId =' + asl.ID + ',wpId =' + wp.ID + ',aselected =0}';
        selectedAssets.add(s);
        UNITYPM_AddRemoveWOAssetsCntrlExt.handleAssetsSubmit(selectedAssets, wo.ID);
        
        
        test.stoptest();
    }
}