@isTest
public class UNITYPM_AutoInvoiceCreation_UT {
   
  	//Setup Product and Pricebook Info
    public static Id PRICEBOOKENTRYID_T;
    public static Id PRICEBOOKENTRYID_L;
    public static Id PRICEBOOKENTRYID_P;
    public static Id PRICEBOOKENTRYID_F;
    public static Id PRODUCTID_T;
    public static Id PRODUCTID_L;
    public static Id PRODUCTID_P;
    public static Id PRODUCTID_F;
    private static String custRTId = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
    private static String vendRTId = UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE;
    private static String buRTId = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
	private static String woRTId = UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE;
    private static String usageRecRTId = UNITY_Constants.ORDER_USAGE_REQUEST_RECORDTYPE;
	private static String purchaseOrdRTId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE;
    private static Account cust;
    private static Account vend;
    private static Account bu;
	private static WorkOrder wo;
    
    static{
        //Create Product & pricebook
        Map<String,String> prodMapP = TestDataProvider.getProductAndPriceBookEntry(1,'Part');
        for(String s :prodMapP.keySet()){
            PRICEBOOKENTRYID_P = (Id)prodMapP.get(s);
            PRODUCTID_P = (Id)s;
        }
        Map<String,String> prodMapL = TestDataProvider.getProductAndPriceBookEntry(1,'Labor');
        for(String s :prodMapL.keySet()){
            PRICEBOOKENTRYID_L = (Id)prodMapL.get(s);
            PRODUCTID_L = (Id)s;
        }
        Map<String,String> prodMapT = TestDataProvider.getProductAndPriceBookEntry(1,'Travel');
        for(String s :prodMapT.keySet()){
            PRICEBOOKENTRYID_T = (Id)prodMapT.get(s);
            PRODUCTID_T = (Id)s;
        }
         Map<String,String> prodMapF = TestDataProvider.getProductAndPriceBookEntry(1,'Freight');
        for(String s :prodMapF.keySet()){
            PRICEBOOKENTRYID_F = (Id)prodMapF.get(s);
            PRODUCTID_F = (Id)s;
        }
    }
  
    @testSetup
    public static void init(){
        TestDataProvider.unityTestSetup();        
    }
   public static void setupAcctAndWorkOrder(){
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
        cust.Type = 'Site/Location';
        update cust;

        //Get the case
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        //Create a Work Order
        wo = new WorkOrder();
        wo.AccountId = cust.Id;
        wo.UNITY_Accepted_Vendor__c = vend.Id;
        wo.UNITY_Business_Unit_Account__c = bu.Id;
        wo.UNITY_Business_Unit__c = 'MNS';
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
        wo.UNITY_Primary_Technician__c = TestDataProvider.getUser('Tech', 'One', 'NMS Technician').Id; 
        wo.UNITY_Secondary_Technician__c = TestDataProvider.getUser('Tech', 'Two', 'NMS Technician').Id;
        insert wo; 
       
       
    }
    
     public static TestMethod void test1(){
		setupAcctAndWorkOrder();        
        //Start test execution
        Test.startTest();         
         
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
            FSO__Product__c = PRODUCTID_P,
            FSO__Quantity__c = 10,
            UNITY_MAC__c = 15
        );
        insert lStock;
         
	     wo.UNITY_Accepted_Vendor__c = vend.Id;
	     wo.UNITY_Vendor_Status__c = 'Accepted';
	     wo.UNITY_Work_Window_Begin__c = DateTime.now();
         wo.UNITY_Work_Window_End__c = DateTime.now().addMinutes(60);
         wo.Status = 'In Progress';
         wo.SFPS_FS_OverallStatus__c = 'In Progress';
	     update wo; 
	      
	     wo.SFPS_FS_AllTasks_Completed__c = 'Complete';
	     wo.UNITY_Next_Step__c = 'Completion Confirmed';
	     update wo;	     
	      
         wo.Status = 'Completed';
         wo.SFPS_FS_OverallStatus__c = 'Completed';
         update wo;         

        List<Order> ords = new List<Order>();
        Order o = new Order();
        o.RecordTypeId = usageRecRTId;
        o.AccountId = cust.Id;
        o.UNITY_Vendor__c = vend.Id;
        o.Type = 'Purchase Order';
        o.UNITY_Business_Unit__c = 'NSBS';
        o.UNITY_Business_Unit_Account__c = bu.Id;
        o.Status = 'Draft';
        o.FSO__WorkOrder__c = wo.Id;
        o.EffectiveDate = Date.today();
        o.UNITY_NTE__c = 200;
        ords.add(o);
        insert ords;
            
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
      
        o.Status = 'Parts Order Required';
        update o;        
     
        o.Status = 'Final';
        o.UNITY_Tracking_Number__c = '111';
        o.UNITY_Shipping_Provider__c = 'FedEx';
        o.UNITY_Shipping_Method__c = 'Ground';
        o.UNITY_Expected_Arrival_Date__c = Date.today() + 3;
        update o;        
       
        oi.UNITY_Actual_Ship_Date__c = Date.today();
        oi.UNITY_Actual_Quantity__c = 10;
        update oi;
         
         o.Status = 'Final';
         update o;
        system.debug('>>>> neli  Status  >>>' + o.Status) ;
         
        UNITYPM_AutoInvoiceCreation autoInvoice = new UNITYPM_AutoInvoiceCreation();
        autoInvoice.getAutoInvoiceCreation(wo.CaseId, wo.ID);
         
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        System.debug('##### Before changing status');
       // UNITY_Invoice__c inv = [SELECT Id,Name,UNITY_Invoice_Status__c,UNITY_Service_Charge__c FROM UNITY_Invoice__c WHERE UNITY_Case__c = :wo.CaseId LIMIT 1];
       // inv.UNITY_Service_Charge__c = 6;
       // update inv;
         
        Test.stopTest();
     }
}