@isTest
public class TestCustomEquipmentCtrl{
     public static testMethod void testCustomEquipmentCtrl(){
        genesis__Applications__c a = genesis.TestHelper.createApplication();
        
        genesis.TestHelper th1 = new genesis.TestHelper();
        ApexPages.StandardController sc = new ApexPages.StandardController(a);
        CustomEquipmentCtrl ctrl  = new CustomEquipmentCtrl(sc);
        
    }
    
}