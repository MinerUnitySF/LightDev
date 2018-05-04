@isTest
private class Test_AmountCToAmount {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        Account acct = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert acct;
        
        String rtid = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'NMS_Opportunities' LIMIT 1].Id;
        Opportunity opp = new Opportunity();
        opp.Name = 'Opp Name';
        opp.AccountId = acct.Id;
        opp.Number_of_Locations__c = 33;
        opp.Revenue_Location__c = 1;
        opp.CloseDate = system.today();
        opp.Send_Close_Date_Email__c = false;
        opp.StageName = 'Prospecting';
        opp.Win_loss_reasons__c = 'the reason';
        opp.RecordTypeId = rtid;
        insert opp;
        
        Opportunity opp_new = [select Amount,Amount__c from Opportunity where id = :opp.id];
        System.assertEquals(opp_new.Amount,opp_new.Amount__c);
        test.startTest();
            opp.Revenue_Location__c = 2;
            update opp_new;
        test.stopTest();
        Opportunity opp_new1 = [select Amount, Amount__c from Opportunity where id = :opp_new.id];
        System.assertEquals(opp_new1.Amount, opp_new1.Amount__c);
        
    }
}