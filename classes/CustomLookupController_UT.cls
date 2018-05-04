@isTest
public class CustomLookupController_UT {
    public static TestMethod void test1(){
        String obj = 'Account';
        String flds = 'Id,Name,Type';
        String whr = 'RecordType.Name = \'Customer\'';
        String lk = 'Name';
        List<Account> accounts = TestdataProvider.getAccounts(2, 'Customer', 'Customer');
        insert accounts;
        List<String> args = new List<String>{obj,flds,whr,lk};
        List<SObject> result = CustomLookupController.doSearch('Test',args);
    }
}