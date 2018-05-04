@isTest
public class UNITY_WorkOrderTriggerHandlerHelperTest {
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
    @testSetup 
    static void init() {
        
        /*
        List<UNITY_General_Settings__c> generalSettings = new List<UNITY_General_Settings__c>();
            
        UNITY_General_Settings__c gSetting1 = new UNITY_General_Settings__c(Name= UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, UNITY_Value__c = 'Vendor Service Fee', UNITY_Description__c='Vendor Service Fee');
        
        generalSettings.add(gSetting1);
        
        insert generalSettings;
        */
            
        Map<String,Object> accountFields = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;  
        
        accountFields.put('Type','Site/Location' );
        accountFields.put('RecordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE );
        accountFields.put('Account_Status__c', 'Active' );
        
        RecordType srRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'UNITY_Service_Request' AND SObjectType = 'Case'];
        
        List<Account> accountList = new List<Account>();
        
        Account acc = (Account) UNITY_TestDataFactory.createObject(1, Account.getSObjectType(), accountFields).get(0);
        accountList.add(acc);
        
        Account customer = (Account) UNITY_TestDataFactory.createObject(1, Account.getSObjectType(), accountFields).get(0);
        accountList.add(customer);
        
        Account vendorAccount = new Account();
        
        vendorAccount.RecordTypeId  = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        vendorAccount.Name = 'Test Vendor Account';
        vendorAccount.Type = 'Site/Location';
        vendorAccount.BillingCity = 'Brooklyn';
        vendorAccount.BillingStateCode = 'NY';
        vendorAccount.BillingStreet = '123 Fake St.';
        vendorAccount.BillingPostalCode = '123456';
        vendorAccount.Account_Status__c = 'Active';
        
        accountList.add(vendorAccount);
        
        insert accountList;
        
        Contact c = new Contact();
        
        c.FirstName = 'Test';
        c.LastName = 'Test';
        c.Email='test@test.com';
        
        insert c;
        
        Case caseRecord = new Case();
        
        caseRecord.Status = 'Verified';
        caseRecord.RecordTypeId = srRT.Id;
        caseRecord.UNITY_Customer__c = customer.Id;
        caseRecord.ContactId = c.Id;
        caseRecord.UNITY_Business_Unit__c = 'MNS';
        
        insert caseRecord;
        
        UNITY_Service_Contract__c vendorContract = new UNITY_Service_Contract__c();
        
        vendorContract.UNITY_Account__c = vendorAccount.Id;
        vendorContract.UNITY_Trip_Charge__c = 10;
        vendorContract.UNITY_Trip_Charge_Type__c = 'Hourly Rate';
        vendorContract.UNITY_Default_Labor_Rate__c = 75;
        vendorContract.UNITY_Invoicing_Increments__c = 'Next ¼ hr';
        vendorContract.UNITY_Business_Unit__c = 'MNS';
        vendorContract.UNITY_IS_Active__c = true;
        vendorContract.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        
        insert vendorContract;
        
        WorkOrder wo = new WorkOrder();
        
        wo.UNITY_Customer__c = customer.Id;
        wo.Status = 'New';
        wo.AccountId = acc.Id;
        wo.UNITY_Assigned_Vendor__c = vendorAccount.Id;
        wo.CaseId = caseRecord.Id;
        wo.Subject='Test';
        wo.UNITY_Work_Window_Begin__c = Datetime.now();
        wo.UNITY_Accepted_Vendor__c = vendorAccount.Id;
        wo.UNITY_Vendor_Status__c = 'Accepted';
        wo.UNITY_Vendor_Contract__c = vendorContract.Id;
        wo.UNITY_Customer_Service_Contract__c = vendorContract.Id;
        
        insert wo;
        
        Product2 laborProduct = new Product2();
        
        laborProduct.Name = 'labor product test';
        laborProduct.IsActive = true ;
        laborProduct.Description  = 'labor product test';
        laborProduct.UNITY_Product_Type__c = 'Labor';
        laborProduct.Model__c = 'product test';
        laborProduct.UNITY_Status__c = 'Inactive';
        
        insert laborProduct;
        
        PricebookEntry pbe = new PricebookEntry();
        
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.Product2Id = laborProduct.Id;
        pbe.UnitPrice = 80;
        
        insert pbe;
        
        FSO__Location__c location = new FSO__Location__c();
        
        location.FSO__Geolocation__Latitude__s = 10;
        location.FSO__Geolocation__Longitude__s = 10;
        
        insert location; 
        
        Order orderRecord = new Order();
            
        orderRecord.FSO__WorkOrder__c = wo.Id;
        orderRecord.AccountId = customer.Id;
        orderRecord.EffectiveDate = Date.today();
        orderRecord.Status = 'Draft';
        orderRecord.UNITY_Location__c = location.Id;
        orderRecord.RecordTypeId = UNITY_Constants.ORDER_STOCKING_PURCHASE_ORDER_RECORDTYPE;
        
        orderRecord.UNITY_Vendor__c = vendorAccount.Id;
        orderRecord.UNITY_Business_Unit__c = 'MNS';
        
        insert orderRecord;
        
        List<OrderItem> orderItemList = new List<OrderItem>();
        
        OrderItem orderItem1 = new OrderItem();
        
        orderItem1.orderId = orderRecord.Id;
        orderItem1.PricebookEntryId = pbe.Id;
        orderItem1.UnitPrice =  pbe.UnitPrice;
        orderItem1.Quantity = 2;
        
        orderItemList.add(orderItem1);
        
        OrderItem orderItem2 = new OrderItem();
        
        orderItem2.orderId = orderRecord.Id;
        orderItem2.PricebookEntryId = pbe.Id;
        orderItem2.UnitPrice =  pbe.UnitPrice;
        orderItem2.Quantity = 3;
        
        orderItemList.add(orderItem2);
        
        insert orderItemList;
        
    }
    
    static testMethod void adjustLaborHoursTest(){
        
        Test.startTest();
        
            WorkOrder wo = [select id, SFPS_FS_OverallStatus__c, Status from WorkOrder where Subject='Test'];
            
            wo.FSO__Check_In_Date__c = Datetime.now();
            wo.StartDate = Datetime.now();
            
            wo.UNITY_Tech_ETA_Date_Cust__c = Datetime.now().format();
            wo.UNITY_Start_Travel_Date_Cust__c = Datetime.now().format();
            wo.UNITY_Check_In_Date_Cust__c = Datetime.now().format();
            wo.UNITY_Check_Out_Date_Cust__c = Datetime.now().format();
            
            update wo;
            
            wo = [select id, SFPS_FS_OverallStatus__c, Status from WorkOrder where Subject='Test'];
            
            wo.Status = 'IVR Check Out - Agent Review Needed';
            
            wo.SFPS_FS_OverallStatus__c = 'In Progress';
            
            update wo;
            
            System.assertEquals('IVR Check Out - Agent Review Needed', wo.Status, 'Status should be \'IVR Check Out - Agent Review Needed\'');
            System.assertEquals('In Progress', wo.SFPS_FS_OverallStatus__c, 'Status should be \'In Progress\'');
            
            wo.SFPS_FS_AllTasks_Completed__c = 'All Tasks Completed/Verified';
            
            update wo;
            
            wo = [select id, SFPS_FS_OverallStatus__c, Status from WorkOrder where Subject='Test'];
            
            //System.assertEquals('Completed', wo.SFPS_FS_OverallStatus__c, 'WO Overall Status should be Completed');                     
            
        Test.stopTest();
    }
}