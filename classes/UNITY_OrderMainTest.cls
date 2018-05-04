/*------------------------------------------------------------
Name:          UNITY_OrderMainTest
Author:        Krishna Kameneni
Company:       Minor
Description:   This class contains unit tests for validating the behavior of trigger UNITY_OrderMain
History:
01/28/2016     Krishna Kameneni(Perficient)    Added/Modified comments
,Indentation 
Added test method
------------------------------------------------------------*/
//@isTest(SeeAllData=true)
@isTest
private class UNITY_OrderMainTest{
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
    static testMethod void updateMissingRequiredDocumentation(){
        //Miner Test Data Set up
        TestDataProvider.setKeyValueStore();
        
        List<UNITY_General_Settings__c> generalSetting =new  List<UNITY_General_Settings__c>();
        system.debug(UNITY_General_Settings__c.getAll().values());
        if(UNITY_General_Settings__c.getAll().values()==null){
            
        
            UNITY_General_Settings__c setting1 = new UNITY_General_Settings__c(
                Name = 'Service Fee POLI Activity Type',
                UNITY_Description__c = 'Vendor Service Fee POLI Activity Type',
                UNITY_Value__c = 'Vendor Service Fee'
            );
            
            UNITY_General_Settings__c setting2 = new UNITY_General_Settings__c(
                Name = 'Service Fee POLI Type',
                UNITY_Description__c = 'Vendor Service Fee POLI Type',
                UNITY_Value__c = 'Vendor Services'
            );
            
            UNITY_General_Settings__c setting3 = new UNITY_General_Settings__c(
                Name = 'Service Fee Product Type',
                UNITY_Description__c = 'Vendor Service Fee Product Type',
                UNITY_Value__c = 'Vendor Service Fee'
            );
            
            UNITY_General_Settings__c setting4 = new UNITY_General_Settings__c(
                Name = 'Service Fee Product name',
                UNITY_Description__c = 'Vendor Service Fee Product Name',
                UNITY_Value__c = 'Vendor Service Fee'
            );
            
            UNITY_General_Settings__c setting5 = new UNITY_General_Settings__c(
                Name = 'PO_Invoiceable_Statuses',
                UNITY_Description__c = 'Comma separated list of statuses, when a PO should be invoiceable ',
                UNITY_Value__c = 'Final,Accepted'
            );
            
            generalSetting.add(setting1);
            generalSetting.add(setting2);
            generalSetting.add(setting3);
            generalSetting.add(setting4);
            generalSetting.add(setting5);
            insert generalSetting;
        }
        
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(2, 'Krishna', Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accounts.get(0).Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accounts.get(0).Id,accounts.get(1).Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accounts.get(0).id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Invoice__c> invoices = UNITY_TestDataFactory.createInvoices(2, cases.get(0).Id, accounts.get(0).Id);
        UNITY_Service_Contract__c serviceContract =new UNITY_Service_Contract__c();
        serviceContract.UNITY_Required_Documentation__c = 'Copy of Supplier Parts;Customer Required Sign Off';
        serviceContract.UNITY_Account__c = accounts.get(0).Id;
        insert serviceContract;
        WorkOrder wo =workOrders.get(0);
        wo.UNITY_Customer_Service_Contract__c =serviceContract.Id; 
        update wo;
        System.Test.startTest();
        
        //WorkOrder wo =[SELECT UNITY_Attachment_Compliant__c FROM WorkOrder WHERE id='a4O180000008YV0EAM' LIMIT 1];
        UNITY_Attachment__c attachment1 = new UNITY_Attachment__c();
        attachment1.Work_Order__c =wo.Id;
        attachment1.UNITY_Type__c ='Copy of Supplier Parts';
        insert attachment1;
        Order orderObj=new Order();
        orderObj.AccountId =  accounts.get(0).Id;
        orderObj.UNITY_Invoice__c=invoices.get(0).Id;
        orderObj.FSO__WorkOrder__c = wo.Id;
        orderObj.Status ='Draft';
        orderObj.EffectiveDate =System.today();
        insert orderObj;
        /*UNITY_Invoice__c invoiceObj = [SELECT id ,UNITY_Missing_Required_Documentation__c  FROM UNITY_Invoice__c where Id =:invoices.get(0).Id LIMIT 1];
    System.assertEquals(false,invoiceObj.UNITY_Missing_Required_Documentation__c);
    UNITY_Attachment__c attachment2 = new UNITY_Attachment__c();
    attachment2.Work_Order__c =wo.Id;
    attachment2.UNITY_Type__c ='Copy of Vendor Invoices';
    insert attachment2;
    update orderObj;
    UNITY_Invoice__c invoiceObj1 = [SELECT id ,UNITY_Missing_Required_Documentation__c  FROM UNITY_Invoice__c where Id =:invoices.get(0).Id LIMIT 1];
    System.assertEquals(false,invoiceObj.UNITY_Missing_Required_Documentation__c);*/
            //delete attachment1;
            /*delete orderObj;
    UNITY_Invoice__c invoiceObj2 = [SELECT id ,UNITY_Missing_Required_Documentation__c  FROM UNITY_Invoice__c where Id =:invoices.get(0).Id LIMIT 1];
    System.assertEquals(false,invoiceObj.UNITY_Missing_Required_Documentation__c);
    Order orderObj1=new Order();
    orderObj1.UNITY_Invoice__c=invoices.get(0).Id;
    orderObj1.FSO__WorkOrder__c = wo.Id;
    orderObj1.Status ='Draft';
    orderObj1.EffectiveDate =System.today();
    insert orderObj1;*/
        
        System.Test.stopTest();
    }
}