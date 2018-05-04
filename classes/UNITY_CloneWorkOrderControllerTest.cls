/*------------------------------------------------------------
Name:          UNITYCloneWorkOrderControllerTest
Author:        Krishna Kamineni
Company:       Minor
Description:   This class contains unit tests for validating the behavior of Apex classe:UNITYCloneWorkOrderController
History:
1/21/2016      Krishna Kamineni

------------------------------------------------------------*/
@isTest
private class UNITY_CloneWorkOrderControllerTest {


    static testMethod void testCloneWorkOrder() {
        Test.startTest();
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(2,'Customer',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accounts.get(0).Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accounts.get(0).Id,accounts.get(1).Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id, accounts[0].Id, UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        
        WorkOrder wo1 =workOrders.get(0);
        PageReference pageRef = Page.UNITY_clone_workorder;
        pageRef.getParameters().put('id', wo1.id);
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(wo1);
        UNITY_CloneWorkOrderController ctrl = new UNITY_CloneWorkOrderController(sc);
        ctrl.cloneWorkOrder();
        wo1.Subject ='GSM-1';
        ApexPages.StandardController sc1 = new ApexPages.StandardController(wo1);
        UNITY_CloneWorkOrderController ctrl1 = new UNITY_CloneWorkOrderController(sc1);
        ctrl1.wo = null;
        ctrl1.cloneWorkOrder();
        Test.stopTest();
            
    }
   
}