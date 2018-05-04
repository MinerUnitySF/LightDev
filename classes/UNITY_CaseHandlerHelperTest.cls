@isTest
public with sharing class UNITY_CaseHandlerHelperTest {

    @testSetup 
    static void init() {
        
        List<Account> accountList = new List<Account>();
        
        Account newAccount1 = new Account();
        
        newAccount1.RecordTypeId  = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        newAccount1.Name = 'Test Site Location';
        newAccount1.Type = 'Site/Location';
        newAccount1.BillingCity = 'Brooklyn';
        newAccount1.BillingStateCode = 'NY';
        newAccount1.BillingStreet = '123 Fake St.';
        newAccount1.BillingPostalCode = '123456';
        newAccount1.Account_Status__c = 'Active';
        accountList.add(newAccount1);
        
        Account newAccount2 = new Account();
        
        newAccount2.RecordTypeId  = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        newAccount2.Name = 'Test Parent Account';
        newAccount2.Type = 'Customer';
        newAccount2.BillingCity = 'Brooklyn';
        newAccount2.BillingStateCode = 'NY';
        newAccount2.BillingStreet = '123 Fake St.';
        newAccount2.BillingPostalCode = '123456';
        newAccount2.Account_Status__c = 'Active';
        accountList.add(newAccount2);
        
        Account newAccount3 = new Account();
        
        newAccount3.RecordTypeId  = UNITY_Constants.ACCOUNT_MINER_RECORDTYPE;
        newAccount3.Name = 'Test 3rd Party';
        newAccount3.Type = 'Customer';
        newAccount3.BillingCity = 'Brooklyn';
        newAccount3.BillingStateCode = 'NY';
        newAccount3.BillingStreet = '123 Fake St.';
        newAccount3.BillingPostalCode = '123456';
        newAccount3.Account_Status__c = 'Active';
        newAccount3.UNITY_LOC__c = '0123';
        newAccount3.UNITY_Subscriber_ID__c = '0123456789';
        accountList.add(newAccount3);
        
        insert accountList;
        
        Account newAccount4 = new Account();
        
        newAccount4.RecordTypeId  = UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE;
        newAccount4.Name = 'Test Child Account';
        newAccount4.ParentId = newAccount2.Id;
        newAccount4.UNITY_Bill_To_Account__c = newAccount2.Id;
        newAccount4.Type = 'Site/Location';
        newAccount4.BillingCity = 'Brooklyn';
        newAccount4.BillingStateCode = 'NY';
        newAccount4.BillingStreet = '123 Fake St.';
        newAccount4.BillingPostalCode = '123456';
        newAccount4.Account_Status__c = 'Active';
        
        insert newAccount4;
        
        List<Contact> contactList = new List<Contact>();
        
        Contact newContact1 = new Contact();
        
        newContact1.LastName = 'Test1';
        newContact1.AccountId = newAccount1.Id;
        contactList.add(newContact1);
        
        Contact newContact2 = new Contact();
        
        newContact2.LastName = 'Test2';
        newContact2.AccountId = newAccount4.Id;
        contactList.add(newContact2);
        
        insert contactList;
        
        List<UNITY_Service_Contract__c> serviceContractList = new List<UNITY_Service_Contract__c>();
        
        List<UNITY_Service_Contract_Line_Item__c> serviceContractLineItemList = new List<UNITY_Service_Contract_Line_Item__c>();
        
        UNITY_Service_Contract__c serviceContract1 = new UNITY_Service_Contract__c();
        
        serviceContract1.UNITY_Account__c = newAccount1.Id;
        serviceContract1.UNITY_Business_Unit__c = 'MNS';
        serviceContract1.UNITY_IS_Active__c = true;
        serviceContract1.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        
        serviceContractList.add(serviceContract1);
        
        UNITY_Service_Contract__c serviceContract2 = new UNITY_Service_Contract__c();
        
        serviceContract2.UNITY_Account__c = newAccount2.Id;
        serviceContract2.UNITY_Business_Unit__c = 'MNS';
        serviceContract2.UNITY_IS_Active__c = true;
        serviceContract2.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        
        serviceContractList.add(serviceContract2);
        
        UNITY_Service_Contract__c serviceContract3 = new UNITY_Service_Contract__c();
        
        serviceContract3.UNITY_Account__c = newAccount3.Id;
        serviceContract3.UNITY_Business_Unit__c = 'MNS';
        serviceContract3.UNITY_IS_Active__c = true;
        serviceContract3.RecordTypeId = UNITY_Constants.SC_SERVICE_REQUEST_RECORDTYPE;
        
        serviceContractList.add(serviceContract3);
        
        insert serviceContractList;
    }
    
    static testMethod void setServiceContractOnCaseTest() {
        
        Test.startTest();
            
            Account siteLocationAcc = [select id from Account where Name = 'Test Site Location'];
            Account thirdPartyAcc = [select id from Account where Name = 'Test 3rd Party'];
            Account withParentAcc = [select id from Account where Name = 'Test Child Account'];
            
            Contact contactRecord1 = [select id from Contact where LastName = 'Test1'];
            Contact contactRecord2 = [select id from Contact where LastName = 'Test2'];
            
            List<Case> caseList = new List<Case>();
            
            Case newCase1 = new Case();
        
            newCase1.RecordTypeId = UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE;
            newCase1.Subject = 'Test Subject';
            newCase1.AccountId = siteLocationAcc.Id;
            newCase1.ContactId = contactRecord1.Id;
            newCase1.UNITY_Customer__c = siteLocationAcc.Id;
            newCase1.UNITY_Business_Unit__c = 'MNS';
            newCase1.Status = 'Verified';
            newCase1.UNITY_NTE_Threshold__c = 2000;
        
            caseList.add(newCase1);
            
            //3rd Party
            Case newCase2 = new Case();
        
            newCase2.RecordTypeId = UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE;
            newCase2.Subject = 'Test Subject';
            newCase2.AccountId = siteLocationAcc.Id;
            newCase2.ContactId = contactRecord1.Id;
            newCase2.UNITY_Customer__c = thirdPartyAcc.Id;
            newCase2.UNITY_Business_Unit__c = 'MNS';
            newCase2.Status = 'Verified';
            newCase2.UNITY_NTE_Threshold__c = 2000;
        
            caseList.add(newCase2);
            
            // account with parent
            Case newCase3 = new Case();
        
            newCase3.RecordTypeId = UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE;
            newCase3.Subject = 'Test Subject';
            newCase3.AccountId = withParentAcc.Id;
            newCase3.ContactId = contactRecord2.Id;
            newCase3.UNITY_Customer__c = thirdPartyAcc.Id;
            newCase3.UNITY_Business_Unit__c = 'MNS';
            newCase3.Status = 'Verified';
            newCase3.UNITY_LOC__c = '0123';
            newCase3.UNITY_Subscriber_ID__c = '0123456789';
            //newCase3.UNITY_NTE_Threshold__c = 2000;
            
            caseList.add(newCase3);
                           
            insert caseList;
            UNITY_CaseHandlerHelper.populateNTEFromServiceContract(caseList);
            
        Test.stopTest();
    }
}