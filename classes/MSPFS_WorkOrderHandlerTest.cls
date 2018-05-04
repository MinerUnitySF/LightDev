@isTest
public class MSPFS_WorkOrderHandlerTest {

    private static Account accountCustomer;
	private static Account accountVendor;
	private static List<Contact> contacts;
	private static List<Case> cases;
	private static List<UNITY_Service_Contract__c> serviceContracts;
	private static WorkOrder testWo;
	private static UNITY_Invoice__c invoice;
	private static Order testPO;
	private static UNITY_Service_Contract__c testServiceContract;
	private static List<User> technicians;
	private static Product2 testLaborProduct;
	private static PricebookEntry testLaborPBE;

	static void setup() {
		TestDataProvider.setKeyValueStore();

		testLaborProduct = new Product2( Name = 'TestLaborProduct_IP', ProductCode = 'Miner-Labor', Make1__c = 'TestMake', Model__c = 'TestModel', Broad__c = 'Door',
			Group__c = 'High Speed', Type__c = 'Electrical', Family = 'Equipment', SVMXC__Product_Line__c = 'Equipment', IsActive = true, Description = 'Installed Product Test Product',
			SVMXC__Product_Cost__c = 0.00, SVMXC__Inherit_Parent_Warranty__c = true, UNITY_Status__c = 'Active', UNITY_Product_Cost__c = 0, UNITY_Unit_Of_Measure__c = 'Each',
			UNITY_Product_Type__c = 'Labor'
		);
		insert testLaborProduct;
		testLaborPBE = new PricebookEntry( Product2Id = testLaborProduct.Id, Pricebook2Id = Test.getStandardPricebookId() , UnitPrice = 2, Cost__c = 1 );
		insert testLaborPBE;
		
		accountCustomer = UNITY_TestDataFactory.createAccounts( 1, 'Site/Location', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE )[0];
		accountVendor = UNITY_TestDataFactory.createAccounts( 1, 'Customer', UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE )[0];
		contacts = UNITY_TestDataFactory.createContacts( 2, accountCustomer.Id );
		cases = UNITY_TestDataFactory.createCases( 2, accountCustomer.Id, accountVendor.Id, contacts[0].Id, UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE );
		serviceContracts = UNITY_TestDataFactory.createServiceContracts( 1, accountCustomer.Id );
		testWo = UNITY_TestDataFactory.createWorkOrders( 2, cases[0].Id, accountCustomer.Id, serviceContracts[0].Id, UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE )[0];

		testServiceContract = new UNITY_Service_Contract__c( UNITY_Account__c = accountCustomer.Id, UNITY_Margin__c = 10, UNITY_Invoicing_Method__c = 'Email' );
        insert testServiceContract;

		invoice = new UNITY_Invoice__c( UNITY_Case__c = cases[0].Id, UNITY_Customer__c = accountCustomer.Id, 
										UNITY_Customer_Service_Contract__c = testServiceContract.Id, UNITY_Service_Contract_Margin_Value__c = testServiceContract.UNITY_Margin__c);
        insert invoice;

		RecordType purchaseOrderRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'UNITY_Purchase_Order' AND SobjectType ='Order'];
		testPO = new Order( RecordTypeId = purchaseOrderRT.id, UNITY_Invoice__c = invoice.id, 
							FSO__WorkOrder__c = testWo.Id, AccountId = accountCustomer.Id, EffectiveDate = Date.today(), Status = 'Draft' );
		insert testPO;

	}

	@isTest 
	static void testUpdatePrimaryTechnician() {
		setup();

		testWO.UNITY_Primary_Technician__c = UserInfo.getUserId();

		UNITY_Constants.executionsPerTrigger.put( 'UNITY_WorkOrderTriggerHandler', 0);

		Test.StartTest();
		update testWO;
		Test.StopTest();
	}

	@isTest 
	static void testUpdateSecondaryTechnician() {
		setup();

		testWO.UNITY_Secondary_Technician__c = UserInfo.getUserId();

		UNITY_Constants.executionsPerTrigger.put( 'UNITY_WorkOrderTriggerHandler', 0);

		Test.StartTest();
		update testWO;
		Test.StopTest();
	}
    
    public static TestMethod void test1(){
        
        //Create a test user
        User u = TestDataProvider.getUsers(1)[0];
        u.Ignore_Validations__c = true;
        insert u;
        //create a queue
        Group q = new Group(Name = 'MSP Nashville Tier 1 Team 1',Type = 'Queue',DeveloperName='UNITY_Tier_1_Team_1');
        insert q;
        //Create a queue object
        QueueSObject qso = new QueueSObject(QueueID = q.id, SobjectType = 'Case');
        insert qso;
        //create a regular group
        Group g = new Group(
            Name = 'MSP Nashville Team 1',
            Type = 'Regular'
        );
        insert g;
        //Add the curremt user to the regular group
        GroupMember gm = new GroupMember(
            GroupId = g.Id,
            UserOrGroupId = u.Id
        );
        insert gm;
        //Add the regular group to the queue
        GroupMember qm = new GroupMember(
            GroupId = q.Id,
            UserOrGroupId = g.Id
        );
        insert qm;
        
        System.runAs(u){
            //Create BU SPecific Team field Map
            UNITY_BU_Team_Field_Map__c nsbsTeamMap = new UNITY_BU_Team_Field_Map__c(
                Name = 'MSP Nashville',
                UNITY_Field_API_Name__c = 'UNITY_Customer_Team__c'
            );
            insert nsbsTeamMap;
            List<Account> accts = new List<Account>();
            Account cust = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];
            cust.Account_Status__c = 'Active';
            cust.UNITY_Customer_Team__c = 'Team 1';
            cust.UNITY_MNS_Customer_Team__c = 'Team 1';
            cust.UNITY_Tier_Level__c = 'Tier 1';
            accts.add(cust);
            Account vend = TestDataProvider.getAccounts(1,'Vendor', 'Vendor')[0];
            accts.add(vend);
            Account buMSPNashville = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];
            buMSPNashville.UNITY_Business_Unit__c = 'MSP Nashville';
            accts.add(buMSPNashville);
            insert accts;
            Account loc = TestDataProvider.getAccounts(1,'Customer', 'Site/Location')[0];
            loc.Account_Status__c = 'Active';
            loc.UNITY_Customer_Team__c = 'Team 1';
            loc.UNITY_MNS_Customer_Team__c = 'Team 1';
            loc.UNITY_Tier_Level__c = 'Tier 1';
            loc.UNITY_Bill_To_Account__c = cust.Id;
            loc.ParentId = cust.Id;
            insert loc;
            
            Case c = UNITY_TestDataFactory.createCases(1,loc.Id,loc.Id)[0];
            c.UNITY_Customer__c = loc.Id;
            c.UNITY_Business_Unit__c = 'MSP Nashville';
            c.UNITY_Business_Unit_Account__c = buMSPNashville.Id;
            c.UNITY_Skill_Broad__c = 'Glass';
            
            update c;
            
            String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
            
            Test.startTest();
            WorkOrder wo = new WorkOrder();
            wo.AccountId = loc.Id;
            wo.UNITY_Assigned_Vendor__c = vend.Id;
            wo.UNITY_Business_Unit_Account__c = buMSPNashville.Id;
            wo.UNITY_Business_Unit__c = 'MSP Nashville';
            wo.UNITY_Customer__c = loc.Id;
            wo.UNITY_Skill_Broad__c = 'Glass';
            wo.UNITY_Skill_Group__c = 'Glass Installation/Repair';
            wo.UNITY_Skill_Type__c = 'Glass, Board up, Mirrors & Displays';
            wo.Priority = '24 Hour Response';
            wo.Status = 'New';
            wo.RecordTypeId = woRTId;
            wo.CaseId = c.Id;
            insert wo;
            
            wo.UNITY_Accepted_Vendor__c = vend.Id;
            wo.UNITY_Vendor_Status__c = 'Accepted';
            update wo;
            
            Set<Id> cids = new Set<Id>();
            cids.add(c.Id);
            UNITY_WorkOrderTriggerHandler_Miner.reassignCaseToCustTeam(cids);
            UNITY_WorkOrderTriggerHandler_Miner.runTriggerOnce_After();
            UNITY_WorkOrderTriggerHandler_Miner.runTriggerOnce_After();
            UNITY_WorkOrderTriggerHandler_Miner.runTriggerOnce_Before();
            UNITY_WorkOrderTriggerHandler_Miner.runTriggerOnce_Before();
            
            Test.stopTest();
        }
    }
    
    private static testMethod void testUpdateWorkOrders(){
    	String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
		String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
		String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
		String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;    
    	
		Account cust;
	    Account vend;
    	Account bu;
    	
    	TestDataProvider.unityTestSetup();
    	
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
        //Get the case
        Case testCase = [SELECT Id FROM Case LIMIT 1];            
            
        Account testBUAcct = [SELECT Id FROM Account LIMIT 1];
        testBUAcct.MSPFS_Is_MSP_BU__c = true;
        update testBUAcct;
    	
    	Test.startTest();	
    	//Create a new Work Order record
        WorkOrder newWO = new WorkOrder();
        newWO.AccountId = cust.Id;
        newWO.UNITY_Accepted_Vendor__c = vend.Id;
        newWO.UNITY_Business_Unit_Account__c = bu.Id;
        newWO.UNITY_Business_Unit__c = 'NSBS';
        newWO.UNITY_Customer__c = cust.Id;
        newWO.UNITY_Skill_Broad__c = 'Glass';
        newWO.UNITY_Skill_Group__c = 'Glass Installation/Repair';
        newWO.UNITY_Skill_Type__c = 'Glass, Board up, Mirrors & Displays';
        newWO.Priority = '24 Hour Response';
        newWO.Status = 'New';
        newWO.RecordTypeId = woRTId;
        newWO.CaseId = testCase.Id;
        newWO.Description = 'Test Test Test';
        newWO.UNITY_Work_Description__c = 'Test Test Test';
        newWO.UNITY_Work_Window_Begin__c = DateTime.now();
        newWO.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
        newWO.MSPFS_Service_Order_Type__c = 'Quoted';
        newWO.StartDate = DateTime.now().addMinutes(2);
        insert newWO;  
    	    	
        List<Id> workOrderIds = new List<Id>();
        workOrderIds.add(newWO.Id);
        MSPFS_WorkOrderHandler.updateWorkOrder(workOrderIds);
        
        WorkOrder wo = [SELECT Id, UNITY_Vendor_Status__c FROM WorkOrder WHERE Id = :newWO.Id];
        system.assert(wo.UNITY_Vendor_Status__c == UNITY_Constants.WO_VENDOR_STATUS_ACCEPTED);

        Test.stopTest();
    }
    
    private static testMethod void testShareWOWithBU(){
    	String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
		String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
		String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
		String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;    

		//Setup Product and Pricebook Info
	    Id PRICEBOOKENTRYID_T;
	    Id PRICEBOOKENTRYID_L;
	    Id PRICEBOOKENTRYID_P;
	    Id PRODUCTID;
	    
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
       	
		Account cust;
	    Account vend;
    	Account bu;
    	
    	TestDataProvider.unityTestSetup();
    	
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
        //Get the case
        Case testCase = [SELECT Id FROM Case LIMIT 1];            
            
        Account testBUAcct = [SELECT Id FROM Account LIMIT 1];
        testBUAcct.MSPFS_Is_MSP_BU__c = true;
        update testBUAcct;
   	
    	Test.startTest();	
    	//Set custom setting to automatically create service record
        FSL_INTG__Sync_Settings__c cSetting = FSL_INTG__Sync_Settings__c.getOrgDefaults();
		cSetting.FSL_INTG__Service_Work_Order_Sync__c = true;
        cSetting.FSL_INTG__Absence_Request_Auto_Approve__c = true;
        cSetting.FSL_INTG__Request_Sync__c = true;
        cSetting.FSL_INTG__Service_Required_Skill_Sync__c = true;
        cSetting.FSL_INTG__Skill_Sync__c = true;
        cSetting.FSL_INTG__Update_WOLI_Owner__c = true;
        cSetting.FSL_INTG__Update_WO_Expected_Duration__c = true;
		upsert cSetting;
		
    	//Create a new Work Order record
        WorkOrder newWO = new WorkOrder();
        newWO.AccountId = cust.Id;
        newWO.UNITY_Accepted_Vendor__c = vend.Id;
        newWO.UNITY_Business_Unit_Account__c = bu.Id;
        newWO.UNITY_Business_Unit__c = 'NSBS';
        newWO.UNITY_Customer__c = cust.Id;
        newWO.UNITY_Skill_Broad__c = 'Glass';
        newWO.UNITY_Skill_Group__c = 'Glass Installation/Repair';
        newWO.UNITY_Skill_Type__c = 'Glass, Board up, Mirrors & Displays';
        newWO.Priority = '24 Hour Response';
        newWO.Status = 'New';
        newWO.RecordTypeId = woRTId;
        newWO.CaseId = testCase.Id;
        newWO.Description = 'Test Test Test';
        newWO.UNITY_Work_Description__c = 'Test Test Test';
        newWO.UNITY_Work_Window_Begin__c = DateTime.now();
        newWO.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
        newWO.MSPFS_Service_Order_Type__c = 'Quoted';
        insert newWO;  
    	
    	Order o = new Order();
    	o.AccountId = cust.Id;
    	o.FSO__WorkOrder__c = newWO.Id;
    	o.UNITY_Vendor__c = vend.Id;
    	o.EffectiveDate = Date.Today();
    	o.Status = 'Draft';
    	insert o;
    	
    	//Create technicians
    	CKSW_BASE__Location__c baseLoc = new CKSW_BASE__Location__c();
        baseLoc.Name = 'Nashville';
        baseLoc.MSPFS_Business_Unit_Account__c = vend.Id;
        insert baseLoc;
        
        //Define a new resource    
        User techUser = TestDataProvider.getUser('Technician', 'New', 'NMS Technician');
        insert techUser;
        
        CKSW_BASE__Resource__c tech = new CKSW_BASE__Resource__c();
        tech.Name = 'Technician New';
        tech.MSPFS_Burden_Rate__c = 40.00;
        tech.CKSW_BASE__Location__c = baseLoc.Id;            
        tech.MSPFS_BU_Default_Resource__c = true;
        tech.CKSW_BASE__User__c = techUser.Id;
        insert tech;
        
		//Create dispatcher
		User disp1User = TestDataProvider.getUser('Dispatcher', 'One', 'NMS Technician');
        insert disp1User;
        
		CKSW_BASE__User_Location__c userLoc1 = new CKSW_BASE__User_Location__c();
		userLoc1.CKSW_BASE__Location__c = baseLoc.Id;
		userLoc1.CKSW_BASE__User__c = disp1User.Id;
		insert userLoc1;
	
		Map<Id, List<WorkOrder>> woMap =  new Map<Id, List<WorkOrder>>();
		List<WorkOrder> myWOList = new List<WorkOrder>();
		myWOList.add(newWO);
		woMap.put(newWO.UNITY_Accepted_Vendor__c, myWOList);
		
		MSPFS_WorkOrderHandler.shareWorkOrdersWithBU(woMap);
		
		//Verifty if the Order was shared
		List<OrderShare> oShare = [SELECT Id, UserOrGroupId, OrderAccessLevel, RowCause FROM OrderShare 
									WHERE OrderId = :o.id AND OrderAccessLevel = 'Edit' AND UserOrGroupId = :disp1User.Id];
		System.Assert(oShare.size() > 0);
		
		
        Test.stopTest();
    
    }    
    
    private static testMethod void testHandleIntercompanyTransferSharing(){
    	String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
		String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
		String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
		String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;    

		Account cust;
	    Account vend;
    	Account bu;
    	
    	TestDataProvider.unityTestSetup();
    	
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
        
        vend = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];bu.UNITY_Business_Unit__c = 'NSBS';bu.UNITY_Company_Code__c = 'NSBS';bu.UNITY_Vendor_Status__c = 'Active';
        vend.MSPFS_Is_MSP_BU__c = true;
        insert vend;
        
        //Get the case
        Case testCase = [SELECT Id FROM Case LIMIT 1];            
         
    	//Set custom setting to automatically create service record
        FSL_INTG__Sync_Settings__c cSetting = FSL_INTG__Sync_Settings__c.getOrgDefaults();
		cSetting.FSL_INTG__Service_Work_Order_Sync__c = true;
        cSetting.FSL_INTG__Absence_Request_Auto_Approve__c = true;
        cSetting.FSL_INTG__Request_Sync__c = true;
        cSetting.FSL_INTG__Service_Required_Skill_Sync__c = true;
        cSetting.FSL_INTG__Skill_Sync__c = true;
        cSetting.FSL_INTG__Update_WOLI_Owner__c = true;
        cSetting.FSL_INTG__Update_WO_Expected_Duration__c = true;
		upsert cSetting;
   		
    	Test.startTest();	
    	//Create a new Work Order record
        WorkOrder newWO = new WorkOrder();
        newWO.AccountId = cust.Id;
        newWO.UNITY_Business_Unit_Account__c = bu.Id;
        newWO.UNITY_Business_Unit__c = 'NSBS';
        newWO.UNITY_Customer__c = cust.Id;
        newWO.UNITY_Skill_Broad__c = 'Glass';
        newWO.UNITY_Skill_Group__c = 'Glass Installation/Repair';
        newWO.UNITY_Skill_Type__c = 'Glass, Board up, Mirrors & Displays';
        newWO.Priority = '24 Hour Response';
        newWO.Status = 'New';
        newWO.RecordTypeId = woRTId;
        newWO.CaseId = testCase.Id;
        newWO.Description = 'Test Test Test';
        newWO.UNITY_Work_Description__c = 'Test Test Test';
        newWO.UNITY_Work_Window_Begin__c = DateTime.now();
        newWO.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
        newWO.MSPFS_Service_Order_Type__c = 'Quoted';
        insert newWO;  

    	//Create technicians
    	CKSW_BASE__Location__c baseLoc = new CKSW_BASE__Location__c();
        baseLoc.Name = 'Nashville';
        baseLoc.MSPFS_Business_Unit_Account__c = vend.Id;
        insert baseLoc;
        
        //Define a new resource    
        User techUser = TestDataProvider.getUser('Technician', 'New', 'NMS Technician');
        insert techUser;
        
        CKSW_BASE__Resource__c tech = new CKSW_BASE__Resource__c();
        tech.Name = 'Technician New';
        tech.MSPFS_Burden_Rate__c = 40.00;
        tech.CKSW_BASE__Location__c = baseLoc.Id;            
        tech.MSPFS_BU_Default_Resource__c = true;
        tech.CKSW_BASE__User__c = techUser.Id;
        insert tech;
        
		//Create dispatcher
		User disp1User = TestDataProvider.getUser('Dispatcher', 'One', 'NMS Technician');
        insert disp1User;
        
		CKSW_BASE__User_Location__c userLoc1 = new CKSW_BASE__User_Location__c();
		userLoc1.CKSW_BASE__Location__c = baseLoc.Id;
		userLoc1.CKSW_BASE__User__c = disp1User.Id;
		insert userLoc1;
		
		newWO.UNITY_Accepted_Vendor__c = vend.Id;
        newWO.MSPFS_Related_Is_Intercompany__c = true;
		update newWO;
		
		//Verify if the Service was shared
		CKSW_BASE__Service__c serv = [SELECT Id, CKSW_BASE__Resource__c FROM CKSW_BASE__Service__c WHERE FSL_INTG__Work_Order__c = :newWO.Id LIMIT 1];
		System.Assert(serv != null);
		List<CKSW_BASE__Service__Share> sShare = [SELECT Id, UserOrGroupId, AccessLevel, RowCause FROM CKSW_BASE__Service__Share WHERE ParentId = :serv.Id];
		System.Assert(sShare != null);
		
        Test.stopTest();
    
    }    
    
}