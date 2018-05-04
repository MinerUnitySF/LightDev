@isTest
public class UNITY_SharingUtilTest {
    
    static testMethod void testManualShareReadDelete(){
        //Miner Test Data Set up
        TestDataProvider.setKeyValueStore();
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Service_Contract__c> serviceContracts = UNITY_TestDataFactory.createServiceContracts(1, accountCustomer.Id);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,serviceContracts.get(0).Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        List<User> technicians = UNITY_TestDataFactory.createUsersTechnician(1, contacts.get(0).Id);
        
        Test.startTest();
        List<UNITY_Invoice__c> invoices = UNITY_TestDataFactory.createInvoices(10,cases.get(0).Id,accountCustomer.Id);
        UNITY_SharingUtil.manualShareCreateReadWriteBulk(invoices,UNITY_Utils.joiningByIdList(technicians) , UNITY_Invoice__Share.SObjectType);
        UNITY_SharingUtil.manualShareCreateReadOnlyBulk(invoices,UNITY_Utils.joiningByIdList(technicians) , UNITY_Invoice__Share.SObjectType);
        UNITY_SharingUtil.manualShareCreateFullAccessBulk(invoices,UNITY_Utils.joiningByIdList(technicians) , UNITY_Invoice__Share.SObjectType);
        UNITY_SharingUtil.manualShareDelete(invoices, UNITY_Invoice__Share.SObjectType);
        
        Test.stopTest();        
    }
    
    static testMethod void testManualShareReadSuccess(){
        
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Service_Contract__c> serviceContracts = UNITY_TestDataFactory.createServiceContracts(1, accountCustomer.Id);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,serviceContracts.get(0).Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        List<User> technicians = UNITY_TestDataFactory.createUsersTechnician(1, contacts.get(0).Id);
        
        Test.startTest();
        List<UNITY_Proposal__c> proposals = UNITY_TestDataFactory.createQuote(10,cases.get(0).Id,workOrders.get(0).Id,accountCustomer.Id,UserInfo.getUserId());
        Test.stopTest(); 
        
        //TODO_TEST_COVERAGE
        /*System.assert(![SELECT Id, UserOrGroupId, AccessLevel, RowCause 
                       FROM UNITY_Proposal__Share 
                       WHERE ParentId IN :UNITY_Utils.joiningByIdList(proposals) AND 
                             UserOrGroupId IN :UNITY_Utils.joiningByIdList(technicians)].isEmpty());*/
        
    }

}