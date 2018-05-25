/** 
 * AccountTriggerHandlerUT
 * Clay Tomerlin
 * 7.10.2015
 * ctomerlin@mhs-corp.com
 */
@isTest
private class AccountTriggerHandler_UT {
    ////////////////////////////
    //First we build out data //
    ////////////////////////////
    @testSetup static void setupTestData(){
        ///////////////////
        //Role heirarchy //
        ///////////////////
        UserRole urTvp = new UserRole(Name = 'Territory VP');
        insert urTvp;
        UserRole urSM = new UserRole(Name = 'Sales Manager', ParentRoleId = urTvp.Id);
        insert urSM;
        UserRole urSR = new UserRole(Name = 'Sales Representative', ParentRoleId = urSM.Id );
        insert urSR;
        ////////////
        //Users// //
        ////////////
        //System admin
        User admin = TestDataProvider.getUser('Tim', 'System_Admin', 'System Administrator');
        admin.Ignore_Validations__c = true;
        //Territory VP
        User tvp = TestDataProvider.getUser('John', 'President', 'SVMX MD - Tech - Miner');
        tvp.UserRoleId = urTvp.Id;
        //Sales Managers
        User sm1 = TestDataProvider.getUser('Jane', 'Manager', 'SVMX MD - Tech - Miner');
        sm1.UserRoleId = urSM.Id;
        User sm2 = TestDataProvider.getUser('Sara', 'Manager', 'SVMX MD - Tech - Miner');
        sm2.UserRoleId = urSM.Id;
        //Sales Representative
        User rep = TestDataProvider.getUser('Jack', 'Representative', 'MinerCorp/DDM Sales');
        rep.UserRoleId = urSR.Id;
        rep.Super_Center__c = 'Miner-Central Texas';
        rep.Business_Unit__c = 'Miner Corp';
        rep.Ignore_Validations__c = true;
        //add them to our users
        List<User> users = new List<User>();
        users.add(admin);users.add(tvp);users.add(sm1);users.add(sm2);users.add(rep);
        insert users;
        String parentId = '';
        System.runAs(admin){
            ////////////////////////////////////
            //Custom setting: Org Wide Emails //
            ////////////////////////////////////
            Org_Wide_Emails__c owe1 = new Org_Wide_Emails__c(Name = 'President', UserId__c=urTvp.Id, Email__c='ctomerlin@minercorp.com');
            insert owe1;
            ///////////////////
            //AccountApprover//
            ///////////////////
            Account_Approver__c accapp1 = new Account_Approver__c(Name = 'Miner-Central Texas', User_Id__c = sm1.Id);
            insert accapp1;
            /* *****************
            ** Parent Account **
            ***************** */
            List<Account> parent = TestDataProvider.getAccounts(1, 'Parent Account', 'Parent Account');
            insert parent;
            parentId = parent[0].Id;
        }
        //Run as rep
        System.runAs(rep){
            //Create and insert account
            List<Account> accounts = TestDataProvider.getAccounts(3, 'Prospect Accounts', 'Prospect');
            for(Account a :accounts){
                a.ParentId = parentId;
            }
            insert accounts;
        }
    }
    
    public static TestMethod void test_AccountInsert(){
        //Get rep user
        User rep = [SELECT Id,FirstName,LastName FROM User WHERE LastName = 'Representative' LIMIT 1];
        //Get the parent account
        List<Account> parent = [SELECT Id,Name FROM Account WHERE Type = 'Parent Account' LIMIT 1];
        //Run as rep
        System.runAs(rep){
            //Create and insert account
            List<Account> accounts = TestDataProvider.getAccounts(3, 'Prospect Accounts', 'Prospect');
            accounts[0].ParentId = parent[0].Id;
            accounts[1].ParentId = null;
            accounts[1].Residential__c = true;
            insert accounts;
            List<Contact> contact = TestDataProvider.getContacts(1, accounts[1].id);
            insert contact;
            accounts[1].MH_Primary_Contact__c = contact[0].Id;
            accounts[0].UNITY_Ultimate_Parent__c = null;
            AccountTriggerHandler.isFirstTriggerRun_Before = true;
            AccountTriggerHandler.isFirstTriggerRun_After = true;
            update accounts;

        }
        rep.Super_Center__c = 'Miner-Houston';
        update rep;
        AccountTriggerHandler.isFirstTriggerRun_Before = true;
        AccountTriggerHandler.isFirstTriggerRun_After = true;
        System.runAs(rep){
            //Create and insert account
            List<Account> accounts = TestDataProvider.getAccounts(3, 'Prospect Accounts', 'Prospect');
            accounts[0].ParentId = parent[0].Id;
            try{
                insert accounts;
            }catch(Exception e){}
        }
    }
    
    public static TestMethod void test_AccountUpdate(){
        //Get rep user
        User rep = [SELECT Id,FirstName,LastName FROM User WHERE LastName = 'Representative' LIMIT 1];
        //Get the parent account
        List<Account> parent = [SELECT Id,Name FROM Account WHERE Type = 'Parent Account' LIMIT 1];
        //Change parent account name and update
        parent[0].Name = 'Changed';
        AccountTriggerHandler.isFirstTriggerRun_Before = true;
        update parent;
        List<Account> accounts = [SELECT Id,Name,ParentId,Ready_to_Convert__c FROM Account WHERE Type = 'Prospect'];
        //Run as rep
        System.runAs(rep){
            //Update the account
            List<Contact> contact = TestDataProvider.getContacts(1, accounts[1].id);
            insert contact;
            try{
                accounts[0].ParentId = null;
                accounts[0].Ready_to_Convert__c = true;
                accounts[0].Business_Unit__c = 'Miner Corp';
                AccountTriggerHandler.isFirstTriggerRun_Before = true;
                update accounts;
            }catch(Exception e){}
            try{
                accounts[1].ParentId = null;
                accounts[1].MH_Primary_Contact__c = null;
                accounts[1].Residential__c = true;
                accounts[1].Business_Unit__c = 'Miner Corp';
                accounts[1].Ready_to_Convert__c = true;
                AccountTriggerHandler.isFirstTriggerRun_Before = true;
                update accounts;
            }catch(Exception e){}
            accounts[0].ParentId = parent[0].Id;
            accounts[0].Ready_to_Convert__c = true;
            accounts[0].Business_Unit__c = 'Miner Corp';
            accounts[1].ParentId = null;
            accounts[1].MH_Primary_Contact__c = contact[0].Id;
            accounts[1].Residential__c = true;
            accounts[1].Business_Unit__c = 'Miner Corp';
            accounts[1].Ready_to_Convert__c = true;
            AccountTriggerHandler.isFirstTriggerRun_Before = true;
            try{
                update accounts;
            }catch(Exception e){
                
            }
            
        }
        
    }
    
        public static TestMethod void test_AccountTeamShare(){
        //Get rep user
        User rep = [SELECT Id,FirstName,LastName FROM User WHERE LastName = 'Representative' LIMIT 1];
        //Create an approver
        User userApprover = TestDataProvider.getUser('Approver', 'One', 'UNITY_FSL Administrator');
        insert userApprover;
        //Run as rep
        
        Account acct;
        
        System.runAs(rep){
            //Create and insert account
            acct = TestDataProvider.getAccounts(1, 'Prospect Accounts', 'Prospect')[0];
            acct.ParentId = null;
            acct.Residential__c = true;
            acct.Account_Approver__c = userApprover.Id;
            insert acct;
        }
            List<AccountShare> acctShare = [SELECT UserOrGroupId, AccountAccessLevel, AccountId FROM AccountShare WHERE AccountId = :acct.Id AND UserOrGroupId = :userApprover.Id];
            System.Assert(acctShare != null);
        
    }
    
    public static TestMethod void test_SLNotesUpdate(){
        //Get rep user
        User rep = [SELECT Id,FirstName,LastName FROM User WHERE LastName = 'Representative' LIMIT 1];

        //Create an approver
        User userApprover = TestDataProvider.getUser('Approver', 'One', 'UNITY_FSL Administrator');
        insert userApprover;

        //Run as rep
        Account acct;
        System.runAs(rep){
            //Create and insert account
            acct = TestDataProvider.getAccounts(1, 'Prospect Accounts', 'Prospect')[0];
            acct.ParentId = null;
            acct.Residential__c = true;
            acct.Account_Approver__c = userApprover.Id;
            acct.SL_Notes_Text__c = 'Notes 1';
            AccountTriggerHandler.isFirstTriggerRun_Before = true;
            insert acct;
        }

        AccountTriggerHandler.isFirstTriggerRun_Before = true;
        acct.SL_Notes_Text__c = 'Notes 2';
        update acct;
        
        List<Note> notes = [SELECT ParentId, Title, Body FROM Note WHERE ParentId = :acct.Id];
        System.Assert(notes.size() > 0);
        System.Assert(notes[0].Title.contains('SL Notes Update'));
    }
    
    public static TestMethod void test_SetUltimateParent(){
        //Get rep user
        User rep = [SELECT Id,FirstName,LastName FROM User WHERE LastName = 'Representative' LIMIT 1];

        //Run as rep
        Account acct;
        System.runAs(rep){
            //Create and insert account
            acct = TestDataProvider.getAccounts(1, 'Prospect Accounts', 'Prospect')[0];
            acct.ParentId = null;
            acct.Residential__c = false;
            AccountTriggerHandler.isFirstTriggerRun_Before = true;
            insert acct;
        }

        Test.startTest();
        
        //Get the parent account
        Account parent = [SELECT Id,Name FROM Account WHERE Type = 'Parent Account' LIMIT 1];
        
        //Assign the parent to account      
        AccountTriggerHandler.isFirstTriggerRun_After = true;
        acct.ParentId = parent.Id;
        update acct;
        
        //Create one more account to parent the parent account
        List<Account> ultimateParent = TestDataProvider.getAccounts(1, 'Customer', 'Customer');
        insert ultimateParent;
    
        //Assign ultimate parent to the parent
        parent.ParentId = ultimateParent[0].Id;
        update parent;
        
        Test.stopTest();
        
        //Test if 
        Account updatedAcct = [SELECT Id, Name, UNITY_Ultimate_Parent__c From Account Where Id = :acct.Id LIMIT 1];
        System.assert(updatedAcct.UNITY_Ultimate_Parent__c == ultimateParent[0].Id );

    }
}