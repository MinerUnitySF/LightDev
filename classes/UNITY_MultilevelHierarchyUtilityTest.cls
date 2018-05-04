@isTest
public with sharing class UNITY_MultilevelHierarchyUtilityTest {
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
        
        id standardPriceBookId = Test.getStandardPricebookId();
        
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 2;
        
        List<UNITY_General_Settings__c> generalSettings = new List<UNITY_General_Settings__c>();
        
        UNITY_General_Settings__c gSetting1 = new UNITY_General_Settings__c(Name= UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, UNITY_Value__c = 'Vendor Service Fee', UNITY_Description__c='Vendor Service Fee');
        
        generalSettings.add(gSetting1);
        
        insert generalSettings;
        
        TestDataProvider.setKeyValueStore();
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        
        List<Product2> productList = new List<Product2>();
        
        Product2 partProduct = new Product2();
        partProduct.Name = 'part product test';
        partProduct.IsActive = true ;
        partProduct.Description  = 'part product test';
        partProduct.UNITY_Product_Type__c = 'Part';
        partProduct.Model__c = 'part test';
        partProduct.UNITY_Status__c = 'Inactive';
        partProduct.Broad__c = 'Door';
        
        productList.add(partProduct);
        
        Product2 laborProduct = new Product2();
        laborProduct.Name = 'labor product test';
        laborProduct.IsActive = true ;
        laborProduct.Description  = 'labor product test';
        laborProduct.UNITY_Product_Type__c = 'Labor';
        laborProduct.Model__c = 'product test';
        laborProduct.UNITY_Status__c = 'Inactive';
        laborProduct.Broad__c = 'Door';
        
        productList.add(laborProduct);
        
        Product2 travelProduct = new Product2();
        travelProduct.Name = 'travel product test';
        travelProduct.IsActive = true ;
        travelProduct.Description  = 'travel product test';
        travelProduct.UNITY_Product_Type__c = 'Travel';
        travelProduct.Model__c = 'travel test';
        travelProduct.UNITY_Status__c = 'Inactive';
        travelProduct.Broad__c = 'Door';
        
        productList.add(travelProduct);
        
        Product2 vendorServiceFeeProduct = new Product2();
        vendorServiceFeeProduct.Name = 'travel product test';
        vendorServiceFeeProduct.IsActive = true ;
        vendorServiceFeeProduct.Description  = 'vendorServiceFeeProduct test';
        vendorServiceFeeProduct.UNITY_Product_Type__c = 'Travel';
        vendorServiceFeeProduct.Model__c = 'vendorServiceFeeProduct';
        vendorServiceFeeProduct.UNITY_Status__c = 'Inactive';
        vendorServiceFeeProduct.Broad__c = 'Door';
        
        productList.add(vendorServiceFeeProduct);
        
        insert productList;
        
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        
        PricebookEntry pbe1 = new PricebookEntry();
        
        pbe1.Pricebook2Id = standardPriceBookId;
        pbe1.Product2Id = partProduct.Id;
        pbe1.UnitPrice = 80;
        
        pbeList.add(pbe1);
        
        PricebookEntry pbe2 = new PricebookEntry();
        
        pbe2.Pricebook2Id = standardPriceBookId;
        pbe2.Product2Id = laborProduct.Id;
        pbe2.UnitPrice = 100;
        
        pbeList.add(pbe2);
        
        PricebookEntry pbe3 = new PricebookEntry();
        
        pbe3.Pricebook2Id = standardPriceBookId;
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
        
        /*
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
        */
        
        insert childTemplate;
        
        UNITY_TemplateConfigRelationshipLookups__c relationshipLookup = new UNITY_TemplateConfigRelationshipLookups__c();
        
        relationshipLookup.UNITY_Child_Object__c = 'OrderItem';
        relationshipLookup.UNITY_Parent_Object__c = 'Order';
        relationshipLookup.UNITY_Parent_Lookup_Field__c = 'OrderId';
        relationshipLookup.Name = 'OrderItem-Order:Lookup';
        
        insert relationshipLookup;
        
        Account newAccount = new Account();
        
        newAccount.RecordTypeId  = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        newAccount.Name = 'Test Customer Account';
        newAccount.BillingStreet = '123 main st';
        newAccount.BillingCity = 'Test';
        newAccount.BillingState = 'IL';
        newAccount.BillingPostalCode = '60606';
        newAccount.BillingCountry = 'US';
        newAccount.Account_Status__c = 'Active';
        
        insert newAccount;
        
        Contact newContact = new Contact();
        
        newContact.LastName = 'Test';
        newContact.AccountId = newAccount.Id;
        
        insert newContact;
        
        FSO__Skill__c skill = new FSO__Skill__c();
        skill.Name = 'Test Skill';
        
        insert skill;
        
        Case newCase = new Case();
        
        newCase.RecordTypeId = UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE;
        newCase.Subject = 'Test Subject';
        newCase.AccountId = newAccount.Id;
        newCase.ContactId = newContact.Id;
        newCase.UNITY_Customer__c = newAccount.Id;
        newCase.Status = 'In Progress';
        
        insert newCase;
        
        WorkOrder newWorkOrder = new WorkOrder();
        
        newWorkOrder.CaseId = newCase.Id;
        newWorkOrder.Subject = 'test WO';
        newWorkOrder.ContactId = newContact.Id;
        newWorkOrder.UNITY_Agent__c = UserInfo.getUserId();
        newWorkOrder.UNITY_Customer__c = newAccount.Id;
        newWorkOrder.UNITY_Work_Window_Begin__c = datetime.now();
        
        insert newWorkOrder;
    }
    
    static testMethod void test(){
        
        Account acc = [select id from Account where name = 'Test Customer Account'];
        WorkOrder wo = [select id from WorkOrder where Subject = 'test WO'];
        
        UNITY_Template_Configuration__c template = [select id from UNITY_Template_Configuration__c where Name ='Test PO'];
        
        Order orderRecord = new Order();
        
        orderRecord.FSO__WorkOrder__c = wo.Id;
        orderRecord.AccountId = acc.Id;
        orderRecord.EffectiveDate = Date.today();
        orderRecord.Status = 'Draft';
        orderRecord.UNITY_PO_Template__c = template.Id;
        
        insert orderRecord;
        
        UNITY_MultiLevelHierarchyUtility.getHierarchiesOptimized(new List<UNITY_Template_Configuration__c>{template});
        
        Map<Id,UNITY_MultiLevelHierarchyUtility.HierarchyNode> hierarchies = UNITY_MultiLevelHierarchyUtility.getHierarchies(new List<UNITY_Template_Configuration__c>{template});
        
        UNITY_MultiLevelHierarchyUtility.printAllChildrenNames(new List<UNITY_Template_Configuration__c>{template}, hierarchies); 
    }
}