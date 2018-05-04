@isTest
public class UNITY_WorkOrderLineControllerTest {

    static testMethod void retrieveWorkOrder() {
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);

        System.assert(!workOrders.isEmpty());
        Test.startTest();
        UNITY_WorkOrderLineController workOrderLineController = new UNITY_WorkOrderLineController();
        workOrderLineController.workOrderId = workOrders.get(0).Id;
        //System.assert(workOrderLineController.items.isEmpty(),'The items are not empty: '+workOrderLineController.items);
        Test.stopTest();
        
    }
    
}