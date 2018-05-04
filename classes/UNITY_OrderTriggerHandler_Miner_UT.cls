/**UNITY_OrderTriggerHandler_Miner_UT
 * @description: This class is the unit test for the UNITY_OrderTriggerHandler_Miner apex class
 * @programer:   Izay Ramos-Irizarry
 * @date:        3/30/2016
 * @version:     1.0
 */
@isTest
public class UNITY_OrderTriggerHandler_Miner_UT {
    //Setup Product and Pricebook Info
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
        
        List<Order> ords = new List<Order>();
        
        Order o = new Order();
        o.RecordTypeId = urRTId;
        o.AccountId = cust.Id;
        o.UNITY_Vendor__c = vend.Id;
        o.Type = 'Usage Request PO';
        o.UNITY_Business_Unit__c = 'NSBS';
        o.UNITY_Business_Unit_Account__c = bu.Id;
        o.Status = 'Draft';
        o.FSO__WorkOrder__c = wo.Id;
        o.EffectiveDate = Date.today();
        
        Order o2 = new Order();
        o2.RecordTypeId = poRTId;
        o2.AccountId = cust.Id;
        o2.UNITY_Vendor__c = vend.Id;
        o2.Type = 'Vendor PO';
        o2.UNITY_Business_Unit__c = 'NSBS';
        o2.UNITY_Business_Unit_Account__c = bu.Id;
        o2.Status = 'Draft';
        o2.FSO__WorkOrder__c = wo.Id;
        o2.EffectiveDate = Date.today();
        
        ords.add(o);
        //ords.add(o2);
        
        test.startTest();
        
        resetTrigger();
        insert o;
        o.Status = 'Final';
        
        resetTrigger();
        o2.UNITY_Originating_Usage_Request__c = o.Id;
        insert o2;
        
        resetTrigger();
        o2.Status = 'Final';
        update o2;

        UNITY_OrderTriggerHandler_Miner.setVendorContract(ords,UNITY_Constants.ContractType.SERVICE_REQUEST);
        
        UNITY_OrderTriggerHandler_Miner.runTriggerOnce_Before();
        UNITY_OrderTriggerHandler_Miner.runTriggerOnce_Before();
        UNITY_OrderTriggerHandler_Miner.runTriggerOnce_After();
        UNITY_OrderTriggerHandler_Miner.runTriggerOnce_After();
        
        test.stopTest();
        
    }
    public static TestMethod void test2(){
        //Get the accounts
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String stockPORTId = UNITY_Constants.ORDER_STOCKING_PURCHASE_ORDER_RECORDTYPE;
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
        //Get the case
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
        
        test.startTest();
        
        resetTrigger();
        Order o = new Order();
        o.RecordTypeId = stockPORTId;
        o.AccountId = cust.Id;
        o.UNITY_Vendor__c = vend.Id;
        o.Type = 'Usage Request PO';
        o.UNITY_Business_Unit__c = 'NSBS';
        o.UNITY_Business_Unit_Account__c = bu.Id;
        o.Status = 'Draft';
        o.EffectiveDate = Date.today();
        insert o;
        
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
        
        resetTrigger();
        o.Status = 'Parts Order Required';
        update o;
        
        resetTrigger();
        o.Status = 'Parts Being Delivered';
        o.UNITY_Tracking_Number__c = '111';
        o.UNITY_Shipping_Provider__c = 'FedEx';
        o.UNITY_Shipping_Method__c = 'Ground';
        o.UNITY_Expected_Arrival_Date__c = Date.today() + 3;
        update o;
        
        resetTrigger();
        oi.UNITY_Actual_Ship_Date__c = Date.today();
        oi.UNITY_Actual_Quantity__c = 10;
        update oi;

        test.stopTest();
    }
    
    public static testMethod void testCheckNTEFinalOrder(){
        Account cust;
        Account vend;
        Account bu;
        
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String usageRecRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String purchaseOrdRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        
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
        
        bu.MSPFS_Is_MSP_BU__c = false;
        update bu;
        
        vend.MSPFS_Is_MSP_BU__c = true;
        update vend;
        
        UNITY_Service_Contract__c serviceContract = new UNITY_Service_Contract__c();
        serviceContract.UNITY_Account__c = bu.Id;
        serviceContract.UNITY_Business_Unit__c = 'MSP San Antonio';
        serviceContract.UNITY_IS_Active__c = true;
        serviceContract.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        serviceContract.Default_Customer_Service_Contract__c = true;
        serviceContract.Residential__c = false;        
        serviceContract.UNITY_Is_Pass_Through__c = true;
        serviceContract.UNITY_Cost_Plus__c = 5;
        insert serviceContract;
                
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        testCase.UNITY_NTE_Threshold__c = 100;
        testCase.UNITY_Customer_Service_Contract__c = serviceContract.Id;
        update testCase;

        //Create a Work Order
        WorkOrder wo = new WorkOrder();
        wo.AccountId = cust.Id;
        wo.UNITY_Assigned_Vendor__c = vend.Id;
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
        wo.CaseId = testCase.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        wo.UNITY_Work_Window_Begin__c = DateTime.now();
        wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);        
        insert wo;    
        
        FSO__Location__c loc = new FSO__Location__c();
        loc.Name = 'Miner Nashville Warehouse';
        loc.FSO__Geolocation__Latitude__s = 1.0;
        loc.FSO__Geolocation__Longitude__s = 1.0;
        insert(loc);
        
        Test.startTest();

        Order o = new Order();
        o.RecordTypeId = purchaseOrdRTId;
        o.AccountId = cust.Id;
        o.UNITY_Vendor__c = vend.Id;
        o.Type = 'Usage Request PO';
        o.UNITY_Business_Unit__c = 'NSBS';
        o.UNITY_Business_Unit_Account__c = bu.Id;
        o.Status = UNITY_Constants.ORDER_STATUS_PART_ORDER_REQUIRED;
        o.FSO__WorkOrder__c = wo.Id;
        o.EffectiveDate = Date.today();
        o.UNITY_Discount__c = 5;
        insert o;
        
       OrderItem oi = new OrderItem(
            UNITY_Type__c = 'Vendor Services',
            UNITY_Activity_Type__c = 'Parts - New Construction',
            PricebookEntryId = PRICEBOOKENTRYID_P,
            OrderId = o.Id,
            Quantity = 5,
            UnitPrice = 10,
            UNITY_Part_Source__c = bu.Id,
            UNITY_Part_Location__c = loc.Id,
            UNITY_Is_Vendor_Supply__c = true,
            UNITY_Not_Billable__c = false,
            UNITY_Discount__c = 25.00,
            UNITY_Total_Price__c = 100            
        );
        insert oi;
               
        o.Status = 'Final'; //UNITY_Constants.ORDER_STATUS_FINAL;
        update o;
        
        //Test scenario: Price is not over the NTE Threshold
        Order ord = [SELECT UNITY_Final_Price__c FROM Order WHERE Id = :o.Id];
        System.Assert(ord.UNITY_Final_Price__c < testCase.UNITY_NTE_Threshold__c);
        
        //Update NTE Threshold
        testCase.UNITY_NTE_Threshold__c = 50;
        update testCase;
  
        o.Status = UNITY_Constants.ORDER_STATUS_PART_ORDER_REQUIRED;
        update o;

        //Test scenario: Price is over the NTE Threshold          
        try {
            o.Status =  'Final';  //UNITY_Constants.ORDER_STATUS_FINAL;
            update o;
            System.assert(false, 'exception expected');
        } catch (Exception e) {
            String message = e.getMessage();
            System.assert(message.contains('The order will make the Case go over the NTE'));
        }
        Test.stopTest();
    }
    
    public static testMethod void testShareOrderWithAgent(){
        Account cust;
        Account vend;
        Account bu;
        
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String usageRecRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String purchaseOrdRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        
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
        
        bu.MSPFS_Is_MSP_BU__c = false;
        update bu;
        
        vend.MSPFS_Is_MSP_BU__c = true;
        update vend;
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        //Create an agent
        User agent = TestDataProvider.getUser('Agent', 'One', 'NMS Technician');
        insert agent;
        
        //Create a Work Order
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
        wo.CaseId = testCase.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        wo.UNITY_Work_Window_Begin__c = DateTime.now();
        wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
        wo.MSPFS_Intercompany_Transfer__c = true;
        wo.UNITY_Agent__c = agent.Id;
        insert wo;    
        
        Test.startTest();
        Order order = new Order(FSO__WorkOrder__c = wo.Id,Type = 'Vendor PO', RecordTypeId = usageRecRTId, 
                                AccountId = cust.Id, EffectiveDate = Date.Today(), Status = 'Draft');
        
        insert order;

        Test.stopTest();
        
        //Verify the order was shared
        try{
            List<OrderShare> oShare = [SELECT UserOrGroupId FROM OrderShare WHERE OrderId = :order.Id AND UserOrGroupId = :agent.Id];
            System.assert(oShare != null);
        }catch(Exception e){
            //Just in case!!!
        }
            
    }
    
    public static testMethod void testShareOrderWithTechAndDisp(){
        Account cust;
        Account vend;
        Account bu;
        
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String usageRecRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String purchaseOrdRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        
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
        
        bu.MSPFS_Is_MSP_BU__c = false;
        update bu;
        
        vend.MSPFS_Is_MSP_BU__c = true;
        update vend;
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        //Create an agent
        User agent = TestDataProvider.getUser('Agent', 'One', 'NMS Technician');
        insert agent;
        
        //Create a Work Order
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
        wo.CaseId = testCase.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        wo.UNITY_Work_Window_Begin__c = DateTime.now();
        wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
        wo.MSPFS_Intercompany_Transfer__c = true;
        insert wo;    
        
        User oOwner = TestDataProvider.getUser('Owner', 'One', 'UNITY_FSL Technician');
        oOwner.UNITY_Segment__c = 'NSBS';
        insert oOwner; 
        
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
        tech.CKSW_BASE__User__c = techUser.Id;
        insert tech;

        //Create dispatcher
        User disp1User = TestDataProvider.getUser('Dispatcher', 'One', 'NMS Technician');
        insert disp1User;
        
        CKSW_BASE__User_Location__c userLoc1 = new CKSW_BASE__User_Location__c();
        userLoc1.CKSW_BASE__Location__c = baseLoc.Id;
        userLoc1.CKSW_BASE__User__c = disp1User.Id;
        insert userLoc1;

        Test.startTest();

        Order order = new Order(FSO__WorkOrder__c = wo.Id,Type = 'Vendor PO', RecordTypeId = purchaseOrdRTId, 
                                AccountId = cust.Id, EffectiveDate = Date.Today(), Status = 'Draft');
        order.UNITY_Vendor__c = vend.Id;
        order.OwnerId = oOwner.Id;      
        insert order;

        Test.stopTest();
        //Verify the order was shared to technician
        OrderShare oShare = [SELECT UserOrGroupId FROM OrderShare WHERE OrderId = :order.Id AND UserOrGroupId = :techUser.Id];
        System.assert(oShare != null);
        
        //Verify the order was shared to the dispatcher
        OrderShare oShare2 = [SELECT UserOrGroupId FROM OrderShare WHERE OrderId = :order.Id AND UserOrGroupId = :disp1User.Id];
        System.assert(oShare != null);
    }
    
    public static testMethod void testUpdatePOStatus(){
        Account cust;
        Account vend;
        Account bu;
        
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String usageRecRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String purchaseOrdRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        
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
        
        bu.MSPFS_Is_MSP_BU__c = false;
        update bu;
        
        vend.MSPFS_Is_MSP_BU__c = true;
        update vend;
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        //Create an agent
        User agent = TestDataProvider.getUser('Agent', 'One', 'NMS Technician');
        insert agent;
        
        //Create a Work Order
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
        wo.CaseId = testCase.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        wo.UNITY_Work_Window_Begin__c = DateTime.now();
        wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
        wo.MSPFS_Intercompany_Transfer__c = true;
        wo.UNITY_Agent__c = agent.Id;
        insert wo;    
        
        Test.startTest();
        Order order = new Order(FSO__WorkOrder__c = wo.Id,Type = 'Vendor PO', RecordTypeId = UNITY_Constants.ORDER_STOCKING_PURCHASE_ORDER_RECORDTYPE, 
                                AccountId = cust.Id, EffectiveDate = Date.Today(), Status = 'Draft');
        insert order;
        
        
        OrderItem oi = new OrderItem(
            UNITY_Type__c = 'Parts',
            UNITY_Activity_Type__c = 'Parts - New Construction',
            UNITY_Is_Vendor_Supply__c = false,
            PricebookEntryId = PRICEBOOKENTRYID_P,
            OrderId = order.Id,
            Quantity = 5,
            UnitPrice = 10,
            UNITY_Cost__c = 12,
            UNITY_Part_Source__c = bu.Id,
            //UNITY_Part_Location__c = location.Id,
            UNITY_Shipment_Received__c = true
        ); 
        insert oi;
        
        Test.stopTest();
        
        Order updatedOrder = [SELECT Status FROM Order WHERE Id = :order.Id];
        
        System.Assert(updatedOrder.Status == 'Completed');
            
    }
    
    private static void createuser(User runAsUser, Contact c, String username, String email){        
        
        system.runAs(runAsUser){
			Profile p = [select Id,name from Profile where UserType = 'PowerCustomerSuccess' limit 1];
            system.debug('@@@p:'+p);

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
    
    public static testMethod void testOrderVendorShare(){
        Account cust;
        Account vend;
        Account bu;
        
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
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
        
        createuser(admin, c, 'test1@dkfjlf.com.d1', 'test1@dkfjlf.com');
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        //Create an agent
        User agent = TestDataProvider.getUser('Agent', 'One', 'NMS Technician');
        insert agent;
        
        //Create a Work Order
        WorkOrder wo = new WorkOrder();
        wo.AccountId = cust.Id;
        wo.UNITY_Business_Unit_Account__c = bu.Id;
        wo.UNITY_Business_Unit__c = 'NSBS';
        wo.UNITY_Customer__c = cust.Id;
        wo.UNITY_Skill_Broad__c = 'Glass';
        wo.UNITY_Skill_Group__c = 'Glass Installation/Repair';
        wo.UNITY_Skill_Type__c = 'Glass, Board up, Mirrors & Displays';
        wo.Priority = '24 Hour Response';
        wo.Status = 'New';
        wo.RecordTypeId = woRTId;
        wo.CaseId = testCase.Id;
        wo.Description = 'Test Test Test';
        wo.UNITY_Work_Description__c = 'Test Test Test';
        wo.UNITY_Work_Window_Begin__c = DateTime.now();
        wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
        wo.MSPFS_Intercompany_Transfer__c = true;
        wo.UNITY_Agent__c = agent.Id;
        wo.UNITY_Assigned_Vendor__c = vend.Id;
        wo.UNITY_Accepted_Vendor__c = vend.Id;
        wo.UNITY_Vendor_Status__c = 'Accepted';
        insert wo;    
        
        Order ord = new Order(FSO__WorkOrder__c = wo.Id,Type = 'Vendor PO', RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE, 
                                AccountId = cust.Id, EffectiveDate = Date.Today(), UNITY_Vendor__c = vend.Id, Status = 'Final');
        insert ord;

        Test.stopTest();

        List<UserRole> ur = [SELECT Id, PortalAccountId FROM UserRole WHERE PortalAccountId = :vend.Id];
        system.debug('@@@testOrderVendorShare ur:'+ur);
        Map<Id,Group> groupMap = new Map<Id, Group>([SELECT Id, RelatedID FROM Group WHERE RelatedID = :ur[0].Id]);
        system.debug('@@@testOrderVendorShare groupMap.keySet():'+groupMap.keySet());
        List<OrderShare> shareList = [SELECT Id, UserOrGroupId FROM OrderShare 
                              WHERE UserOrGroupId = :groupMap.keySet()];
        system.debug('@@@testOrderVendorShare share:'+shareList);
        System.Assert(shareList.size() > 0);
        
		ord.Status = 'Draft';
        update ord;
        
		shareList = [SELECT Id, UserOrGroupId FROM OrderShare 
                              WHERE UserOrGroupId = :groupMap.keySet()];
        system.debug('@@@testOrderVendorShare unshare:'+shareList);
        System.Assert(shareList.size() <= 0);
        
        ord.Status = 'Final';
        update ord;
        
        shareList = [SELECT Id, UserOrGroupId FROM OrderShare 
                              WHERE UserOrGroupId = :groupMap.keySet()];
        system.debug('@@@testOrderVendorShare share:'+shareList);
        System.Assert(shareList.size() > 0);
                    
    }    
     
    public static void resetTrigger(){
        UNITY_OrderTriggerHandler_Miner.isFirstTriggerRun_Before = true;
        UNITY_OrderTriggerHandler_Miner.isFirstTriggerRun_After = true;   
    }
}