@isTest
public class UNITY_UserTriggerHandlerTest {
    
    static testMethod void userTriggerNoTradesSuccess() {
        
        // create accounts
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(1,null);
        // create contacts
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(1,accounts.get(0).Id);
        
        Test.startTest();
        // create users
        List<User> users = UNITY_TestDataFactory.createUsersTechnician(1,contacts.get(0).Id);
        Test.stopTest();
        
        System.assert([SELECT Id FROM FSO__SkillUser__c].isEmpty(),'Should not have user skills in the system.');
        
    }
    
    static testMethod void userTriggerAssignSkillsSuccess() {
        // create accounts
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(1,null);
        // create contacts
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(1,accounts.get(0).Id);
        // create skills
        List<FSO__Skill__c> skills = UNITY_TestDataFactory.createSkills(3);
        // create trades
        List<UNITY_Vendor_Trade__c> vendorTrades = UNITY_TestDataFactory.createTrades(skills,accounts);
        
        Test.startTest();
        // create users
        List<User> users = UNITY_TestDataFactory.createUsersTechnician(1,contacts.get(0).Id);
        Test.stopTest();
        System.assert([SELECT Id FROM FSO__SkillUser__c].size() == vendorTrades.size(),'Should have '+vendorTrades.size() +'user skills in the system.');
        
    }
    
    // Exclude Miner Region Office accounts
    static testMethod void userTriggerNoAssignSkillForAcountMiner() {
        
        // create accounts
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(1,UNITY_Constants.ACCOUNT_MINER_RECORDTYPE);
        // create contacts
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(1,accounts.get(0).Id);
        // create skills
        List<FSO__Skill__c> skills = UNITY_TestDataFactory.createSkills(3);
        // create trades
        List<UNITY_Vendor_Trade__c> vendorTrades = UNITY_TestDataFactory.createTrades(skills,accounts);
        
        Test.startTest();
        // create users
        List<User> users = UNITY_TestDataFactory.createUsersTechnician(1,contacts.get(0).Id);
        Test.stopTest();
        
        System.assert([SELECT Id FROM FSO__SkillUser__c].isEmpty(),'Should not have user skills in the system because the accounts are miner.');
        
    }

    // share work orders to the customer user related to WO.AccountId == (user.Contact.AccountId == user.AccountId)
    static testMethod void shareWorkOrdersToNewCustomer() {
        
        // create accounts
        Account accountCustomer = UNITY_TestDataFactory.createAccounts(1,'Site/Location',UNITY_Constants.ACCOUNT_CUSTOMER_RECORDTYPE).get(0);
        Account accountVendor = UNITY_TestDataFactory.createAccounts(1,'Customer',UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE).get(0);
        // create contacts
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(1,accountCustomer.Id);
        List<Case> cases = UNITY_TestDataFactory.createCases(2,accountCustomer.Id,accountVendor.Id,contacts.get(0).Id,UNITY_Constants.CASE_SERVICE_REQUEST_RECORDTYPE);
        List<UNITY_Service_Contract__c> serviceContracts = UNITY_TestDataFactory.createServiceContracts(1, accountCustomer.Id);
        List<WorkOrder> workOrders = UNITY_TestDataFactory.createWorkOrders(2,cases.get(0).Id,accountCustomer.Id,serviceContracts.get(0).Id,UNITY_Constants.WO_SERVICE_REQUEST_RECORDTYPE);
        for(WorkOrder workOrder : workOrders) {
            workOrder.accountId = accountCustomer.Id;
        }
        update workOrders;
        
        Test.startTest();
        // create users
        List<User> users = UNITY_TestDataFactory.createUsers(1,contacts.get(0).Id,[SELECT Id FROM Profile WHERE Name = 'UNITY_Customer'][0].Id);
        Test.stopTest();
        
        System.assert(![SELECT Id, UserOrGroupId, AccessLevel, RowCause 
                       FROM WorkOrderShare 
                       WHERE RowCause = 'Manual' AND
                             ParentId IN :UNITY_Utils.joiningByIdList(workOrders) AND 
                             UserOrGroupId IN :UNITY_Utils.joiningByIdList(users)].isEmpty());
    }
    
}