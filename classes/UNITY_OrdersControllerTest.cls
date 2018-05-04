@isTest
public class UNITY_OrdersControllerTest {
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
    static testMethod void testOrders() {
        
        UNITY_Constants.MAX_TRIGGER_EXECUTION = 2;
        /*
        List<UNITY_General_Settings__c> generalSettings = new List<UNITY_General_Settings__c>();
        
        UNITY_General_Settings__c gSetting1 = new UNITY_General_Settings__c(Name= UNITY_Constants.SERVICE_FEE_PRODUCT_TYPE_CS_KEY, UNITY_Value__c = 'Vendor Service Fee', UNITY_Description__c='Vendor Service Fee');
        
        generalSettings.add(gSetting1);
        
        insert generalSettings;
        */
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        workOrders.get(0).UNITY_Assigned_Vendor__c = accountVendor.Id;
        update workOrders;
        List<User> users = UNITY_TestDataFactory.createUsersTechnician(1,contacts.get(0).Id);
        Order order1= new Order(AccountId=accountCustomer.Id,EffectiveDate=Date.toDay(),EndDate=Date.toDay(),Status ='Final',FSO__WorkOrder__c=workOrders.get(0).Id,UNITY_Vendor__c=accountVendor.Id);
        Order order2= new Order(AccountId=accountCustomer.Id,EffectiveDate=Date.toDay(),EndDate=Date.toDay(),Status ='Draft',FSO__WorkOrder__c=workOrders.get(0).Id,UNITY_Vendor__c=accountVendor.Id);
        List<Order> orders=new List<Order>();
        User user = users.get(0);
        orders.add(order1);
        orders.add(order2);
        insert orders;
        workOrders.get(0).UNITY_Current_PO__c =orders.get(1).Id;
        update workOrders;
        Test.startTest();
        UNITY_OrdersController ordersController = new UNITY_OrdersController();
        ordersController.workOrderId  = workOrders.get(0).Id;
        ordersController.setAssignedVendorId(accountVendor.Id);
        ordersController.workOrderId  = workOrders.get(1).Id;
        //ordersController.setAssignedVendorId(accountVendor.Id);

        Test.stopTest();
        
        System.assertEquals(1,ordersController.orders.size());
        System.assertEquals(accountVendor.Id,ordersController.getAssignedVendorId());
    }

}