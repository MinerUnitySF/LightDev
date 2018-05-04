/**This class serves as unit test for the ApexHelper class
** @programer: Izay Ramos-Irizarry
** @version: 1.0
** @date: 4/9/2015
*/
@isTest
public class ApexHelper_UT{
    //Test run trigger once methods
    public static TestMethod void test1(){
        //Check first trigger run
        ApexHelper.runTriggerOnce_Before();
        ApexHelper.runTriggerOnce_After();
        ApexHelper.runTriggerStop_Before();
        //Run trigger second time
        ApexHelper.runTriggerOnce_Before();
        ApexHelper.runTriggerOnce_After();
        ApexHelper.runTriggerStop_Before();
        //Call getParam
        String param = ApexHelper.getParam('Id');
        Set<Id> ids = new Set<Id>();
        List<Account> accts = TestDataProvider.getAccounts(2,'Customer','Customer');
        insert accts;
        for(Account a :accts){
            ids.add(a.Id);
        } 
        List<Id> ids2 = new List<Id>();
        ids2.addAll(ids);
        ApexHelper.joinIds(ids);
        ApexHelper.joinIds(ids2);
    } 
}