@isTest
public class UNITY_CallAvatax_UT{
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
    public static void testSetup(){
        TestDataProvider.unityTestSetup();
    }
    
    public static TestMethod void test1(){
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String oRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        List<Account> accounts = [SELECT Id,RecordTypeId FROM Account];
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
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        
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
        insert wo;
        
        //Create order
        Order o = new Order();
        o.RecordTypeId = oRTId;
        o.AccountId = cust.Id;
        o.UNITY_Vendor__c = vend.Id;
        o.Type = 'Usage Request PO';
        o.UNITY_Business_Unit__c = 'NSBS';
        o.UNITY_Business_Unit_Account__c = bu.Id;
        o.Status = 'Draft';
        o.FSO__WorkOrder__c = wo.Id;
        o.EffectiveDate = Date.today();
        o.UNITY_NTE__c = 200;
        insert o;
        //Create order line items
        //1
        List<OrderItem> oLines = new List<Orderitem>();
        OrderItem oItem = new orderItem();
        oItem.OrderId = o.Id;
        oItem.PricebookEntryId = PRICEBOOKENTRYID_T;
        oItem.Quantity = 2;
        oItem.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem.UnitPrice = 10;
        oItem.UNITY_Activity_Type__c = 'Travel - Standard Labor';
        oItem.UNITY_Type__c = 'Travel';
        //2
        OrderItem oItem2 = new orderItem();
        oItem2.OrderId = o.Id;
        oItem2.PricebookEntryId = PRICEBOOKENTRYID_L;
        oItem2.Quantity = 2;
        oItem2.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem2.UnitPrice = 10;
        oItem2.UNITY_Activity_Type__c = 'Standard Labor';
        oItem2.UNITY_Type__c = 'Labor';
        //3
        OrderItem oItem3 = new orderItem();
        oItem3.OrderId = o.Id;
        oItem3.PricebookEntryId = PRICEBOOKENTRYID_T;
        oItem3.Quantity = 2;
        oItem3.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem3.UnitPrice = 10;
        oItem3.UNITY_Activity_Type__c = 'Travel - Overtime Labor';
        oItem3.UNITY_Type__c = 'Travel';
        //4
        OrderItem oItem4 = new orderItem();
        oItem4.OrderId = o.Id;
        oItem4.PricebookEntryId = PRICEBOOKENTRYID_T;
        oItem4.Quantity = 2;
        oItem4.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem4.UnitPrice = 10;
        oItem4.UNITY_Activity_Type__c = 'Overtime Labor';
        oItem4.UNITY_Type__c = 'Labor';
        //5
        OrderItem oItem5 = new orderItem();
        oItem5.OrderId = o.Id;
        oItem5.PricebookEntryId = PRICEBOOKENTRYID_T;
        oItem5.Quantity = 2;
        oItem5.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem5.UnitPrice = 10;
        oItem5.UNITY_Activity_Type__c = 'Use Tax';
        oItem5.UNITY_Type__c = 'Expenses';
        //6
        OrderItem oItem6 = new orderItem();
        oItem6.OrderId = o.Id;
        oItem6.PricebookEntryId = PRICEBOOKENTRYID_P;
        oItem6.Quantity = 2;
        oItem6.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem6.UnitPrice = 10;
        oItem6.UNITY_Activity_Type__c = 'Parts - Service and Remodel';
        oItem6.UNITY_Type__c = 'Parts';
        //7
        OrderItem oItem7 = new orderItem();
        oItem7.OrderId = o.Id;
        oItem7.PricebookEntryId = PRICEBOOKENTRYID_P;
        oItem7.Quantity = 2;
        oItem7.UnitPrice = 10;
        oItem7.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem7.UNITY_Activity_Type__c = 'Parts - New Construction';
        oItem7.UNITY_Type__c = 'Parts';
        //Insert the lines
        oLines.add(oItem);oLines.add(oItem2);oLines.add(oItem3);oLines.add(oItem4);oLines.add(oItem5);oLines.add(oItem6);oLines.add(oItem7);
        insert oLines;
        
        Set<Id> recordIds = new Set<Id>();
        //for(OrderItem itm :oLines){
            //recordIds.add(itm.Id);
        //}
        recordIds.add(o.Id);
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        
        UNITY_CallAvatax.AvataxResult result = UNITY_CallAvatax.getTaxPO(recordIds);
        System.debug('result.message: ' + result.message);
        UNITY_CallAvatax.getTaxCodePO(recordIds);
        
        Test.stopTest();
    }
    public static TestMethod void test1b(){
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String oRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        List<Account> accounts = [SELECT Id,RecordTypeId FROM Account];
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
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        
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
        insert wo;
        
        //Create order
        Order o = new Order();
        o.RecordTypeId = oRTId;
        o.AccountId = cust.Id;
        o.UNITY_Vendor__c = vend.Id;
        o.Type = 'Usage Request PO';
        o.UNITY_Business_Unit__c = 'NSBS';
        o.UNITY_Business_Unit_Account__c = bu.Id;
        o.Status = 'Draft';
        o.FSO__WorkOrder__c = wo.Id;
        o.EffectiveDate = Date.today();
        o.UNITY_NTE__c = 200;
        insert o;
        
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        
        UNITY_CallAvatax.AvataxResult result = UNITY_CallAvatax.getServiceChargeTax(cust.Id,bu.Id,null,100);
        System.debug('result.message: ' + result.message);
        
        Test.stopTest();
    }
    public static TestMethod void test2(){
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String oRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
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
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        
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
        insert wo;
        
        //Create order
        Order o = new Order();
        o.RecordTypeId = oRTId;
        o.AccountId = cust.Id;
        o.UNITY_Vendor__c = vend.Id;
        o.Type = 'Usage Request PO';
        o.UNITY_Business_Unit__c = 'NSBS';
        o.UNITY_Business_Unit_Account__c = bu.Id;
        o.Status = 'Draft';
        o.FSO__WorkOrder__c = wo.Id;
        o.EffectiveDate = Date.today();
        o.UNITY_NTE__c = 200;
        insert o;
        //Create order line items
        //1
        List<OrderItem> oLines = new List<Orderitem>();
        OrderItem oItem = new orderItem();
        oItem.OrderId = o.Id;
        oItem.PricebookEntryId = PRICEBOOKENTRYID_T;
        oItem.Quantity = 2;
        oItem.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem.UnitPrice = 10;
        oItem.UNITY_Activity_Type__c = 'Travel - Standard Labor';
        oItem.UNITY_Type__c = 'Travel';
        //2
        OrderItem oItem2 = new orderItem();
        oItem2.OrderId = o.Id;
        oItem2.PricebookEntryId = PRICEBOOKENTRYID_T;
        oItem2.Quantity = 2;
        oItem2.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem2.UnitPrice = 10;
        oItem2.UNITY_Activity_Type__c = 'Standard Labor';
        oItem2.UNITY_Type__c = 'Labor';
        //3
        OrderItem oItem3 = new orderItem();
        oItem3.OrderId = o.Id;
        oItem3.PricebookEntryId = PRICEBOOKENTRYID_T;
        oItem3.Quantity = 2;
        oItem3.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem3.UnitPrice = 10;
        oItem3.UNITY_Activity_Type__c = 'Travel - Overtime Labor';
        oItem3.UNITY_Type__c = 'Travel';
        //4
        OrderItem oItem4 = new orderItem();
        oItem4.OrderId = o.Id;
        oItem4.PricebookEntryId = PRICEBOOKENTRYID_L;
        oItem4.Quantity = 2;
        oItem4.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem4.UnitPrice = 10;
        oItem4.UNITY_Activity_Type__c = 'Overtime Labor';
        oItem4.UNITY_Type__c = 'Labor';
        //5
        OrderItem oItem5 = new orderItem();
        oItem5.OrderId = o.Id;
        oItem5.PricebookEntryId = PRICEBOOKENTRYID_P;
        oItem5.Quantity = 2;
        oItem5.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem5.UnitPrice = 10;
        oItem5.UNITY_Activity_Type__c = 'Use Tax';
        oItem5.UNITY_Type__c = 'Expenses';
        //6
        OrderItem oItem6 = new orderItem();
        oItem6.OrderId = o.Id;
        oItem6.PricebookEntryId = PRICEBOOKENTRYID_P;
        oItem6.Quantity = 2;
        oItem6.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem6.UnitPrice = 10;
        oItem6.UNITY_Activity_Type__c = 'Parts - Service and Remodel';
        oItem6.UNITY_Type__c = 'Parts';
        //7
        OrderItem oItem7 = new orderItem();
        oItem7.OrderId = o.Id;
        oItem7.PricebookEntryId = PRICEBOOKENTRYID_P;
        oItem7.Quantity = 2;
        oItem7.UnitPrice = 10;
        oItem7.UNITY_Customer_Adjusted_Quantity__c = 2;
        oItem7.UNITY_Activity_Type__c = 'Parts - New Construction';
        oItem7.UNITY_Type__c = 'Parts';
        //Insert the lines
        oLines.add(oItem);oLines.add(oItem2);oLines.add(oItem3);oLines.add(oItem4);oLines.add(oItem5);oLines.add(oItem6);oLines.add(oItem7);
        insert oLines;
        
        UNITY_Invoice__c invoice = new UNITY_Invoice__c();
        invoice.UNITY_Case__c = testCase.Id;
        invoice.UNITY_Customer__c = cust.Id;
        invoice.UNITY_Customer_Email__c = cust.Account_Email__c;
        invoice.UNITY_Status__c = 'Invoice Creation';
        //invoice.UNITY_Customer_Service_Contract__c = testCase.UNITY_Customer_Service_Contract__c;
        insert invoice;
        
        List<Id> recordIds = new List<Id>();
        List<UNITY_Invoice_Line_Item__c> invoiceLineItems = new List<UNITY_Invoice_Line_Item__c>();
        
        for(OrderItem oi :oLines){
            UNITY_Invoice_Line_Item__c ili = new UNITY_Invoice_Line_Item__c();
            ili.UNITY_Invoice__c = invoice.Id;
            ili.UNITY_Total_Price__c = 100;
            ili.UNITY_Cost__c = 50;
            ili.UNITY_Sales_Tax__c = null;
            ili.UNITY_PO_Price__c = 100; 
            ili.UNITY_Quantity__c = oi.Quantity;
            ili.UNITY_Adjusted_Quantity__c = oi.Quantity;
            ili.Product__c = PRODUCTID;
            ili.UNITY_Tax_Code__c = null;
            ili.UNITY_Is_Vendor_Supply__c = false;
            ili.UNITY_Activity_Type__c = oi.UNITY_Activity_Type__c;
            ili.UNITY_Type__c = oi.UNITY_Type__c;
            invoiceLineItems.add(ili);
        }
        insert invoiceLineItems;
        
        recordIds.add(invoice.Id);
        
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        UNITY_CallAvatax.getTaxInvoice(recordIds,true);
        UNITY_CallAvatax.cancelTaxInvoice(recordIds);

        Test.stopTest();
        
    }
    
    public static TestMethod void test3(){
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String qRTId = UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
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
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        
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
        insert wo;
        
        //Create quote
        UNITY_Proposal__c q = new UNITY_Proposal__c();
        q.RecordTypeId = qRTId;
        q.UNITY_Case__c = testCase.Id;
        q.UNITY_Account__c = cust.Id;
        q.UNITY_Customer__c = cust.Id;
        q.UNITY_Business_Unit__c = 'NSBS';
        q.UNITY_Business_Unit_Account__c = bu.Id;
        q.UNITY_Agent__c = UserInfo.getUserId();
        q.UNITY_Effective_Till_Date__c = (Date.today()+30);
        q.UNITY_Proposal_Status__c = 'Quote Creation';
        q.UNITY_Work_Order__c = wo.Id;
        insert q;
        //Create quote line items
        //1
        List<UNITY_Proposal_Line_Item__c> qLines = new List<UNITY_Proposal_Line_Item__c>();
        UNITY_Proposal_Line_Item__c qItem = new UNITY_Proposal_Line_Item__c();
        qItem.UNITY_Proposal__c = q.Id;
        qItem.UNITY_Quantity__c = 2;
        qItem.UNITY_Product__c = PRODUCTID;
        qItem.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem.UNITY_Cost__c = 10;
        qItem.UNITY_Price__c = 100;
        qItem.UNITY_Activity_Type__c = 'Travel - Standard Labor';
        qItem.UNITY_Type__c = 'Travel';
        //2
        UNITY_Proposal_Line_Item__c qItem2 = new UNITY_Proposal_Line_Item__c();
        qItem2.UNITY_Proposal__c = q.Id;
        qItem2.UNITY_Quantity__c = 2;
        qItem2.UNITY_Product__c = PRODUCTID;
        qItem2.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem2.UNITY_Cost__c = 10;
        qItem2.UNITY_Price__c = 100;
        qItem2.UNITY_Activity_Type__c = 'Standard Labor';
        qItem2.UNITY_Type__c = 'Labor';
        //3
        UNITY_Proposal_Line_Item__c qItem3 = new UNITY_Proposal_Line_Item__c();
        qItem3.UNITY_Proposal__c = q.Id;
        qItem3.UNITY_Quantity__c = 2;
        qItem3.UNITY_Product__c = PRODUCTID;
        qItem3.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem3.UNITY_Cost__c = 10;
        qItem3.UNITY_Price__c = 100;
        qItem3.UNITY_Activity_Type__c = 'Travel - Overtime Labor';
        qItem3.UNITY_Type__c = 'Travel';
        //4
        UNITY_Proposal_Line_Item__c qItem4 = new UNITY_Proposal_Line_Item__c();
        qItem4.UNITY_Proposal__c = q.Id;
        qItem4.UNITY_Quantity__c = 2;
        qItem4.UNITY_Product__c = PRODUCTID;
        qItem4.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem4.UNITY_Cost__c = 10;
        qItem4.UNITY_Price__c = 100;
        qItem4.UNITY_Activity_Type__c = 'Overtime Labor';
        qItem4.UNITY_Type__c = 'Labor';
        //5
        UNITY_Proposal_Line_Item__c qItem5 = new UNITY_Proposal_Line_Item__c();
        qItem5.UNITY_Proposal__c = q.Id;
        qItem5.UNITY_Quantity__c = 2;
        qItem5.UNITY_Product__c = PRODUCTID;
        qItem5.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem5.UNITY_Cost__c = 10;
        qItem5.UNITY_Price__c = 100;
        qItem5.UNITY_Activity_Type__c = 'Use Tax';
        qItem5.UNITY_Type__c = 'Expenses';
        //6
        UNITY_Proposal_Line_Item__c qItem6 = new UNITY_Proposal_Line_Item__c();
        qItem6.UNITY_Proposal__c = q.Id;
        qItem6.UNITY_Quantity__c = 2;
        qItem6.UNITY_Product__c = PRODUCTID;
        qItem6.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem6.UNITY_Cost__c = 10;
        qItem6.UNITY_Price__c = 100;
        qItem6.UNITY_Activity_Type__c = 'Parts - Service and Remodel';
        qItem6.UNITY_Type__c = 'Parts';
        //7
        UNITY_Proposal_Line_Item__c qItem7 = new UNITY_Proposal_Line_Item__c();
        qItem7.UNITY_Proposal__c = q.Id;
        qItem7.UNITY_Quantity__c = 2;
        qItem7.UNITY_Product__c = PRODUCTID;
        qItem7.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem7.UNITY_Cost__c = 10;
        qItem7.UNITY_Price__c = 100;
        qItem7.UNITY_Activity_Type__c = 'Parts - New Construction';
        qItem7.UNITY_Type__c = 'Parts';
        //Insert the lines
        qLines.add(qItem);qLines.add(qItem2);qLines.add(qItem3);qLines.add(qItem4);qLines.add(qItem5);qLines.add(qItem6);qLines.add(qItem7);
        insert qLines;
        
        List<Id> recordIds = new List<Id>();
        
        for(UNITY_Proposal_Line_Item__c ql :qLines){
            recordIds.add(ql.Id);
        }
        
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        UNITY_CallAvatax.getTaxQuote(recordIds,'lines');

        Test.stopTest();
        
    }
    
    public static TestMethod void test3b(){
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String qRTId = UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
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
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        
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
        insert wo;
        
        //Create quote
        UNITY_Proposal__c q = new UNITY_Proposal__c();
        q.RecordTypeId = qRTId;
        q.UNITY_Case__c = testCase.Id;
        q.UNITY_Account__c = cust.Id;
        q.UNITY_Customer__c = cust.Id;
        q.UNITY_Business_Unit__c = 'NSBS';
        q.UNITY_Business_Unit_Account__c = bu.Id;
        q.UNITY_Agent__c = UserInfo.getUserId();
        q.UNITY_Effective_Till_Date__c = (Date.today()+30);
        q.UNITY_Proposal_Status__c = 'Quote Creation';
        q.UNITY_Work_Order__c = wo.Id;
        insert q;
        //Create quote line items
        //1
        List<UNITY_Proposal_Line_Item__c> qLines = new List<UNITY_Proposal_Line_Item__c>();
        UNITY_Proposal_Line_Item__c qItem = new UNITY_Proposal_Line_Item__c();
        qItem.UNITY_Proposal__c = q.Id;
        qItem.UNITY_Quantity__c = 2;
        qItem.UNITY_Product__c = PRODUCTID;
        qItem.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem.UNITY_Cost__c = 10;
        qItem.UNITY_Price__c = 100;
        qItem.UNITY_Activity_Type__c = 'Travel - Standard Labor';
        qItem.UNITY_Type__c = 'Travel';
        //2
        UNITY_Proposal_Line_Item__c qItem2 = new UNITY_Proposal_Line_Item__c();
        qItem2.UNITY_Proposal__c = q.Id;
        qItem2.UNITY_Quantity__c = 2;
        qItem2.UNITY_Product__c = PRODUCTID;
        qItem2.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem2.UNITY_Cost__c = 10;
        qItem2.UNITY_Price__c = 100;
        qItem2.UNITY_Activity_Type__c = 'Standard Labor';
        qItem2.UNITY_Type__c = 'Labor';
        //3
        UNITY_Proposal_Line_Item__c qItem3 = new UNITY_Proposal_Line_Item__c();
        qItem3.UNITY_Proposal__c = q.Id;
        qItem3.UNITY_Quantity__c = 2;
        qItem3.UNITY_Product__c = PRODUCTID;
        qItem3.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem3.UNITY_Cost__c = 10;
        qItem3.UNITY_Price__c = 100;
        qItem3.UNITY_Activity_Type__c = 'Travel - Overtime Labor';
        qItem3.UNITY_Type__c = 'Travel';
        //4
        UNITY_Proposal_Line_Item__c qItem4 = new UNITY_Proposal_Line_Item__c();
        qItem4.UNITY_Proposal__c = q.Id;
        qItem4.UNITY_Quantity__c = 2;
        qItem4.UNITY_Product__c = PRODUCTID;
        qItem4.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem4.UNITY_Cost__c = 10;
        qItem4.UNITY_Price__c = 100;
        qItem4.UNITY_Activity_Type__c = 'Overtime Labor';
        qItem4.UNITY_Type__c = 'Labor';
        //5
        UNITY_Proposal_Line_Item__c qItem5 = new UNITY_Proposal_Line_Item__c();
        qItem5.UNITY_Proposal__c = q.Id;
        qItem5.UNITY_Quantity__c = 2;
        qItem5.UNITY_Product__c = PRODUCTID;
        qItem5.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem5.UNITY_Cost__c = 10;
        qItem5.UNITY_Price__c = 100;
        qItem5.UNITY_Activity_Type__c = 'Use Tax';
        qItem5.UNITY_Type__c = 'Expenses';
        //6
        UNITY_Proposal_Line_Item__c qItem6 = new UNITY_Proposal_Line_Item__c();
        qItem6.UNITY_Proposal__c = q.Id;
        qItem6.UNITY_Quantity__c = 2;
        qItem6.UNITY_Product__c = PRODUCTID;
        qItem6.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem6.UNITY_Cost__c = 10;
        qItem6.UNITY_Price__c = 100;
        qItem6.UNITY_Activity_Type__c = 'Parts - Service and Remodel';
        qItem6.UNITY_Type__c = 'Parts';
        //7
        UNITY_Proposal_Line_Item__c qItem7 = new UNITY_Proposal_Line_Item__c();
        qItem7.UNITY_Proposal__c = q.Id;
        qItem7.UNITY_Quantity__c = 2;
        qItem7.UNITY_Product__c = PRODUCTID;
        qItem7.UNITY_Customer_Adjusted_Quantity__c = 2;
        qItem7.UNITY_Cost__c = 10;
        qItem7.UNITY_Price__c = 100;
        qItem7.UNITY_Activity_Type__c = 'Parts - New Construction';
        qItem7.UNITY_Type__c = 'Parts';
        //Insert the lines
        qLines.add(qItem);qLines.add(qItem2);qLines.add(qItem3);qLines.add(qItem4);qLines.add(qItem5);qLines.add(qItem6);qLines.add(qItem7);
        insert qLines;
        
        List<Id> recordIds = new List<Id>();
        recordIds.add(q.Id);
        
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        UNITY_CallAvatax.getTaxServiceCharge(recordIds,'quote');

        Test.stopTest();
        
    }
}