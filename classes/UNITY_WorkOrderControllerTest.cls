@isTest
public class UNITY_WorkOrderControllerTest {
    
    static testMethod void workOrderCheckRetrieveUserSuccess() {
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Service_Contract__c> serviceContracts = UNITY_TestDataFactory.createServiceContracts(1, accountCustomer.Id);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,serviceContracts.get(0).Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
         
        List<User> users = UNITY_TestDataFactory.createUsersTechnician(1,contacts.get(0).Id);
        
        User user = users.get(0);
        
        Test.startTest();
        UNITY_WorkOrderController workOrderController = new UNITY_WorkOrderController();
        workOrderController.relatedTo = workOrders.get(0);
        UNITY_WorkOrderAssignmentController workOrderAssignmentController = new UNITY_WorkOrderAssignmentController();
        workOrderAssignmentController.relatedTo = workOrders.get(0);

        Test.stopTest();
        
       // System.assertEquals(workOrderController.contactUser.Id, user.Id, 'Should be the same user, '+user.Id+' and '+workOrderController.contactUser.Id);
    }

}