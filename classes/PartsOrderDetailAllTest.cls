@isTest(seeAllData=true)
public with sharing class PartsOrderDetailAllTest{
    private static testMethod void myTestMethod(){

        Account ac = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert ac;

        Account ac2 = TestDataProvider.getAccounts(1,'Vendor Account','Vendor')[0];
        insert ac2;

        SVMXC__Site__c loc = TestDataProvider.getLocations(1,'Location Site','SPSC',ac.Id)[0];
        insert loc;

        SVMXC__Installed_Product__c ip1 = TestDataProvider.getInstalledProducts(1,'Installed Product',loc.Id,ac.Id)[0];
        insert ip1;
        System.debug('============== ip1.Id: ' + ip1.Id);
        IP1 = [SELECT Id,Name,Serial_Number__c,SVMXC__Site__c,SVMXC__Company__c,SVMXC__Product__c FROM SVMXC__Installed_Product__c WHERE Id = :ip1.Id LIMIT 1];

        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = ac.id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Order_Type__c = 'Parts Orders';
        wo.Business_Unit__c = 'Miner Corp';
        wo.Vendor_Name_c__c = ac2.Id;
        wo.Location__c = loc.Id;
        wo.SVMXC__Component__c = IP1.id;
        insert wo;

        SVMXC__RMA_Shipment_Order__c PO = new SVMXC__RMA_Shipment_Order__c();
        PO.Vendor__c = ac2.Id;
        PO.Internal_Bill_To__c = ac.Id;
        PO.SVMXC__Destination_Location__c = loc.Id;
        PO.SVMXC__Service_Order__c = wo.Id;
        insert PO;

        SVMXC__RMA_Shipment_Line__c POL1 = new SVMXC__RMA_Shipment_Line__c();
        POL1.SVMXC__RMA_Shipment_Order__c = PO.Id;
        POL1.SVMXC__Line_Type__c = 'Vendor Services';
        POL1.SVMXC__Product__c = IP1.SVMXC__Product__c;
        POL1.SVMXC__Expected_Quantity2__c = 2;
        POL1.WOL_Attach__c = false;

        SVMXC__RMA_Shipment_Line__c POL2 = new SVMXC__RMA_Shipment_Line__c();
        POL2.SVMXC__RMA_Shipment_Order__c = PO.Id;
        POL2.SVMXC__Line_Type__c = 'Vendor Services';
        POL2.SVMXC__Product__c = IP1.SVMXC__Product__c;
        POL2.SVMXC__Expected_Quantity2__c = 2;
        POL2.WOL_Attach__c = true;

        test.startTest();
        insert POL1;
        test.stopTest();

    }
}