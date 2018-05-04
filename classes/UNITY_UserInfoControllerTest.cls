@isTest
public class UNITY_UserInfoControllerTest {
    
    static testMethod void userInfoCheckRetrieveUserSuccess() {
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(2);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accounts.get(0).Id);
        List<User> users = UNITY_TestDataFactory.createUsersTechnician(1,contacts.get(0).Id);
        
        User user = users.get(0);
        
        Test.startTest();
        UNITY_UserInfoController userInfoController = new UNITY_UserInfoController();
        userInfoController.userId = user.Id;
        
        System.assertEquals(userInfoController.userId, user.Id, 'Should be the same user, '+user.Id+' and '+userInfoController.userId);
        
        Test.stopTest();
    }
    
    static testMethod void userInfoCheckRetrieveContactSuccess() {
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(2);
        List<Contact> contacts = UNITY_TestDataFactory.createContacts(2,accounts.get(0).Id);
        List<User> users = UNITY_TestDataFactory.createUsersTechnician(1,contacts.get(0).Id);
        
        User user = users.get(0);
        Contact contact = contacts.get(0);
        
        Test.startTest();
        UNITY_UserInfoController userInfoController = new UNITY_UserInfoController();
        userInfoController.contactId = contact.Id;
        
        System.assertEquals(userInfoController.infoDetail.email, user.email, 'Should be the same email , '+user.email+' and '+userInfoController.infoDetail.email);
        
        Test.stopTest();
    }
    
    static testMethod void userInfoCheckRetrieveAccountSuccess() {
        List<Account> accounts = UNITY_TestDataFactory.createAccounts(2);
        Account acc = accounts.get(0);
        
        Test.startTest();
        UNITY_UserInfoController userInfoController = new UNITY_UserInfoController();
        userInfoController.accountId = acc.Id;
        
        System.assertEquals(userInfoController.infoDetail.name, acc.name, 'Should be the account name , '+acc.name+' and '+userInfoController.infoDetail.name);
        
        Test.stopTest();
    }

}