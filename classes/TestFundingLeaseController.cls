@isTest
public class TestFundingLeaseController{
     public static testMethod void testFundingLeaseController(){
        genesis__Applications__c a = genesis.TestHelper.createApplication();
        
        genesis.TestHelper th1 = new genesis.TestHelper();
        ApexPages.StandardController sc = new ApexPages.StandardController(a);
        FundingLeaseController ctrl  = new FundingLeaseController(sc);
        
        ctrl.saveApp();
    }
    
}