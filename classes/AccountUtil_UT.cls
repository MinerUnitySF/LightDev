/**This class serves as unit test class for the AccountUtil class
***@Developer: Izay Ramos-Irizarry
***@Date:      7/17/2015
***@Version:   1.0
*/
@isTest
public class AccountUtil_UT {
    
    public static TestMethod void test1(){
        List<Account> accounts = TestDataProvider.getAccounts(1, 'FLEXX Accounts', 'Customer');
        accounts[0].Account_Status__c = 'Prospect';
        accounts.addAll(TestDataProvider.getAccounts(1, 'FLEXX Accounts', 'Vendor'));
        accounts[1].Account_Status__c = 'Prospect';
        insert accounts;
        String[] aids = new String[0];
        for(Account a :accounts){
            aids.add(a.Id);
        }
        Test.startTest();
        
        String result = AccountUtil.readyToConvert(aids);
        System.assert(result == 'Success');
        accounts = [SELECT Id,RecordType.Name FROM Account];
        
        System.assert(accounts.size() == 2);
        Boolean foundP = false;
        Boolean foundV = false;
        for(Account a :accounts){
            if(a.RecordType.Name == 'Prospect Accounts'){
                foundP = true;
            }
            if(a.RecordType.Name == 'Vendor Account'){
                foundV = true;
            }
        }
        
        System.assert(foundP);
        System.assert(foundV);
        
        delete accounts;
        
        result = AccountUtil.readyToConvert(aids);
        
        System.assertEquals('Error: Account not found. Contact HELPDESK for help with this problem.', result); 
        
        result = AccountUtil.readyToConvert(new String[0]);
        System.assert(result == 'Error: List of parameters is empty. Contact HELPDESK for help with this problem.');
        
        Test.stopTest();
    }
}