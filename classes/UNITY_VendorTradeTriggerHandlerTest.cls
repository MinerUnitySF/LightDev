@isTest
public class UNITY_VendorTradeTriggerHandlerTest {

    static testMethod void vendorTradeAddDeleteSkillUsersSuccess() {
        
        // create accounts
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(1,null);
        // create contacts
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(1,accounts.get(0).Id);
        // create users
        List<User> users = UNITY_TestDataFactory.createUsersTechnician(1,contacts.get(0).Id);
        // create skills
        List<FSO__Skill__c> skills = UNITY_TestDataFactory.createSkills(3);
        
        Test.startTest();
        UNITY_Vendor_Trade__c vendorTrade = new UNITY_Vendor_Trade__c(Vendor__c=accounts.get(0).Id,
                                                                      Trade__c=skills.get(0).Id);
        insert vendorTrade;
        
        List<FSO__SkillUser__c > skillUsers = [SELECT Id,FSO__Skill__c ,FSO__User__c FROM FSO__SkillUser__c ];
        System.assert(skillUsers.size() == 1,'Should have one record of type FSO__SkillUser__c , '+skillUsers.size());
        FSO__SkillUser__c skillUser = skillUsers.get(0);
        System.assertEquals(skillUser.FSO__Skill__c, skills.get(0).Id,'Should have the profileSkillId: '+skillUser.FSO__Skill__c);
        System.assertEquals(skillUser.FSO__User__c, users.get(0).Id,'Should have the user id: '+skillUser.FSO__User__c);
        
        delete vendorTrade;
        
        skillUsers = [SELECT Id,FSO__Skill__c ,FSO__User__c FROM FSO__SkillUser__c ];
        System.assert(skillUsers.isEmpty(),'Should not have records of type FSO__SkillUser__c , '+skillUsers.size());
        
        Test.stopTest();
        
    }
    
    static testMethod void vendorTradeDuplicatedFail() {
        
        // create accounts
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(1,null);
        // create contacts
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(1,accounts.get(0).Id);
        // create users
        List<User> users = UNITY_TestDataFactory.createUsersTechnician(1,contacts.get(0).Id);
        // create skills
        List<FSO__Skill__c> skills = UNITY_TestDataFactory.createSkills(3);
        
        Test.startTest();
        UNITY_Vendor_Trade__c vendorTrade = new UNITY_Vendor_Trade__c(Vendor__c=accounts.get(0).Id,
                                                                      Trade__c=skills.get(0).Id);
        insert vendorTrade;
        
        try {
            UNITY_Vendor_Trade__c vendorTradeDup = vendorTrade.clone();
            // Insertion fails because of duplicated vendor above.
            insert vendorTradeDup;
            System.assert(false,'Should be an exception when insert duplicated vendor trades');
        } catch(Exception ex) {

        }
        
        Test.stopTest();
        
    }
    
    static testMethod void vendorTradeNoUsersSuccess() {
        
        // create accounts
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(1,null);
        // create contacts
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(1,accounts.get(0).Id);
        // create skills
        List<FSO__Skill__c> skills = UNITY_TestDataFactory.createSkills(3);
        
        Test.startTest();
        UNITY_Vendor_Trade__c vendorTrade = new UNITY_Vendor_Trade__c(Vendor__c=accounts.get(0).Id,
                                                                      Trade__c=skills.get(0).Id);
        insert vendorTrade;
        
        try {
            UNITY_Vendor_Trade__c vendorTradeDup = vendorTrade.clone();
            // Insertion fails because of duplicated vendor above.
            insert vendorTradeDup;
            System.assert(false,'Should be an exception when insert duplicated vendor trades');
        } catch(Exception ex) {

        }
        
        Test.stopTest();
        
    }
    
}