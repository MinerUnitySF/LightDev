@isTest
private class MSPFS_IntercompanyProcessingBatchTest {
    
    private static Account accountCustomer;
    private static Account accountVendor;
    private static Account buAccount;
    private static List<UNITY_Service_Contract__c> serviceContractsVendor;
    private static List<UNITY_Service_Contract__c> serviceContractsCustomer;
    private static List<Contact> contacts;
    private static List<Case> cases;
    private static List<UNITY_Service_Contract__c> serviceContracts;
    private static List<WorkOrder> workOrders;
    private static Product2 testLaborProduct;
    private static PricebookEntry testLaborPBE;

    static void setup() {
        TestDataProvider.setKeyValueStore();

        testLaborProduct = new Product2( Name = 'TestLaborProduct_IP', ProductCode = 'Miner-Labor', Make1__c = 'TestMake', Model__c = 'TestModel', Broad__c = 'Door',
            Group__c = 'High Speed', Type__c = 'Electrical', Family = 'Equipment', SVMXC__Product_Line__c = 'Equipment', IsActive = true, Description = 'Installed Product Test Product',
            SVMXC__Product_Cost__c = 0.00, SVMXC__Inherit_Parent_Warranty__c = true, UNITY_Status__c = 'Active', UNITY_Product_Cost__c = 0, UNITY_Unit_Of_Measure__c = 'Each',
            UNITY_Product_Type__c = 'Labor'
        );
        insert testLaborProduct;
        testLaborPBE = new PricebookEntry( Product2Id = testLaborProduct.Id, Pricebook2Id = Test.getStandardPricebookId() , UnitPrice = 2, Cost__c = 1 );
        insert testLaborPBE;

        accountCustomer = UNITY_TestDataFactory.createAccounts( 1, 'Site/Location', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE ).get(0);
        accountVendor = UNITY_TestDataFactory.createAccounts( 1, 'Customer', UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE ).get(0);
        buAccount = UNITY_TestDataFactory.createAccounts( 1, 'Business Unit', UNITY_Constants.ACCOUNT_MINER_RECORDTYPE ).get(0);
        serviceContractsVendor = UNITY_TestDataFactory.createServiceContracts( 2, accountVendor.id );
        serviceContractsCustomer = UNITY_TestDataFactory.createServiceContracts( 2, accountCustomer.Id );
        contacts = UNITY_TestDataFactory.createContacts( 2, accountCustomer.Id );
        cases = UNITY_TestDataFactory.createCases( 2, accountCustomer.Id, accountVendor.Id, contacts.get(0).Id, UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE );
        serviceContracts = UNITY_TestDataFactory.createServiceContracts( 1, accountCustomer.Id );
        workOrders = UNITY_TestDataFactory.createWorkOrders( 2, cases.get(0).Id,accountCustomer.Id, serviceContracts.get(0).Id, UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE );

        List<WorkOrderLineItem> wolis = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId =: workOrders[0].Id OR WorkOrderId =: workOrders[1].Id];

        for (WorkOrderLineItem woli : wolis) {
            woli.FSO__IsCompleted__c = true;
        }

        update wolis;

        for ( WorkOrder wo : workOrders ) {
            wo.MSPFS_Intercompany_MSP_Revenue_Processed__c = false;
            wo.MSPFS_Intercompany_Transfer__c = true;
            wo.UNITY_Attachment_Compliant__c = true;
            wo.Status = 'Completed';
            wo.SFPS_FS_AllTasks_Completed__c = 'All Tasks Completed/Verified';
            wo.UNITY_Next_Step__c = 'Completion Confirmed';
            wo.UNITY_Business_Unit_Account__c = buAccount.Id;
        }

        update workOrders;
    }

    static void createWOsWithItems() {
        List<Order> orders = new List<Order>();
        Order o = new Order(RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE, FSO__WorkOrder__c = workOrders[0].Id, AccountId = accountCustomer.Id, EffectiveDate = Date.today(), Status = 'Final',
            UNITY_GL_Segment_Account__c = '33', UNITY_GL_Sub_Account__c = '33123456');
        orders.add(o);
        
        Order o2 = new Order(RecordTypeId = UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE, FSO__WorkOrder__c = workOrders[1].Id, AccountId = accountCustomer.Id, EffectiveDate = Date.today(), Status = 'Draft',
            UNITY_GL_Segment_Account__c = '33', UNITY_GL_Sub_Account__c = '33123456');
        orders.add(o2);
        insert orders;

        List<OrderItem> orderItems = new List<OrderItem>();
        OrderItem oi = new OrderItem(OrderId = o.Id, PricebookEntryId = testLaborPBE.Id, Quantity = 10, UnitPrice = 10, UNITY_Total_Price__c = 100, UNITY_Sales_Tax__c = 10, 
            UNITY_Is_Vendor_Supply__c = true, UNITY_Activity_Type__c = 'Holiday Labor', MSPFS_MSP_Price__c = 5, UNITY_Vendor_Adjusted_Quantity__c = 1, 
            UNITY_Customer_Adjusted_Quantity__c = 1, UNITY_Tax_Code__c = 'Test', UNITY_Total_Cost__c = 7, UNITY_Not_Billable__c = false, MSPFS_MSP_Cost__c = 5);
        orderItems.add(oi);
        
        OrderItem oi2 = new OrderItem(OrderId = o2.Id, PricebookEntryId = testLaborPBE.Id, Quantity = 10, UnitPrice = 10, UNITY_Total_Price__c = 100, UNITY_Sales_Tax__c = 10, 
            UNITY_Is_Vendor_Supply__c = true, UNITY_Activity_Type__c = 'Holiday Labor', MSPFS_MSP_Price__c = 5, UNITY_Vendor_Adjusted_Quantity__c = 1,
            UNITY_Customer_Adjusted_Quantity__c = 1, UNITY_Tax_Code__c = 'Test', UNITY_Total_Cost__c = 7, UNITY_Not_Billable__c = false,  MSPFS_MSP_Cost__c = 5);
        orderItems.add(oi2);
        insert orderItems;
    }

    @isTest 
    static void testNoRecords() {

        setup();

        
        MSPFS_IntercompanyProcessingBatch intercompanyBatch = new MSPFS_IntercompanyProcessingBatch();
        intercompanyBatch.query = 'SELECT Id,CaseId,WOrkOrderNumber,MSPFS_Intercompany_MSP_Revenue_Processed__c,MSPFS_Intercompany_Transfer__c,Status,UNITY_Attachment_Compliant__c,UNITY_Accepted_Vendor__c,UNITY_Accepted_Vendor__r.BU_Unique_Field__c,UNITY_Business_Unit_Account__c FROM WorkOrder';
        
        Test.startTest();

        createWOsWithItems();
        
        Database.executeBatch( intercompanyBatch, 10 );
        Test.stopTest();
    }

}