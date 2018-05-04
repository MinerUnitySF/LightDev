@isTest
public class TestCreditReportPullCtrl {
    
    public static testMethod void testCreditReportPullCtrl(){
        Contact c = genesis.TestHelper.createContact();
        genesis__Applications__c a = genesis.TestHelper.createApplication();
        genesis.TestHelper th1 = new genesis.TestHelper();
        th1.createCreditPullParameters(false,false,false);
        
        ints__Credit_Report__c cr = new ints__Credit_Report__c();
        cr.genesis__Open_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 100;
        cr.genesis__Open_Bankruptcy_Currently_Used__c = 1789;
        cr.genesis__Dismissed_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 50;
        cr.genesis__Dismissed_Bankruptcy_Currently_Used__c = 1400;
        cr.genesis__Delinquent_Child_Support_Amount__c = 1345;
        cr.genesis__Involuntary_Repossession__c = 345;
        cr.genesis__Vehicle_Charge_Off_Currently_Used__c = 678;
        cr.ints__Contact__c = c.Id;
        insert cr;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(a);
        CreditReportPullCtrl ctrl  = new CreditReportPullCtrl(sc);
        CreditReportPullCtrl.pullCreditForBorrower(null,a.Id);
        
        System.assertEquals(CreditReportPullCtrl.pullCreditForBorrower(null,a.Id),null);
    }

     public static testMethod void testCreditReportPullCtrl1(){
        Contact c = genesis.TestHelper.createContact();
        genesis__Applications__C a = genesis.TestHelper.createApplication();
        genesis.TestHelper th1 = new genesis.TestHelper();
        th1.createCreditPullParameters(false,false,false);
        
         ints__Credit_Report__c cr = new ints__Credit_Report__c();
        cr.genesis__Open_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 100;
        cr.genesis__Open_Bankruptcy_Currently_Used__c = 1789;
        cr.genesis__Dismissed_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 50;
        cr.genesis__Dismissed_Bankruptcy_Currently_Used__c = 1400;
        cr.genesis__Delinquent_Child_Support_Amount__c = 1345;
        cr.genesis__Involuntary_Repossession__c = 345;
        cr.genesis__Vehicle_Charge_Off_Currently_Used__c = 678;
        cr.ints__Contact__c = c.Id;
        insert cr;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(a);
        CreditReportPullCtrl ctrl = new CreditReportPullCtrl(sc);
        System.assertEquals(CreditReportPullCtrl.pullCreditForBorrower(c.Id,a.Id),
        'Credit pull successful.');
    }
    
    public static testMethod void testCreditReportPullCtrl2(){
        Contact c = genesis.TestHelper.createContact();
        genesis__Applications__C a = genesis.TestHelper.createApplication();
        genesis.TestHelper th1 = new genesis.TestHelper();
        th1.createCreditPullParameters(true,false,false);
        
        ints__Credit_Report__c cr = new ints__Credit_Report__c();
        cr.genesis__Open_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 100;
        cr.genesis__Open_Bankruptcy_Currently_Used__c = 1789;
        cr.genesis__Dismissed_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 50;
        cr.genesis__Dismissed_Bankruptcy_Currently_Used__c = 1400;
        cr.genesis__Delinquent_Child_Support_Amount__c = 1345;
        cr.genesis__Involuntary_Repossession__c = 345;
        cr.genesis__Vehicle_Charge_Off_Currently_Used__c = 678;
        cr.ints__Contact__c = c.Id;
        insert cr;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(a);
        CreditReportPullCtrl ctrl = new CreditReportPullCtrl(sc);
        CreditReportPullCtrl.pullCreditForBorrower(c.Id,a.Id);
        System.assertEquals(CreditReportPullCtrl.pullCreditForBorrower(c.Id,a.Id),'Credit pull successful.');
    }
    
    public static testMethod void testCreditReportPullCtrl3(){
        Contact c = genesis.TestHelper.createContact();
        genesis__Applications__c a = genesis.TestHelper.createApplication();
        genesis.TestHelper th1 = new genesis.TestHelper();
        genesis.TestHelper.createCreditReportData2(a);
        th1.createCreditPullParameters(true,true,false);
        
        ints__Credit_Report__c cr = new ints__Credit_Report__c();
        cr.genesis__Open_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 100;
        cr.genesis__Open_Bankruptcy_Currently_Used__c = 1789;
        cr.genesis__Dismissed_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 50;
        cr.genesis__Dismissed_Bankruptcy_Currently_Used__c = 1400;
        cr.genesis__Delinquent_Child_Support_Amount__c = 1345;
        cr.genesis__Involuntary_Repossession__c = 345;
        cr.genesis__Vehicle_Charge_Off_Currently_Used__c = 678;
        cr.ints__Contact__c = c.Id;
        insert cr;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(a);
        CreditReportPullCtrl ctrl = new CreditReportPullCtrl(sc);
        ctrl.saveDecisionInfo();
        ctrl.refreshDecision();
        ctrl.autoDecision();
        ctrl.autoDecision();
        ctrl.fetchCreditPullData();
        //CreditReportPullCtrl.pullCreditForBorrower(c.Id,a.Id);
        System.assertEquals(CreditReportPullCtrl.pullCreditForBorrower(c.Id,a.Id),'Credit pull successful.');
    }
    
    public static testMethod void testCreditReportPullCtrl4(){
        Contact c = genesis.TestHelper.createContact();
        genesis__Applications__c a = genesis.TestHelper.createApplication();
        genesis__Application_Decisions__c ad = genesis.TestHelper.createAppDecision(a);
        genesis.TestHelper.createCreditReportData(a);
        genesis.TestHelper th1 = new genesis.TestHelper();
        th1.createCreditPullParameters(true,true,true);
        
        ints__Credit_Report__c cr = new ints__Credit_Report__c();
        cr.genesis__Open_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 100;
        cr.genesis__Open_Bankruptcy_Currently_Used__c = 1789;
        cr.genesis__Dismissed_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 50;
        cr.genesis__Dismissed_Bankruptcy_Currently_Used__c = 1400;
        cr.genesis__Delinquent_Child_Support_Amount__c = 1345;
        cr.genesis__Involuntary_Repossession__c = 345;
        cr.genesis__Vehicle_Charge_Off_Currently_Used__c = 678;
        cr.ints__Contact__c = c.Id;
        insert cr;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(a);
        CreditReportPullCtrl ctrl = new CreditReportPullCtrl(sc);
        ctrl.saveDecisionInfo();
        ctrl.refreshDecision();
        ctrl.autoDecision();
        ctrl.fetchCreditPullData();
       // CreditReportPullCtrl.pullCreditForBorrower(c.Id,a.Id);
       System.assertEquals(CreditReportPullCtrl.pullCreditForBorrower(c.Id,a.Id),'Credit pull successful.');
    }
    
    public static testMethod void testCreditReportPullCtrl5(){
    
        Account acc = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert acc;
        genesis__Applications__c a = genesis.TestHelper.createApplication();
        a.genesis__account__c = acc.Id;
        a.genesis__contact__c = null;
        upsert a;
        
        ints__Credit_Report__c cr = new ints__Credit_Report__c();
        cr.genesis__Open_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 100;
        cr.genesis__Open_Bankruptcy_Currently_Used__c = 1789;
        cr.genesis__Dismissed_Bankruptcy_Date__c = genesis.TestHelper.systemDate - 50;
        cr.genesis__Dismissed_Bankruptcy_Currently_Used__c = 1400;
        cr.genesis__Delinquent_Child_Support_Amount__c = 1345;
        cr.genesis__Involuntary_Repossession__c = 345;
        cr.genesis__Vehicle_Charge_Off_Currently_Used__c = 678;
        cr.ints__Account__c = acc.Id;
        insert cr;
        
        genesis__Application_Decisions__c ad = genesis.TestHelper.createAppDecision(a);
        genesis.TestHelper.createCreditReportData(a);
        genesis.TestHelper th1 = new genesis.TestHelper();
        th1.createCreditPullParameters(true,true,true);
        ApexPages.StandardController sc = new ApexPages.StandardController(a);
        CreditReportPullCtrl ctrl = new CreditReportPullCtrl(sc);
        ctrl.saveDecisionInfo();
        ctrl.refreshDecision();
        ctrl.autoDecision();
        ctrl.fetchCreditPullData();
        //CreditReportPullCtrl.pullCreditForBorrower(c.Id,a.Id);
        System.assertEquals(CreditReportPullCtrl.pullCreditForAccount(acc.Id,a.Id),'Credit pull successful.');
    }
}