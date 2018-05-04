/**
 * ContactTriggerHandler_UT: This is the unit test class for the ContactTriggerHandler class
 * @programer: Izay Ramos
 * @date: 10/27/2015
 * @version: 1.0
 */
@isTest
public class ContactTriggerHandler_UT {
    
    public static TestMethod void test1(){
        //Bollean to denote when a transaction fail
        Boolean failed = false;
        //Create an user to run the test as 
        User  u = TestDataProvider.getUser('Tim', 'Burton', 'MinerCorp/DDM Sales');
        u.Business_Unit__c = 'Miner Corp';
        u.Super_Center__c = 'Miner-Central Texas';
        insert u;
        User admin = TestDataProvider.getUser('Admin', 'User', 'System Administrator');
        insert admin;
        //Create a prospect account
        Account cust = TestDataProvider.getAccounts(1, 'Prospect Accounts', 'Customer')[0];
        //Create a contact
        Contact con = TestDataProvider.getContacts(1, null)[0];
        //Try inserting the customer. This should fail becasue there is no account approver setup yet
        System.runAs(u){
            insert con;
        }
        //Assign the contact as the primary conatct for the prospect account. Also, set the account as residential
        cust.Account_Status__c = 'Prospect';
        cust.Residential__c = true;
        cust.MH_Primary_Contact__c = con.Id;
        //Try inserting the customer. This should fail becasue there is no account approver setup yet
        System.runAs(u){
            try{
                insert cust;
            }catch(Exception e){
                failed = true;
            }
        }
        //Check that the transaction failed
        //System.assert(failed);
        //Reset failed
        failed = false;
        //Setup account approver for super center
        System.runAs(admin){
            Account_Approver__c accapp1 = new Account_Approver__c(Name = 'Miner-Central Texas', User_Id__c = u.Id);
            insert accapp1;
        }
        //Reset trigger
        resetTrigger();
        System.runAs(u){
            update cust;
            //Fetch the account and compare check that its name is the contact last name plust the account billing street
            cust = [SELECT Id,Name,BillingStreet,BillingStateCode,BillingState,Residential__c,Business_Unit__c FROM Account WHERE Id = :cust.Id LIMIT 1];
            //System.assert(cust.Name == (con.LastName + ' - ' + cust.BillingStreet));
            System.debug('============= cust.Name: ' + cust.Name);
            System.debug('============= cust.Name: ' + cust);
            //Now, need to convert the prospect to customer. For testing will simply change the account status to active
            resetTrigger();
            cust.Account_Status__c = 'Active';
            update cust;
            //Now, try to change the contact name. This should fail
            try{
                resetTrigger();
                con.FirstName = 'Changed';
                con.LastName = 'Changed';
                update con;
            }catch(Exception e){
                failed = true;
            }
            //Check that the transaction failed
            //System.assert(failed);
            //Reset failed flag and try deleteing the contact. This should fail
            failed = false;
            try{
                resetTrigger();
                delete con;
            }catch(Exception e){
                failed = true;
            }
            //Check that the transaction failed
            //System.assert(failed);
            ContactTriggerHandler.runTriggerOnce_Before();
            ContactTriggerHandler.runTriggerOnce_After();
            ContactTriggerHandler.runTriggerOnce_After();
        }
    }
    
    public static void resetTrigger(){
        ////Reset trigger run
        AccountTriggerHandler.isFirstTriggerRun_Before = true;
        AccountTriggerHandler.isFirstTriggerRun_After = true;
        ContactTriggerHandler.isFirstTriggerRun_Before = true;
        ContactTriggerHandler.isFirstTriggerRun_After = true;
    }
    
}