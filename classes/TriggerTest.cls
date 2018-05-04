/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TriggerTest {
    static testMethod void opportunityCloseDate() {
           
        Account acct = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert acct;
           
        Opportunity opp = new Opportunity();
        opp.Name = 'Opp Name';
        opp.AccountId = acct.id;
        opp.CloseDate = system.today();
        opp.Send_Close_Date_Email__c = false;
        opp.StageName = 'Presented';
        insert opp;
    }
            
    static testMethod void testLeadBusinessUnit() {
    
        User usr = [SELECT Id,Business_Unit__c from User 
        where User.IsActive = True and user.Business_Unit__c != NULL Limit 1 ];
    
        // System.debug('USER= '+ usr);
        Lead newlead =  TestDataProvider.getLeads(3, 'Miner_Corp_BDC_Leads')[0];
        insert newlead;
        
    }
}