@isTest
public class TestAppEquipmentCtrl { 
    
    public static testMethod void testAppEquipmentCtrl1 (){
        genesis__Applications__c a = genesis.TestHelper.createApplication();
        genesis__Application_Equipment__c ae =  genesis.TestHelper.createApplicationEquipment(a);
        ApexPages.StandardController sc = new ApexPages.StandardController(ae);
        AppEquipmentCtrl  ctrl  = new AppEquipmentCtrl(sc);
        ctrl.getOptions();
        ctrl.saveDetailsInfo();
        ctrl.fetchEvaluation();
        ctrl.fetchMasterDetails();
        ctrl.deleteDetailsInfo();
        System.assertEquals(ctrl.saveDetailsInfo(),null);
        ctrl.cancel();
        ae =  new genesis__Application_Equipment__c();
        sc = new ApexPages.StandardController(ae);
        ctrl.getOptions();
        ctrl.choice = '1';
        ctrl.equipmentMasterChoice();
        ctrl.choice = '2';
        ctrl.equipmentMasterChoice();
        ctrl.saveDetailsInfo();
    }
    
    public static testMethod void testAppEquipmentCtrl2 (){
        genesis__Applications__c a = genesis.TestHelper.createApplication();
        genesis__Application_Equipment__c ae =  genesis.TestHelper.createApplicationEquipment(a);
        ApexPages.StandardController sc = new ApexPages.StandardController(ae);
        AppEquipmentCtrl  ctrl  = new AppEquipmentCtrl(sc);
        System.assertNotEquals(ctrl.saveDetailsInfo(),null);
        //ctrl.saveDetailsInfo();
        ctrl.saveDetailsInfo();
    }
}