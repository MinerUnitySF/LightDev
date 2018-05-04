/** Description: This is the unit test for the UpdateIPPM class
*** Programer:   Josh Phillips
*** Date:        12/1/2014
*** Version:     1.0
*/
@isTest(SeeAllData=true)
private class UpdateIPPM_UT{

    static testmethod void test1(){
        //Create an installed product
        SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c();
        ip.name = 'test product';
        //Insert the installed product
        insert ip;
        //Create a service order
        SVMXC__Service_Order__c svo = new SVMXC__Service_Order__c();
        svo.SVMXC__Component__c = ip.id;//Assign the installed product to the order
        svo.Last_PM_Date__c = Date.today();
        svo.Meter_Reading__c  = 1500;
        svo.MHE_Resolution_Code__c='PM'; 
        svo.Business_Unit__c='Total Fleet Solutions';
        //Insert the service order
        insert svo;
    }
    
}