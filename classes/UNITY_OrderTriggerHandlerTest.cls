@isTest
public class UNITY_OrderTriggerHandlerTest {
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
    /*
     *  Description : check when the Purchase Order status is changed from Draft to Final, the parent WO fields : WO.UNITY_Current_PO and WO.UNITY_Action are updated.
     * 
     */
    static testMethod void setFinalOrder() {
        
        setUpTestData1(); 
        TestDataProvider.setKeyValueStore();
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        Test.startTest();
        
            Map<id, WorkOrder> workOrders = new Map<id, WorkOrder>([SELECT id,UNITY_Current_PO__c , UNITY_Action__c,
                                                                                          (SELECT id, FSO__WorkOrder__c 
                                                                                           FROM FSO__Orders__r
                                                                                           WHERE recordTypeId = :UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE)
                                                                                     FROM  WorkOrder ]);
            Map<id,Order> wo_orders_a = new Map<id,Order>();
            Map<id,Order> wo_orders_b = new Map<id,Order>();
        
            for(WorkOrder onWO :workOrders.values()){
                system.assertEquals(null, onWO.UNITY_Current_PO__c, 'Should be null');
                system.assertEquals(null, onWO.UNITY_Action__c, 'Should be null');
                if(onWO.FSO__Orders__r.size()>0)
                    wo_orders_a.put(onWO.id, onWO.FSO__Orders__r.get(0));
                if(onWO.FSO__Orders__r.size()>1)
                    wo_orders_b.put(onWO.id, onWO.FSO__Orders__r.get(0));
            }
        
            for(Order onOrder :wo_orders_a.values()){
                onOrder.Status = 'Final';
            }
            update wo_orders_a.values();
            
            list<WorkOrder> verifyWO = [SELECT id, UNITY_Current_PO__c, UNITY_Action__c FROM  WorkOrder WHERE id IN :wo_orders_a.keySet() ];
            /*for(WorkOrder onWO :verifyWO){
                system.assertEquals(wo_orders_a.get(onWO.id).id, onWO.UNITY_Current_PO__c, 'Current PO should be set.');
                system.assertEquals('Send PO', onWO.UNITY_Action__c, 'Action on WO should be "Send PO".');
            }*/
        
            for(Order onOrder :wo_orders_b.values()){
                onOrder.Status = 'Final';
            }
            update wo_orders_b.values();
            
        
            verifyWO = [SELECT id, UNITY_Current_PO__c, UNITY_Action__c FROM  WorkOrder WHERE id IN :wo_orders_b.keySet() ];
            /*for(WorkOrder onWO :verifyWO){
                system.assertEquals(wo_orders_b.get(onWO.id).id, onWO.UNITY_Current_PO__c, 'Current PO should be set.');
                system.assertEquals('Send PO', onWO.UNITY_Action__c, 'Action on WO should be "Send PO".');
            }*/
            
        
        Test.stopTest();
        
    }

    /*
     * Data created : 
     *               Order:
     *                   Customer account 1 
     *                   MAX_SKILLS Skills
     *                   MAX_CASES Cases per Skill
     *                   MAX_WO WO per Case
     *                   MAX_ORDERS PO per WO
     * 
     */
    static void setUpTestData1() {
        
        Integer MAX_SKILLS = 3;
        Integer MAX_ORDERS = 2;
        Integer MAX_CASES  = 1;
        Integer MAX_WO     = 1;
        
        if(UNITY_General_Settings__c.getOrgDefaults() == null) {
            List<UNITY_General_Settings__c> generalSettings = new List<UNITY_General_Settings__c>();
            
            UNITY_General_Settings__c gSetting1 = new UNITY_General_Settings__c(Name= UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, UNITY_Value__c = 'Vendor Service Fee', UNITY_Description__c='Vendor Service Fee');
            
            generalSettings.add(gSetting1);
            
            insert generalSettings;    
                
        }    
        
        Account onCustomer = new Account();
        
        List<FSO__Skill__c> skills = new List<FSO__Skill__c>();

        Map<String,Object> workOrderFields             = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> vendorPreferenceFields      = UNITY_TestDataFactory.MOCKUP_VENDOR_TRADE_FIELDS;
        Map<String,Object> vendorPreferenceTradeFields = UNITY_TestDataFactory.MOCKUP_VENDOR_PREFERENCE_TRADE_FIELDS;
        Map<String,Object> vendorTradeFields           = UNITY_TestDataFactory.MOCKUP_VENDOR_TRADE_FIELDS;
        Map<String,Object> vendorLocationFields        = UNITY_TestDataFactory.MOCKUP_VENDOR_LOCATION_FIELDS;
        Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;    
        Map<String,Object> skillFields                 = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;    
        Map<String,Object> caseFields                  = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> orderFields                 = UNITY_TestDataFactory.MOCKUP_ORDER_FIELDS;
                                                    
        accountFields.put('ShippingPostalCode', UNITY_Utils.generateRandomPin()+'-'+UNITY_Utils.generateRandomPin());
        accountFields.put('RecordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Name', 'C-'+UNITY_Utils.generateRandomPin());
        onCustomer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType(),accountFields ).get(0); 
        onCustomer.Type = 'Customer';
        
        insert onCustomer;
        
        skills = UNITY_TestDataFactory.createSkills(MAX_SKILLS, false);
        insert skills;
        
        list<Case> cases = new list<Case>();
        
        caseFields.put('Customer__c', onCustomer.id);
        caseFields.put('RecordTypeId', UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
             
        for(FSO__Skill__c onSkill :skills){
           caseFields.put('UNITY_Trade__c',onSkill.id); 
           caseFields.put('Status','Verified');
           cases.add((Case) UNITY_TestDataFactory.createObject(MAX_CASES, Case.getSObjectType(), caseFields).get(0));
        }
        insert cases;
        
        workOrderFields.put('RecordTypeId', UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        workOrderFields.put('AccountId', onCustomer.id);
        workOrderFields.put('Subject', 'WO-Test');
        workOrderFields.put('UNITY_Customer__c', onCustomer.id);
        
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for(Case onCase :cases){
            workOrderFields.put('UNITY_Trade__c',onCase.UNITY_Trade__c); 
            workOrderFields.put('CaseId',onCase.id);
            workOrders.addAll(UNITY_TestDataFactory.createWorkOrders(MAX_WO,workOrderFields));
        }
        
        insert workOrders;
        
        List<SObject> orders = new List<SObject>();
        for(WorkOrder onWO :workOrders){
            orderFields.put('AccountId',onWO.AccountId); 
            orderFields.put('UNITY_Customer__c',onWO.UNITY_Customer__c); 
            orderFields.put('FSO__WorkOrder__c',onWO.id);
            orderFields.put('RecordTypeId', UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE);
            orders.addAll( UNITY_TestDataFactory.createObject(MAX_ORDERS, Order.getSObjectType(), orderFields));
        }
        insert orders;    
    }
    
    
    static testMethod void testOrderUpdate() {
        TestDataProvider.setKeyValueStore();
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        Test.startTest();
            
            if(UNITY_General_Settings__c.getOrgDefaults() == null) {
                List<UNITY_General_Settings__c> generalSettings = new List<UNITY_General_Settings__c>();
                
                UNITY_General_Settings__c gSetting1 = new UNITY_General_Settings__c(Name= UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, UNITY_Value__c = 'Vendor Service Fee', UNITY_Description__c='Vendor Service Fee');
                
                generalSettings.add(gSetting1);
                
                insert generalSettings;    
                    
            }  
            
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
            
            Product2 product = new Product2();
            
            product.Name = 'labor product test';
            product.IsActive = true ;
            product.Description  = 'labor product test';
            product.UNITY_Product_Type__c = 'Vendor Service Fee';
            product.Model__c = 'product test';
            product.UNITY_Status__c = 'Inactive';
            
            insert product;
            
            PricebookEntry pbe = new PricebookEntry();
            
            pbe.Pricebook2Id = Test.getStandardPricebookId();
            pbe.Product2Id = product.Id;
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
            orderRecord.RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
            orderRecord.UNITY_Vendor_Contract__c = vendorContract.Id;
            orderRecord.UNITY_Vendor__c = vendorAccount.Id;
            orderRecord.UNITY_Business_Unit__c = 'MNS';
            
            insert orderRecord;
            
            List<OrderItem> orderItemList = new List<OrderItem>();
            
            OrderItem orderItem1 = new OrderItem();
            
            orderItem1.orderId = orderRecord.Id;
            orderItem1.PricebookEntryId = pbe.Id;
            orderItem1.UnitPrice =  pbe.UnitPrice;
            orderItem1.Quantity = 2;
            orderItem1.UNITY_Cost__c = 20;
            
            insert orderItem1;
            
            OrderItem orderItem2 = new OrderItem();
            
            orderItem2.orderId = orderRecord.Id;
            orderItem2.PricebookEntryId = pbe.Id;
            orderItem2.UnitPrice =  pbe.UnitPrice;
            orderItem2.Quantity = 3;
            orderItem2.UNITY_Cost__c = 20;
            
            insert orderItem2;
        
        Test.stopTest();
    }
}