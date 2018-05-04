/*------------------------------------------------------------
Name:          UNITY_NewOrderURController
Author:        Hao Dong
Company:       Salesforce
Description:   This class creates new usage request (Order) from WorkOrder
History:
3/22/2016      Hao Dong
------------------------------------------------------------*/
@isTest
private class UNITY_NewOrderURControllerTest {
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
    static testMethod void testNewOrderUR(){
        /*Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
              */

        Map<String,Object> caseFields                  = UNITY_TestDataFactory.MOCKUP_CASE_FIELDS;
        Map<String,Object> skillFields                 = UNITY_TestDataFactory.MOCKUP_FSO_SKILL_FIELDS;
        Map<String,Object> contactFields               = UNITY_TestDataFactory.MOCKUP_CONTACT_FIELDS;

        Map<String,Object> accountFields               = UNITY_TestDataFactory.MOCKUP_ACCOUNT_FIELDS;
        Map<String,Object> workOrderFields             = UNITY_TestDataFactory.MOCKUP_WORK_ORDER_FIELDS;
        Map<String,Object> serviceContractFields       = UNITY_TestDataFactory.MOCKUP_SERVICE_CONTRACT_FIELDS;
		
        TestDataProvider.setKeyValueStore();

        // Create Customer Account
        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE);
        accountFields.put('Type', 'Customer');

        Account customer = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);
        insert customer;


        // Create Vendor Account
        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE);
        accountFields.put('Type', 'Vendor');


        Account vendor = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);
        insert vendor;

        // Create BU Account
        accountFields.put('Type', 'Business Unit');
        accountFields.put('recordTypeId', UNITY_Constants.ACCOUNT_MINER_RECORDTYPE);
        accountFields.put('UNITY_Business_Unit__c', 'MNS');
        accountFields.put('UNITY_Service_Report_Template__c' , 'SRT');

        Account minerAccount   = (Account)UNITY_TestDataFactory.createObject(1, Account.getSObjectType() , accountFields).get(0);
        insert minerAccount;

        // Create Customer contact
        contactFields.put('AccountId', customer.id);

        Contact customerContact = (Contact)UNITY_TestDataFactory.createObject(1, Contact.getSObjectType() , contactFields).get(0);
        insert customerContact;

        // Create Skill
        FSO__Skill__c onSkill = (FSO__Skill__c)UNITY_TestDataFactory.createObject(1, FSO__Skill__c.getSObjectType() , skillFields).get(0);
        insert onSkill;

        caseFields.put('Status'           , 'Verified');
        caseFields.put('AccountId'        , customer.id);
        caseFields.put('ContactId'        , customerContact.id);
        caseFields.put('Customer__c'      , customer.id);
        caseFields.put('RecordTypeId'     , UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        caseFields.put('UNITY_Trade__c'   , onSkill.id);
        caseFields.put('UNITY_Work_Window_End__c'   , Date.today().addDays(10));
        caseFields.put('UNITY_Work_Window_Begin__c' , Date.today());
        caseFields.put('UNITY_Business_Unit__c' , 'MNS');
        caseFields.put('UNITY_Business_Unit_Account__c' , minerAccount.Id);

        List<Case> cases = (List<Case>) UNITY_TestDataFactory.createObject(2, Case.getSObjectType(), caseFields);
        insert cases;

        // Create Customer Service Contract 
        serviceContractFields.put('UNITY_Business_Unit__c', 'MNS');
        serviceContractFields.put('UNITY_Account__c', customer.id);
        serviceContractFields.put('UNITY_Signature_Template__c', 'Something');
        serviceContractFields.put('UNITY_Required_Documentation__c', 'Customer-Specific Service Report Sign');
        UNITY_Service_Contract__c c_sc  = (UNITY_Service_Contract__c)UNITY_TestDataFactory.createObject(1, UNITY_Service_Contract__c.getSObjectType(), serviceContractFields).get(0);
        insert c_sc;


      
        workOrderFields.put('Subject'           , 'WO-Test');
        workOrderFields.put('AccountId'         , customer.id);
        workOrderFields.put('RecordTypeId'      , UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        workOrderFields.put('UNITY_Trade__c'    , onSkill.id);
        workOrderFields.put('UNITY_Agent__c'    , UserInfo.getUserId());
        workOrderFields.put('UNITY_Customer__c' , customer.id);
        workOrderFields.put('UNITY_Business_Unit__c' , 'MNS');
        workOrderFields.put('UNITY_Business_Unit_Account__c' , minerAccount.Id);
        workOrderFields.put('SFPS_FS_Is_Vendor_Dispatcher__c' , true);
        workOrderFields.put('UNITY_Customer_Service_Contract__c' , c_sc.id);

        List<WorkOrder> workOrders = new List<WorkOrder>();

        for(Case onCase :cases){
              workOrderFields.put('CaseId' , onCase.id);
              workOrders.addAll((List<WorkOrder>)UNITY_TestDataFactory.createObject(1, WorkOrder.getSObjectType(), workOrderFields));
        }
        insert workOrders;    
        Test.setMock(WebServiceMock.class, new AvataxCalloutMock());
        Test.startTest();
            UNITY_newOrderURController newURController = new UNITY_newOrderURController(new ApexPages.StandardController(workOrders.get(0)));

            //Create First UR
            newURController.newOrderUR();

            //Create Second UR
            newURController.newOrderUR();


        Test.stopTest();
    }
}