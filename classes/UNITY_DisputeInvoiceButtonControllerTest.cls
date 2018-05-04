@isTest
public class UNITY_DisputeInvoiceButtonControllerTest{
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
   public static testMethod void runTest(){
            UNITY_Constants.MAX_TRIGGER_EXECUTION = 6;
        	//system.runAs(createUser()){
            
            Test.startTest();
            UNITY_Invoice__c invoice = prepareData();
			
            ApexPages.StandardController sc1 = new ApexPages.StandardController(invoice);
            UNITY_DisputeInvoiceButtonController controller = new UNITY_DisputeInvoiceButtonController(sc1);
            controller.disputeInvoice();
            
            List<UNITY_Invoice__c> invoices = [SELECT Id, UNITY_Invoice_Status__c FROM UNITY_Invoice__c];
            system.assertEquals(2, invoices.size());
            for(UNITY_Invoice__c i : invoices){
                if(i.Id == invoice.Id){
                    system.assertEquals('Disputed', i.UNITY_Invoice_Status__c);
                } 
            }
            
            List<UNITY_Invoice_Line_Item__c> oldilis = [SELECT Id FROM UNITY_Invoice_Line_Item__c WHERE UNITY_Invoice__c =: invoice.Id];
            //system.assertEquals(2, oldilis.size());
            List<UNITY_Invoice_Line_Item__c> newilis = [SELECT Id FROM UNITY_Invoice_Line_Item__c WHERE UNITY_Invoice__c !=: invoice.Id];
            //system.assertEquals(0, newilis .size());
            
            Order o1 = [SELECT Id, Status, UNITY_Updated_Invoice__c FROM Order];
            system.assertNotEquals(invoice.Id, o1.UNITY_Updated_Invoice__c);
            //system.assertNotEquals(null, o.UNITY_Updated_Invoice__c);
            //system.assertEquals('Invoice Regenerated', o.Status);
        	//} 

            Test.stopTest();
    }
    
    private static UNITY_Invoice__c prepareData(){
    
        //Get the accounts
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String usageRecRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
        String purchaseOrdRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
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
        Contact con = new Contact(FirstName = 'Test', LastName = 'Test', Email='test@test.com');
        insert con;
        
        Product2 product = new Product2(Name = 'Test');
        product.UNITY_Status__c = 'Inactive';
        insert product;
        
        Product2 product2 = new Product2(Name = 'Test2');
        product2.UNITY_Status__c = 'Inactive';
        insert product2;
        
        FSO__Skill__c skill = new FSO__Skill__c();
        skill.Name = 'Test Skill';
        
        insert skill;
        
        List<UNITY_Service_Contract__c> serviceContractList = new List<UNITY_Service_Contract__c>();
        
        List<UNITY_Service_Contract_Line_Item__c> serviceContractLineItemList = new List<UNITY_Service_Contract_Line_Item__c>();
        
        UNITY_Service_Contract__c serviceContract1 = new UNITY_Service_Contract__c();
        
        serviceContract1.UNITY_Account__c = cust.Id;
        serviceContract1.UNITY_Trip_Charge__c = 10;
        serviceContract1.UNITY_Trip_Charge_Type__c = 'Hourly Rate';
        serviceContract1.UNITY_Default_Labor_Rate__c = 75;
        serviceContract1.UNITY_Invoicing_Increments__c = 'Next ¼ hr';
        //serviceContract1.UNITY_Business_Unit__c = 'MNS;NSBS';
        serviceContract1.UNITY_IS_Active__c = true;
        serviceContract1.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        serviceContract1.UNITY_ServiceReport_Template__c = 'my template';
        
        serviceContractList.add(serviceContract1);
        
        insert serviceContractList;
        
        UNITY_Service_Contract_Line_Item__c serviceContractLI1 = new UNITY_Service_Contract_Line_Item__c();
        
        serviceContractLI1.UNITY_Trade__c = skill.Id;
        serviceContractLI1.UNITY_Labor_Cost__c = 100;
        serviceContractLI1.UNITY_Service_Contract__c = serviceContract1.Id;
        serviceContractLI1.RecordTypeId = UNITY_Constants.SCLI_HOURLY_RATE_RECORDTYPE;
        
        serviceContractLineItemList.add(serviceContractLI1);
        
        insert serviceContractLineItemList;
        
        //Get the case
        Case c = [SELECT Id FROM Case LIMIT 1];
        c.UNITY_Customer_Service_Contract__c = serviceContract1.Id;
        update c;
        
        RecordType woRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'WorkOrder' AND DeveloperName = 'Service_Request'];  
        WorkOrder wo = new WorkOrder(RecordTypeId = woRecordType.Id, UNITY_Customer__c  = cust.Id ,UNITY_Assigned_Vendor__c = vend.Id, AccountId=cust.Id, CaseId = c.Id, Subject='Test');
        wo.UNITY_Customer_Service_Contract__c = serviceContract1.Id;
        insert wo;
        
        RecordType purchaseOrderRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'UNITY_Purchase_Order' AND SobjectType ='Order'];
        
        UNITY_Service_Contract__c sc = new UNITY_Service_Contract__c(
            UNITY_Account__c = cust.Id, 
            UNITY_Margin__c = 10,
            UNITY_Invoicing_Method__c = 'Email'
        );
        insert sc;
        
        UNITY_Invoice__c invoice = new UNITY_Invoice__c(UNITY_Customer_Email__c = cust.Account_Email__c, UNITY_Case__c = c.Id, UNITY_Customer__c = cust.Id, UNITY_Customer_Service_Contract__c = sc.Id, UNITY_Service_Contract_Margin_Value__c = sc.UNITY_Margin__c);
        insert invoice;
        
        
        List<Order> orders = new List<Order>();
        Order o = new Order(RecordTypeId = purchaseOrderRT.id,UNITY_Invoice__c =invoice.id , FSO__WorkOrder__c = wo.Id, AccountId = cust.Id, EffectiveDate = Date.today(), Status = 'Draft');
        orders.add(o);
        
        insert orders;
        
        PricebookEntry pe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product.Id, UnitPrice = 10, IsActive = true);
        insert pe;
        
        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product2.Id, UnitPrice = 10, IsActive = true);
        insert pe2;
        
        List<OrderItem> orderItems = new List<OrderItem>();
        OrderItem oi = new OrderItem(OrderId = o.Id, PricebookEntryId = pe.Id, Quantity = 10, UnitPrice = 10, UNITY_Total_Price__c = 100, UNITY_Sales_Tax__c = 10, UNITY_Customer_Adjusted_Quantity__c = 1, UNITY_Tax_Code__c = 'Test', UNITY_Total_Cost__c = 7);
        orderItems.add(oi);
        
        OrderItem oi2 = new OrderItem(OrderId = o.Id, PricebookEntryId = pe2.Id, Quantity = 20, UnitPrice = 10, UNITY_Total_Price__c = 200, UNITY_Sales_Tax__c = 5, UNITY_Customer_Adjusted_Quantity__c = 2, UNITY_Tax_Code__c = 'Test2', UNITY_Total_Cost__c = 14);
        orderItems.add(oi2);
        
        insert orderItems;

        List<UNITY_Invoice_Line_Item__c> invoiceLinteItems = new List<UNITY_Invoice_Line_Item__c>();
        UNITY_Invoice_Line_Item__c ili1 = new UNITY_Invoice_Line_Item__c(UNITY_Invoice__c = invoice.Id, UNITY_Total_Price__c = 100, UNITY_Cost__c = 7, UNITY_Sales_Tax__c = 10, UNITY_PO_Price__c =10, UNITY_Quantity__c = 10, UNITY_Adjusted_Quantity__c = 1, Product__c = product.Id, UNITY_Tax_Code__c = 'Test');
        invoiceLinteItems.add(ili1);
        UNITY_Invoice_Line_Item__c ili2 = new UNITY_Invoice_Line_Item__c(UNITY_Invoice__c = invoice.Id, UNITY_Total_Price__c = 200, UNITY_Cost__c = 14, UNITY_Sales_Tax__c = 5, UNITY_PO_Price__c =10, UNITY_Quantity__c = 20, UNITY_Adjusted_Quantity__c = 2, Product__c = product2.Id, UNITY_Tax_Code__c = 'Test2');
        invoiceLinteItems.add(ili2);
        insert invoiceLinteItems;
        return invoice;
    }
    
    private static User createUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'testu', Email='testUser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='unityTestUser@testorg.com');
        insert u;
        return u;
    }

}