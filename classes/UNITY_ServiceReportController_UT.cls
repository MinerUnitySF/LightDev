@isTest
public class UNITY_ServiceReportController_UT {
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
        //Get the case
        Case c = [SELECT Id FROM Case LIMIT 1];

        Asset a = new Asset(
        	Name = 'TestAsset#1',
            AccountId = cust.Id,
            Product2Id = PRODUCTID,
            SerialNumber = '1234567',
            UNITY_Asset_Location_On_Site__c = 'At a place in the place'
        );
        insert a;
        c.AssetId = a.Id;
        update c;
        
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
        wo.UNITY_Tech_ETA_Date_Cust__c = '01/15/2016 5:00PM';
        insert wo;
        
        List<Order> ords = new List<Order>();
        
        Order o = new Order();
        o.RecordTypeId = purchaseOrdRTId;
        o.AccountId = cust.Id;
        o.UNITY_Vendor__c = vend.Id;
        o.Type = 'Purchase Order';
        o.UNITY_Business_Unit__c = 'NSBS';
        o.UNITY_Business_Unit_Account__c = bu.Id;
        o.Status = 'Draft';
        o.FSO__WorkOrder__c = wo.Id;
        o.EffectiveDate = Date.today();
        ords.add(o);
        
        test.startTest();
        insert ords;
        List<OrderItem> oLines = new List<Orderitem>();
        OrderItem oItem = new orderItem();
        oItem.OrderId = o.Id;
        oItem.PricebookEntryId = PRICEBOOKENTRYID_P;
        oItem.Quantity = 2;
        oItem.UnitPrice = 10;
        oItem.UNITY_Activity_Type__c = 'Parts - Service and Remodel';
        oItem.UNITY_Type__c = 'Parts';
        insert oLines;
        
        UNITY_ServiceReportController src = new UNITY_ServiceReportController();
        src.relatedTo = wo;
        
        test.stopTest();
        
    }
}