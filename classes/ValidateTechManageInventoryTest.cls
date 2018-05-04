@isTest(SeeAllData=true)
public class ValidateTechManageInventoryTest {
  
    //test data is setup with location the same on work order and group member. Group memeber manage inventory has not been set to true yet.
    @isTest
    static void testNoUpdateNoTech(){
        test.startTest();
        
        Account ac = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert ac;
        
        Account ac2 = TestDataProvider.getAccounts(1,'Vendor Account','Vendor')[0];
        insert ac2;
        
        SVMXC__Site__c loc = TestDataProvider.getLocations(1,'Inventory Location','SPSC',ac.Id)[0];
        insert(loc);
        system.assertNotEquals(null, loc.id);
        
        SVMXC__Installed_Product__c ip1 = TestDataProvider.getInstalledProducts(1,'Installed Product',loc.Id,ac.Id)[0];
        insert ip1;
        
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c();
        sgroup.Name = 'Test Service Group';
        sgroup.SVMXC__Active__c = true;
        sgroup.Super_Center__c = 'Miner-Central Texas';
        sgroup.Segment__c = 'San Antonio';        
        insert sgroup;
        
        //TestDataProvider.setKeyValueStore();
        //TestDataProvider.unityTestSetup();
        /*
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = ac.id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Order_Type__c = 'Service-DDM';
        wo.Business_Unit__c = 'Miner Corp';
        wo.Vendor_Name_c__c = ac2.Id;
        wo.Location__c = loc.Id;
        wo.SVMXC__Site__c = loc.Id;
        wo.SVMXC__Component__c = IP1.id;
        wo.SVMXC__Service_Group__c = sgroup.id;
        wo.SVMXC__Problem_Description__c = 'desc';
        insert wo;
        
        SVMXC__RMA_Shipment_Order__c PO = new SVMXC__RMA_Shipment_Order__c();
        po.recordTypeId = Schema.Sobjecttype.SVMXC__RMA_Shipment_Order__c.getRecordTypeInfosByName().get('Miner').getRecordTypeId();
        po.SVMXC__Order_Status__c = 'Open';
        PO.Vendor__c = ac2.Id;
        PO.SVMXC__Destination_Location__c = loc.Id;
        PO.SVMXC__Service_Order__c = wo.Id;
        insert PO;
        
        //Create service group member
        SVMXC__Service_Group_Members__c member = new SVMXC__Service_Group_Members__c();
        member.SVMXC__Inventory_Location__c = loc.id;
        member.SVMXC__Service_Group__c = sgroup.Id;
        member.SVMXC__Salesforce_User__c = UserInfo.getUserId();
        member.SVMXC_Manage_Inventory__c = False;
        member.SVMXC__Fixed_Cost__c = 25;
        member.SVMXC__Active__c = true;
        member.SVMXC__Email__c = 'test@domain.com';
        member.SVMXC__Role__c = 'Technician';
        member.Name = 'Test Tech';  
        insert member;
        
        //closing order status on shipment order
        SVMXC__RMA_Shipment_Order__c poBefore = [SELECT SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE ID = :PO.Id];
        poBefore.SVMXC__Order_Status__c = 'Closed';
        
        try{
            upsert poBefore;
            //System.assert(false, 'exception expected');
        }
        catch(Exception e){
            String message = e.getMessage();
            //System.assert(message.contains(' Manage inventory permission not set on this user.'), 'message=' + message);
        } */
        
        test.stopTest();    
    }
    
    //test data is setup with location the same on work order and group member. Group memeber manage inventory has not been set to true yet.
    @isTest
    static void testNoUpdateNoLocation(){
        test.startTest();
        
        Account ac = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert ac;
        
        Account ac2 = TestDataProvider.getAccounts(1,'Vendor Account','Vendor')[0];
        insert ac2;
        
        SVMXC__Site__c loc = TestDataProvider.getLocations(1,'Inventory Location','SPSC',ac.Id)[0];
        loc.SVMXC__Stocking_Location__c = False;
        insert(loc);
        system.assertNotEquals(null, loc.id);
        
        SVMXC__Installed_Product__c ip1 = TestDataProvider.getInstalledProducts(1,'Installed Product',loc.Id,ac.Id)[0];
        insert ip1;
        
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c();
        sgroup.Name = 'Test Service Group';
        sgroup.SVMXC__Active__c = true;
        sgroup.Super_Center__c = 'Miner-Central Texas';
        sgroup.Segment__c = 'San Antonio';        
        insert sgroup;
        
        //Create service group 2
        SVMXC__Service_Group__c sgroup2 = new SVMXC__Service_Group__c();
        sgroup.Name = 'Test Service Group 2';
        sgroup.SVMXC__Active__c = true;
        sgroup.Super_Center__c = 'Miner-Central Texas 2';
        sgroup.Segment__c = 'San Antonio 2';        
        insert sgroup2;
        
        //TestDataProvider.setKeyValueStore();
        //TestDataProvider.unityTestSetup();
        /*
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = ac.id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Order_Type__c = 'Service-DDM';
        wo.Business_Unit__c = 'Miner Corp';
        wo.Vendor_Name_c__c = ac2.Id;
        wo.Location__c = loc.Id;
        wo.SVMXC__Site__c = loc.Id;
        wo.SVMXC__Component__c = IP1.id;
        wo.SVMXC__Service_Group__c = sgroup.id;
        wo.SVMXC__Problem_Description__c = 'desc';
        insert wo;
        
        SVMXC__RMA_Shipment_Order__c PO = new SVMXC__RMA_Shipment_Order__c();
        po.recordTypeId = Schema.Sobjecttype.SVMXC__RMA_Shipment_Order__c.getRecordTypeInfosByName().get('Miner').getRecordTypeId();
        po.SVMXC__Order_Status__c = 'Open';
        PO.Vendor__c = ac2.Id;
        PO.SVMXC__Destination_Location__c = loc.Id;
        PO.SVMXC__Service_Order__c = wo.Id;
        insert PO;
        
        //Create service group member
        SVMXC__Service_Group_Members__c member = new SVMXC__Service_Group_Members__c();
        member.SVMXC__Inventory_Location__c = loc.id;
        member.SVMXC__Service_Group__c = sgroup2.Id;
        member.SVMXC__Salesforce_User__c = UserInfo.getUserId();
        member.SVMXC_Manage_Inventory__c = True;
        member.SVMXC__Fixed_Cost__c = 25;
        member.SVMXC__Active__c = true;
        member.SVMXC__Email__c = 'test@domain.com';
        member.SVMXC__Role__c = 'Technician';
        member.Name = 'Test Tech';  
        insert member;
        
        //closing order status on shipment order
        SVMXC__RMA_Shipment_Order__c poBefore = [SELECT SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE ID = :PO.Id];
        poBefore.SVMXC__Order_Status__c = 'Closed';
        
        try{
            upsert poBefore;
            //System.assert(false, 'exception expected');
        }
        catch(Exception e){
            String message = e.getMessage();
            //System.assert(message.contains(' Manage inventory permission at this location not met.'), 'message=' + message);
        } 
        */
        test.stopTest();    
    }
    
    @isTest
    static void testUpdateAllowedStockingLocationTrue(){
        test.startTest();
        
        Account ac = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert ac;
        
        Account ac2 = TestDataProvider.getAccounts(1,'Vendor Account','Vendor')[0];
        insert ac2;
        
        SVMXC__Site__c loc = TestDataProvider.getLocations(1,'Inventory Location','SPSC',ac.Id)[0];
        //add stocking location true for this test
        loc.SVMXC__Stocking_Location__c = True;
        insert(loc);
        system.assertNotEquals(null, loc.id);
        
        SVMXC__Installed_Product__c ip1 = TestDataProvider.getInstalledProducts(1,'Installed Product',loc.Id,ac.Id)[0];
        insert ip1;
        
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c();
        sgroup.Name = 'Test Service Group';
        sgroup.SVMXC__Active__c = true;
        sgroup.Super_Center__c = 'Miner-Central Texas';
        sgroup.Segment__c = 'San Antonio';        
        insert sgroup;
        /*
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = ac.id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Order_Type__c = 'Service-DDM';
        wo.Business_Unit__c = 'Miner Corp';
        wo.Vendor_Name_c__c = ac2.Id;
        wo.Location__c = loc.Id;
        wo.SVMXC__Site__c = loc.Id;
        wo.SVMXC__Component__c = IP1.id;
        wo.SVMXC__Service_Group__c = sgroup.id;
        wo.SVMXC__Problem_Description__c = 'desc';
        insert wo;
        
        SVMXC__RMA_Shipment_Order__c PO = new SVMXC__RMA_Shipment_Order__c();
        po.recordTypeId = Schema.Sobjecttype.SVMXC__RMA_Shipment_Order__c.getRecordTypeInfosByName().get('Miner').getRecordTypeId();
        po.SVMXC__Order_Status__c = 'Open';
        PO.Vendor__c = ac2.Id;
        PO.SVMXC__Destination_Location__c = loc.Id;
        PO.SVMXC__Service_Order__c = wo.Id;
        insert PO;
        
        //Create service group member
        SVMXC__Service_Group_Members__c member = new SVMXC__Service_Group_Members__c();
        member.SVMXC__Inventory_Location__c = loc.id;
        member.SVMXC__Service_Group__c = sgroup.Id;
        member.SVMXC__Salesforce_User__c = UserInfo.getUserId();
        member.SVMXC__Fixed_Cost__c = 25;
        member.SVMXC__Active__c = true;
        member.SVMXC__Email__c = 'test@domain.com';
        member.SVMXC__Role__c = 'Technician';
        member.Name = 'Test Tech';
        //added allow Manage Inventory
        member.SVMXC_Manage_Inventory__c = True;
        insert member;
        
        //closing order status on shipment order
        SVMXC__RMA_Shipment_Order__c poBefore = [SELECT SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE ID = :PO.Id];
        poBefore.SVMXC__Order_Status__c = 'Closed';
        upsert poBefore;
        
        //Trigger should run after insert -get after
        SVMXC__RMA_Shipment_Order__c poAfter = [SELECT SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE ID = :PO.Id];
        
        //status set to close
        //location stocking location is true
        //manage inventory on group memeber is true
        //Destination location = group memebers Inventory Location
        //member User should be equal to user who is running test
        //trigger should should allow insert, order status should  change
        system.assertEquals(poBefore.SVMXC__Order_Status__c, poAfter.SVMXC__Order_Status__c);
        */
        test.stopTest();    
    }
    
    @isTest
    static void testUpdateAllowedStockingLocationFalse(){
        test.startTest();
        
        Account ac = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
        insert ac;
        
        Account ac2 = TestDataProvider.getAccounts(1,'Vendor Account','Vendor')[0];
        insert ac2;
        
        SVMXC__Site__c loc = TestDataProvider.getLocations(1,'Inventory Location','SPSC',ac.Id)[0];
        //add stocking location true for this test
        loc.SVMXC__Stocking_Location__c = False;
        insert(loc);
        system.assertNotEquals(null, loc.id);
        
        SVMXC__Installed_Product__c ip1 = TestDataProvider.getInstalledProducts(1,'Installed Product',loc.Id,ac.Id)[0];
        insert ip1;
        
        //Create service group
        SVMXC__Service_Group__c sgroup = new SVMXC__Service_Group__c();
        sgroup.Name = 'Test Service Group';
        sgroup.SVMXC__Active__c = true;
        sgroup.Super_Center__c = 'Miner-Central Texas';
        sgroup.Segment__c = 'San Antonio';        
        insert sgroup;
        /*
        SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
        wo.SVMXC__Company__c = ac.id;
        wo.SVMXC__Order_Status__c = 'Open';
        wo.SVMXC__Order_Type__c = 'Service-DDM';
        wo.Business_Unit__c = 'Miner Corp';
        wo.Vendor_Name_c__c = ac2.Id;
        wo.Location__c = loc.Id;
        wo.SVMXC__Site__c = loc.Id;
        wo.SVMXC__Component__c = IP1.id;
        wo.SVMXC__Service_Group__c = sgroup.id;
        wo.SVMXC__Problem_Description__c = 'desc';
        insert wo;
        
        SVMXC__RMA_Shipment_Order__c PO = new SVMXC__RMA_Shipment_Order__c();
        po.recordTypeId = Schema.Sobjecttype.SVMXC__RMA_Shipment_Order__c.getRecordTypeInfosByName().get('Miner').getRecordTypeId();
        po.SVMXC__Order_Status__c = 'Open';
        PO.Vendor__c = ac2.Id;
        PO.SVMXC__Destination_Location__c = loc.Id;
        PO.SVMXC__Service_Order__c = wo.Id;
        insert PO;
        
        //Create service group member
        SVMXC__Service_Group_Members__c member = new SVMXC__Service_Group_Members__c();
        member.SVMXC__Inventory_Location__c = loc.id;
        member.SVMXC__Service_Group__c = sgroup.Id;
        member.SVMXC__Salesforce_User__c = UserInfo.getUserId();
        member.SVMXC__Fixed_Cost__c = 25;
        member.SVMXC__Active__c = true;
        member.SVMXC__Email__c = 'test@domain.com';
        member.SVMXC__Role__c = 'Technician';
        member.Name = 'Test Tech';
        //added allow Manage Inventory
        member.SVMXC_Manage_Inventory__c = True;
        insert member;
        
        //closing order status on shipment order
        SVMXC__RMA_Shipment_Order__c poBefore = [SELECT SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE ID = :PO.Id];
        poBefore.SVMXC__Order_Status__c = 'Closed';
        upsert poBefore;
        
        //Trigger should run after insert -get after
        SVMXC__RMA_Shipment_Order__c poAfter = [SELECT SVMXC__Order_Status__c FROM SVMXC__RMA_Shipment_Order__c WHERE ID = :PO.Id];
        
        //status set to close
        ////location stocking location is true
        //Service Group is same on member as it is on service order
        //member User should be equal to user who is running test
        //trigger should should allow insert, order status should  change
        system.assertEquals(poBefore.SVMXC__Order_Status__c, poAfter.SVMXC__Order_Status__c);
        */
        test.stopTest();    
    }
    
}