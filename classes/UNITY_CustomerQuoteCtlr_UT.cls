/**UNITY_CustomerQuoteCtlr_UT
 * @description: This is the unit test class for UNITY_CustomerQuoteCtlr: controller class for the customer quote .pdf vfPage
 * @programer:   Izay Ramos-Irizarry
 * @date:		 4/5/2016
 * @version:	 1.0
 */
@isTest
public class UNITY_CustomerQuoteCtlr_UT {
    
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
        UNITY_MuleSiteSettingUtilsTest.setUp();
        UNITY_Mule2Salesforce_MappingUtilsTest.setUp();
        UNITY_Mulesoft_Credentials__c mCreds = new UNITY_Mulesoft_Credentials__c(
        	Name = 'Test-Basic Authorization-162468',
            Authorization_Header__c = 'Basic dXNlcjE6cGFzc3dvcmQx'
        );
        //Create BU Specific Team field Map
        UNITY_BU_Team_Field_Map__c nsbsTeamMap = new UNITY_BU_Team_Field_Map__c(
        	Name = 'NSBS',
            UNITY_Field_API_Name__c = 'UNITY_Customer_Team__c'
        );
        insert nsbsTeamMap;
        //Setup custom setting with status map
        List<UNITY_Status_Fields_Update_Map__c> statMapList = new List<UNITY_Status_Fields_Update_Map__c>();
        statMapList.add(new UNITY_Status_Fields_Update_Map__c());
        
        statMapList[0].Name = 'TestPOSubmittedtoWO';
        statMapList[0].UNITY_Origin_Object__c = 'UNITY_Proposal__c';
        statMapList[0].UNITY_Origin_Value__c = 'Quote Creation';
        statMapList[0].UNITY_Origin_Record_Type__c = 'UNITY_Customer_Proposal';
        statMapList[0].UNITY_Order__c = 1;
        statMapList[0].UNITY_Target_Object__c = 'WorkOrder';
        statMapList[0].UNITY_Target_Value__c = 'Quote Needed';
        statMapList[0].UNITY_Target_Record_Type__c = 'Service_Request';
        
        statMapList.add(new UNITY_Status_Fields_Update_Map__c());
        statMapList[1].Name = 'TestPOFinaltoWO';
        statMapList[1].UNITY_Origin_Object__c = 'UNITY_Proposal__c';
        statMapList[1].UNITY_Origin_Value__c = 'Pending Customer Review';
        statMapList[1].UNITY_Origin_Record_Type__c = 'UNITY_Customer_Proposal';
        statMapList[1].UNITY_Order__c = 2;
        statMapList[1].UNITY_Target_Object__c = 'WorkOrder';
        statMapList[1].UNITY_Target_Value__c = 'Quote Submitted to Customer';
        statMapList[1].UNITY_Target_Record_Type__c = 'Service_Request';
        insert statMapList;
        List<Account> accts = new List<Account>();
        Account cust = TestDataProvider.getAccounts(1,'Customer', 'Customer')[0];cust.Account_Status__c = 'Active';
        cust.Account_Status__c = 'Active';
        cust.UNITY_Customer_Team__c = 'Team 1';
        cust.UNITY_MNS_Customer_Team__c = 'Team 1';
        cust.UNITY_Tier_Level__c = 'Tier 1';
        Account vend = TestDataProvider.getAccounts(1,'Vendor','Vendor')[0];vend.UNITY_Vendor_Status__c = 'Active';
        Account bu = TestDataProvider.getAccounts(1,'Miner','Business Unit')[0];bu.UNITY_Business_Unit__c = 'NSBS';bu.UNITY_Company_Code__c = 'NSBS';bu.UNITY_Vendor_Status__c = 'Active';
        accts.add(cust);accts.add(vend);accts.add(bu);insert accts;
        TestDataProvider.setKeyValueStore();
        TestDataProvider.setGLMatrix();
        User u = TestDataProvider.getUsers(1)[0];
        System.runAs(u){
            TestDataProvider.setEmailTemplate('UNITY_Quote_Initial_Acceptance_v2');
        }
        //Create Contact
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(1,cust.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(1,cust.Id,cust.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
    	cases[0].UNITY_Business_Unit_Account__c = bu.Id;
        cases[0].UNITY_Business_Unit__c = 'NSBS';
        update cases;
        
    }
    
    public static Testmethod void test1(){
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String qRTId = UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String oRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        
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
        
        Test.startTest();
        
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
        
        List<UNITY_proposal_Line_Item__c> qLines = new List<UNITY_proposal_Line_Item__c>();
        for(Integer i = 0; i < 30; i++){
            UNITY_proposal_Line_Item__c ql1 = new UNITY_proposal_Line_Item__c(
                UNITY_Proposal__c = q.Id,
                UNITY_PriceBook_Entry_Id__c = PRICEBOOKENTRYID_L,
                UNITY_Product__c = PRODUCTID,
                UNITY_Cost__c = 55,
                UNITY_Quantity__c = 2,
                UNITY_Vendor_Adjusted_Quantity__c = 2.5,
                UNITY_Customer_Adjusted_Quantity__c = 1,
                UNITY_Activity_Type__c = 'Labor - Service',
                UNITY_Type__c = 'Standard Labor',
                UNITY_Price__c = 75
            );
            qLines.add(ql1);
        }
        insert qLines;
        
        List<Order> ords = new List<Order>();
        
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
        ords.add(o);
        
        Order o2 = new Order();
        o2.RecordTypeId = oRTId;
        o2.AccountId = cust.Id;
        o2.UNITY_Vendor__c = vend.Id;
        o2.Type = 'Usage Request PO';
        o2.UNITY_Business_Unit__c = 'NSBS';
        o2.UNITY_Business_Unit_Account__c = bu.Id;
        o2.Status = 'Draft';
        o2.FSO__WorkOrder__c = wo.Id;
        o2.EffectiveDate = Date.today();
        o2.UNITY_NTE__c = 400;
        ords.add(o2);
        
        insert ords;
        
        List<OrderItem> oLines = new List<Orderitem>();
        OrderItem oItem = new orderItem();
        oItem.OrderId = ords[0].Id;
        oItem.PricebookEntryId = PRICEBOOKENTRYID_L;
        oItem.Quantity = 2;
        oItem.UnitPrice = 10;
        oItem.UNITY_Activity_Type__c = 'Standard Labor';
        oItem.UNITY_Type__c = 'Labor - Service';
        OrderItem oItem2 = new orderItem();
        oItem2.OrderId = ords[1].Id;
        oItem2.PricebookEntryId = PRICEBOOKENTRYID_L;
        oItem2.Quantity = 2;
        oItem2.UnitPrice = 10;
        oItem2.UNITY_Activity_Type__c = 'Standard Labor';
        oItem2.UNITY_Type__c = 'Labor - Service';
        oLines.add(oItem);
        oLines.add(oItem2);
        insert oLines;
        
        ords[0].Status = 'Accepted';
        ords[1].Status = 'Accepted';
        
        update ords;
        
        UNITY_Proposal__c master = [SELECT Id,UNITY_Customer__c,UNITY_Account__c,UNITY_Business_Unit_Account__c FROM UNITY_Proposal__c WHERE RecordTypeId = :UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE LIMIT 1];
        
        master.UNITY_Business_Unit_Account__c = bu.Id;
        master.UNITY_Customer__c = cust.Id;
        master.UNITY_Account__c = cust.Id;
        master.UNITY_Business_Unit__c = 'NSBS';
        update master;
        
        PageReference pageRef = Page.UNITY_CustomerQuote;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',q.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(q);
        UNITY_CustomerQuoteCtlr controller = new UNITY_CustomerQuoteCtlr(sc);
        
        UNITY_AttachmentHelper_Miner.attachQuote(q.Id);
        Test.stopTest();
    }
    
    public static Testmethod void test2(){
        String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
        String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        String qRTId = UNITY_Constants.PROPOSAL_CUSTOMER_PROPOSAL_RECORDTYPE;
        String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
        String oRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
        
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
        
        Test.startTest();
        
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
        
        List<Order> ords = new List<Order>();
        
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
        ords.add(o);
        
        Order o2 = new Order();
        o2.RecordTypeId = oRTId;
        o2.AccountId = cust.Id;
        o2.UNITY_Vendor__c = vend.Id;
        o2.Type = 'Usage Request PO';
        o2.UNITY_Business_Unit__c = 'NSBS';
        o2.UNITY_Business_Unit_Account__c = bu.Id;
        o2.Status = 'Draft';
        o2.FSO__WorkOrder__c = wo.Id;
        o2.EffectiveDate = Date.today();
        o2.UNITY_NTE__c = 400;
        ords.add(o2);
        
        insert ords;
        
        List<OrderItem> oLines = new List<Orderitem>();
        OrderItem oItem = new orderItem();
        oItem.OrderId = ords[0].Id;
        oItem.PricebookEntryId = PRICEBOOKENTRYID_L;
        oItem.Quantity = 2;
        oItem.UnitPrice = 10;
        oItem.UNITY_Activity_Type__c = 'Standard Labor';
        oItem.UNITY_Type__c = 'Labor - Service';
        OrderItem oItem2 = new orderItem();
        oItem2.OrderId = ords[1].Id;
        oItem2.PricebookEntryId = PRICEBOOKENTRYID_L;
        oItem2.Quantity = 2;
        oItem2.UnitPrice = 10;
        oItem2.UNITY_Activity_Type__c = 'Standard Labor';
        oItem2.UNITY_Type__c = 'Labor - Service';
        oLines.add(oItem);
        oLines.add(oItem2);
        insert oLines;
        
        ords[0].Status = 'Accepted';
        ords[1].Status = 'Accepted';
        
        update ords;
        
        List<UNITY_Proposal__c> quotes = new List<UNITY_Proposal__c>();
        
        UNITY_Proposal__c master = [SELECT Id,UNITY_Customer__c,UNITY_Account__c,UNITY_Business_Unit_Account__c FROM UNITY_Proposal__c WHERE RecordTypeId = :UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE LIMIT 1];
        
        master.UNITY_Business_Unit_Account__c = bu.Id;
        master.UNITY_Customer__c = cust.Id;
        master.UNITY_Account__c = cust.Id;
        master.UNITY_Business_Unit__c = 'NSBS';
        master.UNITY_Customer_Email__c = 'test@minercorp.com';
        q.UNITY_Proposal_Status__c = 'Agent Review Complete';
        quotes.add(q);
        quotes.add(master);
        update quotes;

        ApexPages.StandardController sc = new ApexPages.StandardController(master);
        ApexPages.currentPage().getParameters().put('id',master.Id);
        ApexPages.currentPage().getParameters().put('relatedToId',master.Id);
        UNITY_CustomerQuoteCtlr controller = new UNITY_CustomerQuoteCtlr();

        controller.quoteId = master.Id;
        
        //Set<String> qids = new Set<String>();
        //qids.add(master.Id);
        UNITY_AttachmentHelper_Miner.sendAndAttachQuote(master.id,true);
        
        test.stopTest();
    }
}