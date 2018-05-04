@isTest
public class UNITY_QuoteToOrderConverterTest{
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
    public static testMethod void runTest(){
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 2;
        id standardPriceBook =Test.getStandardPricebookId();
        if(UNITY_General_Settings__c.getAll().values()==null){
            
            List<UNITY_General_Settings__c> generalSettings = new List<UNITY_General_Settings__c>();
            
            UNITY_General_Settings__c gSetting1 = new UNITY_General_Settings__c(Name= UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, UNITY_Value__c = 'Vendor Service Fee', UNITY_Description__c='Vendor Service Fee');
            
            generalSettings.add(gSetting1);
            
            insert generalSettings;
        }
        
        Account acc = new Account(Name = 'Test', BillingCity = 'City', BillingStateCode = 'CA', BillingPostalCode = '12345', BillingCountry = 'US', BillingStreet = 'Street', Account_Email__c = 'test2@test.com');
        acc.Account_Status__c = 'Active';
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Test', Email='test@test.com', AccountId = acc.Id);
        insert con;
        
        Case c = new Case(AccountId = acc.Id, ContactId = con.Id);
        c.Status = 'Verified';
        insert c;
    
        WorkOrder workOrder = new WorkOrder(UNITY_Customer__c = acc.Id, UNITY_Assigned_Vendor__c = acc.Id, AccountId=acc.Id, CaseId = c.Id, Pricebook2Id = standardPriceBook, Subject = 'Subject');
        workOrder.UNITY_Work_Window_Begin__c = DateTime.now();
        workOrder.UNITY_Work_Window_End__c   = DateTime.now().addDays(5);
        insert workOrder;
    
        Key_Value_Store__c kvs = new Key_Value_Store__c(Name = 'Avatax URL', Value__c = 'www.someTestURL.com');
        insert kvs;
    
        Product2 product = new Product2(Name = 'Test');
        product.UNITY_Status__c = 'Inactive';
        product.Make1__c = 'test';
        product.Model__c = 'test';
        product.Description = 'test';
        insert product;
        
        PriceBookEntry pbe = new PriceBookEntry(Pricebook2Id = standardPriceBook, Product2Id = product.Id, UnitPrice = 12, IsActive = True );
        insert pbe;
    
        UNITY_Proposal__c quote = new UNITY_Proposal__c(UNITY_Work_Order__c = workOrder.Id, UNITY_Account__c = acc.Id, UNITY_Proposal_Status__c = 'Sent to Customer', UNITY_Case__c = c.Id);
        insert quote;
        
        UNITY_Proposal_Line_Item__c pli1 = new UNITY_Proposal_Line_Item__c(UNITY_Price__c = 100, UNITY_Product__c = product.Id, UNITY_Proposal__c = quote.Id, UNITY_Quantity__c = 10);
        insert pli1;
        
        quote.UNITY_Status__c = 'Accepted';
        update quote;
        
        UNITY_QuoteToOrderConverter.convertQuote(quote.Id);
        
        List<OrderItem> orderItems = [SELECT Id FROM OrderItem];
        system.assertEquals(1, orderItems.size());
    }
}