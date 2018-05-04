@isTest
public class UNITY_MuleCalloutOperationTest {

    @testSetup public static void setup() {
        UNITY_MuleSiteSettingUtilsTest.setUp();
        UNITY_Mule2Salesforce_MappingUtilsTest.setUp();
    }
    
    static testMethod void calloutVendorSuccess() {
        UNITY_MuleHttpCalloutMockImp calloutMock = new UNITY_MuleHttpCalloutMockImp(true);
        calloutMock.supposedEndPoint = UNITY_MuleSiteSettingUtils.getEndPoint(UNITY_MuleSiteSettingUtils.VENDOR);
        Test.setMock(HttpCalloutMock.class, calloutMock);
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(2,UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        Test.startTest();
        UNITY_MuleCalloutOperation.invokeCallOut(UNITY_Utils.joiningByIdList(accounts), 
                                                 UNITY_MuleSiteSettingUtils.VENDOR);
        Test.stopTest();
    }
    
    static testMethod void calloutVendorUnauthorized() {
        UNITY_MuleHttpCalloutMockImp calloutMock = new UNITY_MuleHttpCalloutMockImp(false);
        calloutMock.supposedEndPoint = UNITY_MuleSiteSettingUtils.getEndPoint(UNITY_MuleSiteSettingUtils.VENDOR);
        Test.setMock(HttpCalloutMock.class, calloutMock);
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(2,UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        Test.startTest();
        UNITY_MuleCalloutOperation.invokeCallOut(UNITY_Utils.joiningByIdList(accounts), 
                                                 UNITY_MuleSiteSettingUtils.VENDOR);
        Test.stopTest();
    }
    
    static testMethod void calloutCustomerSuccess() {
        UNITY_MuleHttpCalloutMockImp calloutMock = new UNITY_MuleHttpCalloutMockImp(true);
        calloutMock.supposedEndPoint = UNITY_MuleSiteSettingUtils.getEndPoint(UNITY_MuleSiteSettingUtils.CUSTOMER);
        Test.setMock(HttpCalloutMock.class, calloutMock);
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(2,UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        Test.startTest();
        UNITY_MuleCalloutOperation.invokeCallOut(UNITY_Utils.joiningByIdList(accounts), 
                                                 UNITY_MuleSiteSettingUtils.CUSTOMER);
        Test.stopTest();
    }
    
    static testMethod void calloutInvoiceSuccess() {
        //Miner Test Data Set up
        TestDataProvider.setKeyValueStore();
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        UNITY_MuleHttpCalloutMockImp calloutMock = new UNITY_MuleHttpCalloutMockImp(true);
        calloutMock.supposedEndPoint = UNITY_MuleSiteSettingUtils.getEndPoint(UNITY_MuleSiteSettingUtils.INVOICE);
        Test.setMock(HttpCalloutMock.class, calloutMock);
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Invoice__c> invoices = UNITY_TestDataFactory.createInvoices(2, cases.get(0).Id, accountVendor.Id);
        System.debug('invoices --->'+invoices);
        Test.startTest();
        UNITY_MuleCalloutOperation.invokeCallOut(UNITY_Utils.joiningByIdList(invoices), 
                                                 UNITY_MuleSiteSettingUtils.INVOICE);
        Test.stopTest();
    }
    
}