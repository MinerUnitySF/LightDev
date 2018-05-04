/**
 * OpportunityTriggerHandlerUT
 * Clay Tomerlin
 * ctomerlin@mhs-corp.com
 * July 1 2015
 * 
 */
@isTest
private class OpportunityTriggerHandler_UT {
    
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
        List<User> users = new List<User>();
        //System admin
        User admin = TestDataProvider.getUser('Tim', 'System_Admin', 'System Administrator');
        admin.Ignore_Validations__c = true;
        //Territory VP
        User tvp = TestDataProvider.getUser('John', 'President', 'SVMX MD - Tech - Miner');
        tvp.UserRoleId = urTvp.Id;
        //Sales Managers
        User sm1 = TestDataProvider.getUser('Jane', 'Manager', 'SVMX MD - Tech - Miner');
        sm1.UserRoleId = urSM.Id;
        sm1.Super_Center__c = 'Miner-Central Texas';
        sm1.Business_Unit__c = 'Miner Corp';
        User sm2 = TestDataProvider.getUser('Sara', 'Manager', 'SVMX MD - Tech - Miner');
        sm2.UserRoleId = urSM.Id;
        sm2.Super_Center__c = 'Miner-Central Texas';
        sm2.Business_Unit__c = 'Miner Corp';
        sm2.Ignore_Validations__c = true;
        //Sales Representative
        User rep = TestDataProvider.getUser('Jack', 'Representative', 'MinerCorp/DDM Sales');
        rep.UserRoleId = urSR.Id;
        rep.Super_Center__c = 'Miner-Central Texas';
        rep.Business_Unit__c = 'Miner Corp';
        rep.Ignore_Validations__c = true;
        //add them to our users
        users.add(admin);users.add(tvp);users.add(sm1);users.add(sm2);users.add(rep);
        insert users;
        System.runAs(admin){
            ////////////////////////////////////
            //Custom setting: Org Wide Emails //
            ////////////////////////////////////
            Org_Wide_Emails__c owe1 = new Org_Wide_Emails__c(Name = 'President', UserId__c=urTvp.Id, Email__c='ctomerlin@minercorp.com');
            insert owe1;
            /////////////////////////////////////////
            //Custom Setting: HV Email Threshold// //
            /////////////////////////////////////////
            OppHighValue__c hv1 = new OppHighValue__c(Name='Equipment1', Threshold__c=25000,Type__c='Equipment',Who__c='Sales Manager, Territory VP');
            OppHighValue__c hv2 = new OppHighValue__c(Name='Equipment2', Threshold__c=50000,Type__c='Equipment',Who__c='Sales Manager, Territory VP, President');
            insert hv1; insert hv2;
            ////////////////////////
            //Email Templates// /
            ////////////////////////
            EmailTemplate et1 = new EmailTemplate(isActive = true, Name = 'Opportunity at risk Alert', DeveloperName = 'Opportunity_At_Risk_Alert', TemplateType = 'text', Subject='Opportunity TESTING at risk alert');
            et1.FolderId = UserInfo.getUserId();
            EmailTemplate et2 = new EmailTemplate(isActive = true, Name = 'Opportunity High Value', DeveloperName = 'Opportunity_High_Value', TemplateType = 'text', Subject='Opportunity TESTING high value alert');
            et2.FolderId = UserInfo.getUserId();
            insert et1;
            insert et2;
            
            //////////////
            //account// //
            //////////////
            List<Account> parAccts = TestDataProvider.getAccounts(1, 'Parent Account', 'Parent Account');
            insert parAccts;
            
            //now we make normal accounts and assign to the accounts
            List<Account> accts = TestDataProvider.getAccounts(3, 'Customer Account', 'Customer');
            for(Account acc: accts) {
               acc.ParentId = parAccts[0].Id;
            }
            insert accts;
        }
    }

    @isTest static void test_Opp_update() {
        //Get tyhe users
        User rep = [SELECT Id,FirstName,LastName FROM User WHERE LastName = 'Representative' LIMIT 1];
        User sm2 = [SELECT Id,Firstname,Lastname FROM User WHERE LastName = 'Manager' LIMIT 1];
        //Get Customer Accounts
        List<Account> accts = [SELECT Id,Name,Type FROM Account WHERE Type = 'Customer'];
        //////////////////
        //Opportunity// //
        //////////////////
        //we have to run this as a different user:
        System.runAs(rep){
            OpportunityTriggerHandler.isFirstTriggerRun_Before = true;
            OpportunityTriggerHandler.isFirstTriggerRun_After = true;
            Opportunity opp1 = new Opportunity(Name = 'Test Opp 1', StageName = 'Discovery', CloseDate = Date.today()+ 7, Status__c = 'Open', Amount = 25000, Sales_Cycle__c = '30 - 60', AccountId = accts[0].Id, Type = 'Equipment', OwnerId = rep.Id);
            insert opp1;    
        }
        System.runAs(sm2){
            OpportunityTriggerHandler.isFirstTriggerRun_Before = true;
            OpportunityTriggerHandler.isFirstTriggerRun_After = true;
            Opportunity opp2 = new Opportunity(Name = 'Test Opp 2', StageName = 'Discovery', CloseDate = Date.today()+ 9, Status__c = 'Open', Amount = 60000, Sales_Cycle__c = '30 - 60', AccountId = accts[0].Id, Type = 'Equipment', Business_Unit__c = '');
            insert opp2;
        }
        OpportunityTriggerHandler.isFirstTriggerRun_Before = true;
        OpportunityTriggerHandler.isFirstTriggerRun_After = true;
        Opportunity opp = [SELECT Id, Name, Amount, Stage_Change_Time_Stamp__c FROM Opportunity WHERE Name = 'Test Opp 1' LIMIT 1];
        opp.Amount = 50000;
        opp.Stage_Change_Time_Stamp__c = Date.today() - 1;
        opp.At_Risk__c = true;
        opp.At_Risk_Send_Email__c = true;
        opp.CloseDate = Date.today() + 10;
        update opp;
        //update opp again
        update opp;
        //Just to cover more...
        OpportunityTriggerHandler oth = new OpportunityTriggerHandler(false, 1);
		Boolean fromTrigger = oth.isTriggerContext;
    }
    
}