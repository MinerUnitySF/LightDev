@isTest
public class UNITY_ContactTriggerHandlerTest {
    /*
    static testMethod void handleTradeVendorSuccessOneRecordInsert() {
        
        // create accounts
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(2,UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE);
        // create skill
        List<ProfileSkill> skills = UNITY_TestDataFactory.createSkills(3);
        // create vendor trades, relationship vendor trades/skill/accounts
        List<UNITY_Vendor_Trade__c> vendorTrades = UNITY_TestDataFactory.createTrades(skills,accounts);
        
        Test.startTest();
        
        // insert a contact
        Contact newContact = UNITY_TestDataFactory.createContact('John','Doe',accounts.get(0).Id);
        
        Test.stopTest();
        
        //verify the Vendor Trades with the Skill Users
         List<ProfileSkillUser> skillUsers = [SELECT Id,ProfileSkillId,UserId FROM ProfileSkillUser];
        
        System.assert(skillUsers.size() == 1,'Should have one record of type ProfileSkillUser');
        
        ProfileSkillUser skillUser = skillUsers.get(0);
        
        Boolean shouldBeOne = false;
        for(UNITY_Vendor_Trade__c vendorTrade : vendorTrades) {
            shouldBeOne = vendorTrade.Trade__c == skillUser.ProfileSkillId;
            if(shouldBeOne) {
                break;
            }
        }
        
        System.assert(shouldBeOne,'Should have a skill related with a vendor trade and skill user');
        
    } 
    
    static testMethod void handleTradeVendorSuccessOneRecordUpdate() {
        
        // create accounts
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(2,UNITY_Constants.ACCOUNT_VENDOR_RECORDTYPE);
        // create skill
        List<ProfileSkill> skills = UNITY_TestDataFactory.createSkills(3);
        // create vendor trades, relationship vendor trades/skill/accounts
        List<UNITY_Vendor_Trade__c> vendorTrades = UNITY_TestDataFactory.createTrades(skills,accounts);
        
        Test.startTest();
        
        // update a contact        
        Contact updateContact = UNITY_TestDataFactory.createContact('Jane','Smith',null);
        
        updateContact.AccountId = accounts.get(accounts.size()-1).Id;
        
        update updateContact;
        
        Test.stopTest();
        
        //verify the Vendor Trades with the Skill Users
         List<ProfileSkillUser> skillUsers = [SELECT Id,ProfileSkillId,UserId FROM ProfileSkillUser];
        
        System.assert(skillUsers.size() == 1,'Should have one record of type ProfileSkillUser');
        
        ProfileSkillUser skillUser = skillUsers.get(0);
        
        Boolean shouldBeOne = false;
        for(UNITY_Vendor_Trade__c vendorTrade : vendorTrades) {
            shouldBeOne = vendorTrade.Trade__c == skillUser.ProfileSkillId;
            if(shouldBeOne) {
                break;
            }
        }
        
        System.assert(shouldBeOne,'Should have a skill related with a vendor trade and skill user');
        
    } 
    */
    
}