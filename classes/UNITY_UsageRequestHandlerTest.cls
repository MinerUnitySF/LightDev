@isTest
public with sharing class UNITY_UsageRequestHandlerTest {
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
        
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 6;
        Integer MAX_ORDERS = 2;
        
        TestDataProvider.setKeyValueStore();
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        
        Map<String,Object> orderFields = UNITY_TestDataFactory.MOCKUP_ORDER_FIELDS;

        //if(UNITY_General_Settings__c.getAll().values()!=null){
            
            //List<UNITY_General_Settings__c> generalSettings = new List<UNITY_General_Settings__c>();
            
            //UNITY_General_Settings__c gSetting1 = new UNITY_General_Settings__c(Name= UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, UNITY_Value__c = 'Vendor Service Fee', UNITY_Description__c='Vendor Service Fee');
            
            //generalSettings.add(gSetting1);
            
            //insert generalSettings;
        //}
        
        List<Product2> productList = new List<Product2>();
        
        Product2 partProduct = new Product2();
        partProduct.Name = 'part product test';
        partProduct.IsActive = true ;
        partProduct.Description  = 'part product test';
        partProduct.UNITY_Product_Type__c = 'Part';
        partProduct.Model__c = 'part test';
        partProduct.UNITY_Status__c = 'Inactive';
        
        productList.add(partProduct);
        
        Product2 laborProduct = new Product2();
        laborProduct.Name = 'labor product test';
        laborProduct.IsActive = true ;
        laborProduct.Description  = 'labor product test';
        laborProduct.UNITY_Product_Type__c = 'Labor';
        laborProduct.Model__c = 'product test';
        laborProduct.UNITY_Status__c = 'Inactive';
        
        productList.add(laborProduct);
        
        Product2 travelProduct = new Product2();
        travelProduct.Name = 'travel product test';
        travelProduct.IsActive = true ;
        travelProduct.Description  = 'travel product test';
        travelProduct.UNITY_Product_Type__c = 'Travel';
        travelProduct.Model__c = 'travel test';
        travelProduct.UNITY_Status__c = 'Inactive';
        
        productList.add(travelProduct);
        
        insert productList;
        
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        
        PricebookEntry pbe1 = new PricebookEntry();
        
        pbe1.Pricebook2Id = Test.getStandardPricebookId();
        pbe1.Product2Id = partProduct.Id;
        pbe1.UnitPrice = 80;
        
        pbeList.add(pbe1);
        
        PricebookEntry pbe2 = new PricebookEntry();
        
        pbe2.Pricebook2Id = Test.getStandardPricebookId();
        pbe2.Product2Id = laborProduct.Id;
        pbe2.UnitPrice = 100;
        
        pbeList.add(pbe2);
        
        PricebookEntry pbe3 = new PricebookEntry();
        
        pbe3.Pricebook2Id = Test.getStandardPricebookId();
        pbe3.Product2Id = travelProduct.Id;
        pbe3.UnitPrice = 30;
        
        pbeList.add(pbe3);
        
        insert pbeList;
         
        UNITY_Template_Configuration__c parentTemplate = new UNITY_Template_Configuration__c ();
        
        parentTemplate.RecordTypeId = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        parentTemplate.UNITY_Template_Parent__c = null;
        parentTemplate.Name = 'Test PO';
        
        insert parentTemplate;
        
        List<UNITY_Template_Configuration__c> childTemplate = new List<UNITY_Template_Configuration__c>();
        
        UNITY_Template_Configuration__c childTemplate1 = new UNITY_Template_Configuration__c ();
        
        childTemplate1.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        childTemplate1.UNITY_Template_Parent__c = parentTemplate.Id;
        childTemplate1.Name                     = 'Test POLI';
        childTemplate1.UNITY_Node_Value__c      = '1';
        childTemplate1.UNITY_Target_Object__c   = 'OrderItem';
        childTemplate1.UNITY_Part_Lookup__c     = partProduct.id;
        
        childTemplate.add(childTemplate1);
        
        UNITY_Template_Configuration__c childTemplate2 = new UNITY_Template_Configuration__c ();
        
        childTemplate2.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        childTemplate2.UNITY_Template_Parent__c = parentTemplate.Id;
        childTemplate2.Name                     = 'Test POLI';
        childTemplate2.UNITY_Node_Value__c      = '10';
        childTemplate2.UNITY_Target_Object__c   = 'OrderItem';
        childTemplate2.UNITY_Part_Lookup__c     = laborProduct.id;
        
        childTemplate.add(childTemplate2);
        
        UNITY_Template_Configuration__c childTemplate3 = new UNITY_Template_Configuration__c ();
        
        childTemplate3.RecordTypeId             = UNITY_Constants.TEMPLATE_CONFIG_PURCHASE_ORDER_RECORDTYPE;
        childTemplate3.UNITY_Template_Parent__c = parentTemplate.Id;
        childTemplate3.Name                     = 'Test POLI';
        childTemplate3.UNITY_Node_Value__c      = '3';
        childTemplate3.UNITY_Target_Object__c   = 'OrderItem';
        childTemplate3.UNITY_Part_Lookup__c     = travelProduct.id;
        
        childTemplate.add(childTemplate3);
        
        insert childTemplate;
        

        List<Account> accountList = new List<Account>();
        
        Account newAccount1 = new Account();
        
        newAccount1.RecordTypeId  = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        newAccount1.Name = 'Test Customer Account';
        newAccount1.Type = 'Site/Location';
        newAccount1.BillingCity = 'Brooklyn';
        newAccount1.BillingStateCode = 'NY';
        newAccount1.BillingStreet = '123 Fake St.';
        newAccount1.BillingPostalCode = '123456';
        newAccount1.Account_Status__c = 'Active';
        accountList.add(newAccount1);
        
        Account newAccount2 = new Account();
        
        newAccount2.RecordTypeId  = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        newAccount2.Name = 'Test Vendor Account';
        newAccount2.Type = 'Site/Location';
        newAccount2.BillingCity = 'Brooklyn';
        newAccount2.BillingStateCode = 'NY';
        newAccount2.BillingStreet = '123 Fake St.';
        newAccount2.BillingPostalCode = '123456';
        newAccount2.Account_Status__c = 'Active';
        
        accountList.add(newAccount2);
        
        insert accountList;
        
        Contact newContact = new Contact();
        
        newContact.LastName = 'Test';
        newContact.AccountId = newAccount1.Id;
        insert newContact;

        
        FSO__Skill__c skill = new FSO__Skill__c();
        skill.Name = 'Test Skill';
        
        insert skill;

        
        List<UNITY_Service_Contract__c> serviceContractList = new List<UNITY_Service_Contract__c>();
        
        List<UNITY_Service_Contract_Line_Item__c> serviceContractLineItemList = new List<UNITY_Service_Contract_Line_Item__c>();
        
        UNITY_Service_Contract__c serviceContract1 = new UNITY_Service_Contract__c();
        
        serviceContract1.UNITY_Account__c = newAccount1.Id;
        serviceContract1.UNITY_Trip_Charge__c = 10;
        serviceContract1.UNITY_Trip_Charge_Type__c = 'Hourly Rate';
        serviceContract1.UNITY_Default_Labor_Rate__c = 75;
        serviceContract1.UNITY_Invoicing_Increments__c = 'Next ¼ hr';
        serviceContract1.UNITY_Business_Unit__c = 'MNS';
        serviceContract1.UNITY_IS_Active__c = true;
        serviceContract1.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        
        serviceContractList.add(serviceContract1);
 
         UNITY_Service_Contract__c serviceContract2 = new UNITY_Service_Contract__c();
        
        serviceContract2.UNITY_Account__c = newAccount2.Id;
        serviceContract2.UNITY_Trip_Charge__c = 10;
        serviceContract2.UNITY_Trip_Charge_Type__c = 'Hourly Rate';
        serviceContract2.UNITY_Default_Labor_Rate__c = 75;
        serviceContract2.UNITY_Invoicing_Increments__c = 'Next ¼ hr';
        serviceContract2.UNITY_Business_Unit__c = 'MNS';
        serviceContract2.UNITY_IS_Active__c = true;
        serviceContract2.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        
        serviceContractList.add(serviceContract2);
        
        insert serviceContractList;

        
        UNITY_Service_Contract_Line_Item__c serviceContractLI1 = new UNITY_Service_Contract_Line_Item__c();
        
        serviceContractLI1.UNITY_Trade__c = skill.Id;
        serviceContractLI1.UNITY_Labor_Cost__c = 100;
        serviceContractLI1.UNITY_Service_Contract__c = serviceContract1.Id;
        serviceContractLI1.RecordTypeId = UNITY_Constants.SCLI_HOURLY_RATE_RECORDTYPE;
        
        serviceContractLineItemList.add(serviceContractLI1);
        
        UNITY_Service_Contract_Line_Item__c serviceContractLI2 = new UNITY_Service_Contract_Line_Item__c();
        
        serviceContractLI2.UNITY_Product__c = partProduct.Id;
        serviceContractLI2.UNTIY_Material_Cost__c = 1000;
        serviceContractLI2.UNITY_Service_Contract__c = serviceContract1.Id;
        serviceContractLI1.RecordTypeId = UNITY_Constants.SCLI_PRODUCT_PRICING_RECORDTYPE;

        UNITY_Service_Contract_Line_Item__c serviceContractLI3 = new UNITY_Service_Contract_Line_Item__c();
        
        serviceContractLI3.UNITY_Trade__c = skill.Id;
        serviceContractLI3.UNITY_Labor_Cost__c = 100;
        serviceContractLI3.UNITY_Service_Contract__c = serviceContract2.Id;
        serviceContractLI3.RecordTypeId = UNITY_Constants.SCLI_HOURLY_RATE_RECORDTYPE;
        
        serviceContractLineItemList.add(serviceContractLI3);
        
        UNITY_Service_Contract_Line_Item__c serviceContractLI4 = new UNITY_Service_Contract_Line_Item__c();
        
        serviceContractLI4.UNITY_Product__c = partProduct.Id;
        serviceContractLI4.UNTIY_Material_Cost__c = 1000;
        serviceContractLI4.UNITY_Service_Contract__c = serviceContract2.Id;
        serviceContractLI4.RecordTypeId = UNITY_Constants.SCLI_PRODUCT_PRICING_RECORDTYPE;
        
        serviceContractLineItemList.add(serviceContractLI4);
        
        insert serviceContractLineItemList;

        
        Case newCase = new Case();
        
        newCase.RecordTypeId = UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE;
        newCase.Subject = 'Test Subject';
        newCase.AccountId = newAccount1.Id;
        newCase.ContactId = newContact.Id;
        newCase.UNITY_Customer__c = newAccount1.Id;
        newCase.UNITY_Business_Unit__c = 'MNS';
        newCase.Status = 'Verified';
        newCase.UNITY_NTE_Threshold__c = 2000;
        
        insert newCase;


        WorkOrder newWorkOrder = new WorkOrder();
       
        newWorkOrder.CaseId = newCase.Id;
        newWorkOrder.Subject = 'test WO';
        newWorkOrder.AccountId = newCase.AccountId;
        newWorkOrder.UNITY_Customer__c = newCase.AccountId;
        newWorkOrder.UNITY_Customer_Service_Contract__c = serviceContract1.Id;
        newWorkOrder.UNITY_Assigned_Vendor__c = newAccount2.Id;
        newWorkOrder.UNITY_Business_Unit__c = 'MNS';
        newWorkOrder.UNITY_Business_Unit_Account__c = newAccount2.Id;
        newWorkOrder.UNITY_Vendor_Contract__c = serviceContract2.Id;
        newWorkOrder.ContactId = newContact.Id;
        newWorkOrder.UNITY_Agent__c = UserInfo.getUserId();
        newWorkOrder.UNITY_Trade__c = skill.Id;
        newWorkOrder.UNITY_Work_Window_Begin__c = DateTime.now();
        newWorkOrder.UNITY_Work_Window_End__c   = DateTime.now().addDays(5);

        insert newWorkOrder;
        
        System.debug('#newWorkOrder '+newWorkOrder);

    }
    
    static testMethod void createPOFromUsageRequestTest() {
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 6;
        
        WorkOrder wo = [select id,AccountId,UNITY_Customer__c,UNITY_Assigned_Vendor__c from WorkOrder where Subject = 'test WO'];
        
        Order orderRecord1 = new Order();
        Order orderRecord2 = new Order();
        List<Order> orderList = new List<Order>();
        
        orderRecord1.FSO__WorkOrder__c = wo.Id;
        orderRecord1.AccountId = wo.AccountId;
        orderRecord1.UNITY_Customer__c = wo.UNITY_Customer__c;
        orderRecord1.EffectiveDate = Date.today();
        orderRecord1.Status = 'Draft';
        orderRecord1.RecordTypeId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        orderRecord1.UNITY_Vendor__c = wo.UNITY_Assigned_Vendor__c;
        orderRecord1.UNITY_Business_Unit__c = 'MNS';
        //orderRecord1.Pricebook2Id = Test.getStandardPriceBookId();
        orderList.add(orderRecord1);
        
        orderRecord2.FSO__WorkOrder__c = wo.Id;
        orderRecord2.AccountId = wo.AccountId;
        orderRecord2.UNITY_Customer__c = wo.UNITY_Customer__c;
        orderRecord2.EffectiveDate = Date.today();
        orderRecord2.Status = 'Draft';
        orderRecord2.RecordTypeId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        orderRecord2.UNITY_Vendor__c = wo.UNITY_Assigned_Vendor__c;
        orderRecord2.UNITY_Business_Unit__c = 'MNS';
        //orderRecord1.Pricebook2Id = Test.getStandardPriceBookId();
        orderList.add(orderRecord2);
        
        insert orderList;
        
        PricebookEntry pbe1 = [select Id, UnitPrice from PricebookEntry where product2.Name = 'part product test'];
        PricebookEntry pbe2 = [select Id, UnitPrice from PricebookEntry where product2.Name = 'Labor product test'];
        PricebookEntry pbe3 = [select Id, UnitPrice from PricebookEntry where product2.Name = 'Travel product test'];
        
        List<OrderItem> orderItemList = new List<OrderItem>();
        OrderItem orderItem1 = new OrderItem();
        orderItem1.orderId = orderRecord1.Id;
        orderItem1.PricebookEntryId = pbe1.Id;
        orderItem1.UnitPrice =  pbe1.UnitPrice;
        orderItem1.Quantity = 1;
        orderItemList.add(orderItem1);
        
        OrderItem orderItem2 = new OrderItem();
        orderItem2.orderId = orderRecord2.Id;
        orderItem2.PricebookEntryId = pbe1.Id;
        orderItem2.UnitPrice =  pbe1.UnitPrice;
        orderItem2.Quantity = 10;
        orderItemList.add(orderItem2);
        
        OrderItem orderItem3 = new OrderItem();
        orderItem3.orderId = orderRecord2.Id;
        orderItem3.PricebookEntryId = pbe2.Id;
        orderItem3.UnitPrice =  pbe2.UnitPrice;
        orderItem3.Quantity = 2;
        orderItem1.UNITY_Is_Vendor_Supply__c = true;
        orderItemList.add(orderItem3);
        
        OrderItem orderItem4 = new OrderItem();
        orderItem4.orderId = orderRecord2.Id;
        orderItem4.PricebookEntryId = pbe3.Id;
        orderItem4.UnitPrice =  pbe3.UnitPrice;
        orderItem4.Quantity = 2;
        orderItem1.UNITY_Is_Vendor_Supply__c = true;
        orderItemList.add(orderItem4);
        
        insert orderItemList;
            
        Test.startTest();
        
        Case testCase = [Select Id, UNITY_Total_Price__c, UNITY_NTE_Threshold__c from Case where Subject = 'Test Subject'];
        system.debug('@@: case : '+testCase);
        testCase.UNITY_Total_Price__c = 1500;
        update testCase;
        Order lowOrder = [Select Id, UNITY_Total_Amount__c from Order where Id =:orderRecord1.Id];
        
        
        Order highOrder = [Select Id, UNITY_Total_Amount__c from Order where Id =:orderRecord2.Id];
        system.debug('@@: lowOrder : '+lowOrder);
        system.debug('@@: highOrder : '+highOrder);
        
        
        Map<String,String> eNTE = UNITY_UsageRequestHandler.createPOFromUsageRequest2(orderRecord1.Id);
        if(eNTE.get('result') == 'false'){
            UNITY_UsageRequestHandler.createPurchaseOrders2(orderRecord1.Id);
            
        }
        //testCase.UNITY_Total_Price__c = 100;
        //update testCase;
        eNTE = UNITY_UsageRequestHandler.createPOFromUsageRequest2(orderRecord2.Id);
        if(eNTE.get('result') == 'false'){
            UNITY_UsageRequestHandler.createPurchaseOrders2(orderRecord2.Id);
            UNITY_UsageRequestHandler.getIncurredCharges(testCase.Id,false);
            UNITY_UsageRequestHandler.getIncurredCharges(testCase.Id,true);
        }
        
        Test.stopTest();
    }
    
    static testMethod void createQuoteTest() {        
                                    
            UNITY_Constants.MAX_TRIGGER_EXECUTION = 6;
        
            WorkOrder wo = [select id,AccountId, UNITY_Case__c, UNITY_Customer__c,UNITY_Assigned_Vendor__c from WorkOrder where Subject = 'test WO'];
            
            Order orderRecord1 = new Order();
            Order orderRecord2 = new Order();
            List<Order> orderList = new List<Order>();
            
            orderRecord1.FSO__WorkOrder__c = wo.Id;
            orderRecord1.AccountId = wo.AccountId;
            orderRecord1.UNITY_Customer__c = wo.UNITY_Customer__c;
            orderRecord1.EffectiveDate = Date.today();
            orderRecord1.Status = 'Draft';
            orderRecord1.RecordTypeId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
            orderRecord1.UNITY_Vendor__c = wo.UNITY_Assigned_Vendor__c;
            orderRecord1.UNITY_Business_Unit__c = 'MNS';
            //orderRecord1.Pricebook2Id = Test.getStandardPriceBookId();
            orderList.add(orderRecord1);

            orderRecord2.FSO__WorkOrder__c = wo.Id;
            orderRecord2.AccountId = wo.AccountId;
            orderRecord2.UNITY_Customer__c = wo.UNITY_Customer__c;
            orderRecord2.EffectiveDate = Date.today();
            orderRecord2.Status = 'Draft';
            orderRecord2.RecordTypeId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
            orderRecord2.UNITY_Vendor__c = wo.UNITY_Assigned_Vendor__c;
            orderRecord2.UNITY_Business_Unit__c = 'MNS';
            //orderRecord2.Pricebook2Id = Test.getStandardPriceBookId();
            orderList.add(orderRecord2);
                        
            insert orderList;
            
            PricebookEntry pbe1 = [select Id, UnitPrice from PricebookEntry where product2.Name = 'part product test'];
            PricebookEntry pbe2 = [select Id, UnitPrice from PricebookEntry where product2.Name = 'Labor product test'];
            PricebookEntry pbe3 = [select Id, UnitPrice from PricebookEntry where product2.Name = 'Travel product test'];
            
            List<OrderItem> orderItemList = new List<OrderItem>();
            OrderItem orderItem1 = new OrderItem();
            orderItem1.orderId = orderRecord1.Id;
            orderItem1.PricebookEntryId = pbe1.Id;
            orderItem1.UnitPrice =  pbe1.UnitPrice;
            orderItem1.Quantity = 1;
            orderItemList.add(orderItem1);
            
            OrderItem orderItem2 = new OrderItem();
            orderItem2.orderId = orderRecord2.Id;
            orderItem2.PricebookEntryId = pbe1.Id;
            orderItem2.UnitPrice =  pbe1.UnitPrice;
            orderItem2.Quantity = 10;
            orderItemList.add(orderItem2);
            
            OrderItem orderItem3 = new OrderItem();
            orderItem3.orderId = orderRecord2.Id;
            orderItem3.PricebookEntryId = pbe2.Id;
            orderItem3.UnitPrice =  pbe2.UnitPrice;
            orderItem3.Quantity = 2;
            orderItemList.add(orderItem3);
            
            OrderItem orderItem4 = new OrderItem();
            orderItem4.orderId = orderRecord2.Id;
            orderItem4.PricebookEntryId = pbe3.Id;
            orderItem4.UnitPrice =  pbe3.UnitPrice;
            orderItem4.Quantity = 2;
            orderItemList.add(orderItem4);
            
            insert orderItemList;
            
        Test.startTest();

        orderRecord1 = [select id,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Business_Unit__c,UNITY_Vendor__c,FSO__WorkOrder__r.CaseId,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__c,
                        FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Is_Pass_Through__c,FSO__WorkOrder__r.Case.UNITY_Customer_Service_Contract__r.UNITY_Contract_Sub_type__c,FSO__WorkOrder__r.UNITY_Customer__r.Account_Email__c,FSO__WorkOrder__r.UNITY_Agent__c,FSO__WorkOrder__r.UNITY_Customer_Margin__c ,
                        FSO__WorkOrder__r.UNITY_Customer__c,UNITY_NTE_Exceeded__c,UNITY_Total_Amount__c,UNITY_Business_Unit_Account__c,Status, FSO__WorkOrder__c,UNITY_Total_Cost__c,AccountId,EffectiveDate,
                        Description,UNITY_Shipping_Method__c,UNITY_Shipping_Provider__c,UNITY_Ship_To_Account__c,ShipToContactId,UNITY_Parts_Needed_By__c,UNITY_Expected_Arrival_Date__c,
                        ShippingStreet,ShippingCity,ShippingState,ShippingStateCode,ShippingPostalCode,ShippingCountry, ShippingCountryCode, UNITY_Actual_Arrival_Date__c,UNITY_Tracking_Number__c 
                        from Order where id =:orderRecord1.Id];
            
        UNITY_UsageRequestHandler.currentOrderItemList = orderItemList;
        
        UNITY_UsageRequestHandler.currentOrder = orderRecord1;
        String urId = orderRecord1.Id;
        Map<String,String> result = UNITY_UsageRequestHandler.createQuote2(urId);
        //UNITY_UsageRequestHandler.createQuoteLineItems(proposal.Id, orderItemList);
        UNITY_UsageRequestHandler.processUsageRequestPartVendorIdentified(orderList);
        
        Map<String,String> resultForBlankId = UNITY_UsageRequestHandler.createQuote2('');
        System.Assert(resultForBlankId.get('success')=='false');

        Test.stopTest();        
    }
    
    static testMethod void createPOFromUsageRequestNonWorkTest() {
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 6;
        
        WorkOrder wo = [select id,AccountId,UNITY_Customer__c,UNITY_Assigned_Vendor__c,RecordTypeId from WorkOrder where Subject = 'test WO'];
        wo.RecordTypeId = UNITY_Constants.WO_NON_WORK_RECORDTYPE;
        update wo;
        Order orderRecord1 = new Order();
        Order orderRecord2 = new Order();
        List<Order> orderList = new List<Order>();
        
        orderRecord1.FSO__WorkOrder__c = wo.Id;
        orderRecord1.AccountId = wo.AccountId;
        orderRecord1.UNITY_Customer__c = wo.UNITY_Customer__c;
        orderRecord1.EffectiveDate = Date.today();
        orderRecord1.Status = 'Draft';
        orderRecord1.RecordTypeId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        orderRecord1.UNITY_Vendor__c = wo.UNITY_Assigned_Vendor__c;
        orderRecord1.UNITY_Business_Unit__c = 'MNS';
        //orderRecord1.Pricebook2Id = Test.getStandardPriceBookId();
        orderList.add(orderRecord1);
        
        orderRecord2.FSO__WorkOrder__c = wo.Id;
        orderRecord2.AccountId = wo.AccountId;
        orderRecord2.UNITY_Customer__c = wo.UNITY_Customer__c;
        orderRecord2.EffectiveDate = Date.today();
        orderRecord2.Status = 'Draft';
        orderRecord2.RecordTypeId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        orderRecord2.UNITY_Vendor__c = wo.UNITY_Assigned_Vendor__c;
        orderRecord2.UNITY_Business_Unit__c = 'MNS';
        //orderRecord1.Pricebook2Id = Test.getStandardPriceBookId();
        orderList.add(orderRecord2);
        
        insert orderList;
        
        PricebookEntry pbe1 = [select Id, UnitPrice from PricebookEntry where product2.Name = 'part product test'];
        //PricebookEntry pbe2 = [select Id, UnitPrice from PricebookEntry where product2.Name = 'Labor product test'];
        //PricebookEntry pbe3 = [select Id, UnitPrice from PricebookEntry where product2.Name = 'Travel product test'];
        
        List<OrderItem> orderItemList = new List<OrderItem>();
        OrderItem orderItem1 = new OrderItem();
        orderItem1.orderId = orderRecord1.Id;
        orderItem1.PricebookEntryId = pbe1.Id;
        orderItem1.UnitPrice =  pbe1.UnitPrice;
        orderItem1.Quantity = 1;
        orderItem1.UNITY_Part_Source__c = wo.UNITY_Assigned_Vendor__c;
        orderItemList.add(orderItem1);
        
        OrderItem orderItem2 = new OrderItem();
        orderItem2.orderId = orderRecord2.Id;
        orderItem2.PricebookEntryId = pbe1.Id;
        orderItem2.UnitPrice =  pbe1.UnitPrice;
        orderItem2.Quantity = 10;
        orderItemList.add(orderItem2);
        
        insert orderItemList;
            
        Test.startTest();
        
        Case testCase = [Select Id, UNITY_Total_Price__c, UNITY_NTE_Threshold__c from Case where Subject = 'Test Subject'];
        system.debug('@@: case : '+testCase);
        testCase.UNITY_Total_Price__c = 1500;
        update testCase;
        Order lowOrder = [Select Id, UNITY_Total_Amount__c from Order where Id =:orderRecord1.Id];
        
        
        Order highOrder = [Select Id, UNITY_Total_Amount__c from Order where Id =:orderRecord2.Id];
        system.debug('@@: lowOrder : '+lowOrder);
        system.debug('@@: highOrder : '+highOrder);
        
        
        Map<String,String> eNTE = UNITY_UsageRequestHandler.createPOFromUsageRequest2(orderRecord1.Id);
        if(eNTE.get('result') == 'false'){
            UNITY_UsageRequestHandler.createPurchaseOrders2(orderRecord1.Id);
            UNITY_UsageRequestHandler.updateUsageRequestStatus(orderRecord1.Id, 'PO Created');
        }
        //testCase.UNITY_Total_Price__c = 100;
        //update testCase;
        eNTE = UNITY_UsageRequestHandler.createPOFromUsageRequest2(orderRecord2.Id);
        if(eNTE.get('result') == 'false'){
            UNITY_UsageRequestHandler.createPurchaseOrders2(orderRecord2.Id);
        }
        
        Test.stopTest();
    }
    public static testMethod void testcalCulateServicveCharge(){
        Map<String,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();
        List<UNITY_General_Settings__c> gSettings =  new List<UNITY_General_Settings__c>();
        if(!generalSettings.KeySet().contains(UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY))
            gSettings.add(new UNITY_General_Settings__c(
                Name = UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, 
                UNITY_Value__c = 'Vendor Service Fee', 
                UNITY_Description__c='Vendor Service Fee'
            ));
        if(!generalSettings.KeySet().contains(UNITY_Constants.PO_INVOICEABLE_STATUSES))
            gSettings.add(new UNITY_General_Settings__c(
                Name = UNITY_Constants.PO_INVOICEABLE_STATUSES, 
                UNITY_Value__c = 'Final', 
                UNITY_Description__c='PO INVOICEABLE STATUS'
            ));
        if(!gSettings.isEmpty()) 
            insert gSettings;

        
        Case c = [SELECT Id, AccountId FROM Case Where Subject = 'Test Subject' LIMIT 1];
        
        UNITY_Service_Contract__c svc = [SELECT Id FROM UNITY_Service_Contract__c WHERE UNITY_Account__c = :c.AccountId];        
        svc.UNITY_Business_Unit__c = 'MNS';
        svc.UNITY_IS_Active__c = true;
        svc.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        svc.UNITY_Is_Pass_Through__c = true;
        update svc;

        FSO__Skill__c skill = new FSO__Skill__c();
        skill.Name = 'Test Skill';
        insert skill;
        
        
        List<UNITY_Service_Contract_Line_Item__c> scLIs = new List<UNITY_Service_Contract_Line_Item__c>();
        UNITY_Service_Contract_Line_Item__c scLI = new UNITY_Service_Contract_Line_Item__c();
        scLI.UNITY_Trade__c = skill.Id;
        scLI.UNITY_Labor_Cost__c = 100;
        scLI.UNITY_Service_Contract__c = svc.Id;
        scLI.RecordTypeId = UNITY_Constants.SCLI_SERVICE_CHARGE_RECORDTYPE;
        scLI.UNITY_Service_Charge_Percentage__c = 2;
        scLI.UNITY_Service_Charge_Amount__c = 10;
        scLI.UNITY_Threshold_Start__c = 100;
        scLI.UNITY_Threshold_End__c = 1000;
        scLIs.add(scLI);
        
        UNITY_Service_Contract_Line_Item__c scLI2 = new UNITY_Service_Contract_Line_Item__c();
        scLI2.UNITY_Trade__c = skill.Id;
        scLI2.UNITY_Labor_Cost__c = 100;
        scLI2.UNITY_Service_Contract__c = svc.Id;
        scLI2.RecordTypeId = UNITY_Constants.SCLI_SERVICE_CHARGE_RECORDTYPE;
        scLI2.UNITY_Service_Charge_Percentage__c = 2;
        scLI2.UNITY_Service_Charge_Amount__c = 10;
        scLI2.UNITY_Threshold_Start__c = 100;
        scLI2.UNITY_Threshold_End__c = 1000;
        scLIs.add(scLI2);
        insert scLIs;
        
        c.UNITY_Customer_Service_Contract__c = svc.Id;
        update c;
        
        WorkOrder wo = [select id,AccountId,UNITY_Customer__c,UNITY_Assigned_Vendor__c from WorkOrder where Subject = 'test WO'];
        wo.Status = 'New';
        
        List<Order> orderList = new List<Order>();
        
        Order order1 = new Order();
        order1.FSO__WorkOrder__c = wo.Id;
        order1.AccountId = wo.AccountId;
        order1.UNITY_Customer__c = wo.UNITY_Customer__c;
        order1.EffectiveDate = Date.today();
        order1.Status = 'Draft';
        order1.RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        order1.UNITY_Vendor__c = wo.UNITY_Assigned_Vendor__c;
        order1.UNITY_Business_Unit__c = 'MNS';
        orderList.add(order1);
        
        Order order2 = new Order();
        order2.FSO__WorkOrder__c = wo.Id;
        order2.AccountId = wo.AccountId;
        order2.UNITY_Customer__c = wo.UNITY_Customer__c;
        order2.EffectiveDate = Date.today();
        order2.Status = 'Final';
        order2.RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        order2.UNITY_Vendor__c = wo.UNITY_Assigned_Vendor__c;
        order2.UNITY_Business_Unit__c = 'MNS';
        order2.UNITY_Discount__c = 50;
        orderList.add(order2);
        insert orderList;

        Test.startTest();
        PricebookEntry pbe1 = [select Id, UnitPrice from PricebookEntry where product2.Name = 'part product test'];        
        
        OrderItem orderItem1 = new OrderItem();
        orderItem1.orderId = order2.Id;
        orderItem1.PricebookEntryId = pbe1.Id;
        orderItem1.UnitPrice =  pbe1.UnitPrice;
        orderItem1.Quantity = 1;
        orderItem1.UNITY_Part_Source__c = wo.UNITY_Assigned_Vendor__c;
        insert orderItem1;
        
        OrderItem orderItem2 = new OrderItem();
        orderItem2.orderId = order2.Id;
        orderItem2.PricebookEntryId = pbe1.Id;
        orderItem2.UnitPrice =  pbe1.UnitPrice;
        orderItem2.Quantity = 1;
        orderItem2.UNITY_Part_Source__c = wo.UNITY_Assigned_Vendor__c;
        orderItem2.UNITY_Is_Vendor_Supply__c = true;
        orderItem2.UNITY_Discount_Amount__c = 50;
        orderItem2.UNITY_Total_Price__c = 300;
        insert orderItem2;
        
        Map<String,String> eNTE = UNITY_UsageRequestHandler.createPOFromUsageRequest2(order1.Id);
        
        Decimal serviceCharge = UNITY_UsageRequestHandler.calculateServicveCharge(svc.Id, 250, 0);
        Test.stopTest();
        
        System.Assert(serviceCharge == 10);     
    }
}