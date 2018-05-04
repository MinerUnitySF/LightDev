/**This class serves as unit test for the checkRecursive class
 * @programer: Izay Ramos
 * @date: 10/19/2015
 * @version: 1
 * */
@isTest
public class CheckRecursive_UT {
    public static TestMethod void test1(){
        Boolean run1 = checkRecursive.runOnce();
        System.assert(run1);
        run1 = checkRecursive.runOnce();
        System.assert(!run1);
        Boolean run2 = checkRecursive.runOnce2();
        System.assert(run2);
        run2 = checkRecursive.runOnce2();
        System.assert(!run2);
        Boolean run3 = checkRecursive.runOnce3();
        System.assert(run3);
        run3 = checkRecursive.runOnce3();
        System.assert(!run3);
    }
}