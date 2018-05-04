@isTest(seeAllData=true)
public with sharing class WorkDetailallTest {

	private static testMethod void testInventoryRelief(){
		
		Account ac = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
		insert ac;
		
		Account ac1 = TestDataProvider.getAccounts(1,'Vendor Account','Vendor')[0];
		insert ac1;
        
        Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String pid = '';
        for(String key :prodMap.keySet()){
            pid = key;
            break;
        }
		
		SVMXC__Site__c loc = TestDataProvider.getLocations(1,'Location Site','SPSC',ac.Id)[0];
        insert loc;
        // create IP
        SVMXC__Installed_Product__c IP1 = TestDataProvider.getInstalledProducts(1,'Installed Product',loc.Id,ac.Id)[0];
		insert IP1;
		
		SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
		wo.SVMXC__Company__c = ac.id;
		wo.SVMXC__Order_Status__c = 'Open';
		wo.SVMXC__Order_Type__c = 'Parts Orders';
		wo.Business_Unit__c = 'Miner Corp';
		wo.Vendor_Name_c__c = ac1.Id;
        wo.Location__c = loc.Id;
        wo.SVMXC__Component__c = IP1.id;
		insert wo;
		
		SVMXC__Product_Stock__c ps1 = new SVMXC__Product_Stock__c();
		ps1.SVMXC__Location__c = loc.Id;
		ps1.SVMXC__Product__c = pid;
		ps1.SVMXC__Status__c = 'Available';
		insert ps1;
		
		SVMXC__Product_Stock__c ps2 = new SVMXC__Product_Stock__c();
		ps2.SVMXC__Location__c = loc.Id;
		ps2.SVMXC__Product__c = pid;
		ps2.SVMXC__Status__c = 'Consumed';
		insert ps2;
		
		MH_Invoice__c inv = new MH_Invoice__c();
		inv.Account__c = ac.Id;
		inv.Work_Order__c = wo.Id;
		insert inv;
		
		MH_Invoice_Details__c invd = new MH_Invoice_Details__c();
		invd.Invoice__c = inv.Id;
		insert invd;
		
		SVMXC__Service_Order_Line__c wod = new SVMXC__Service_Order_Line__c();
		wod.Vendor__c = ac1.id;
		wod.SVMXC__Service_Order__c = wo.id;
		wod.SVMXC__Line_Type__c = 'Parts';
        wod.SVMXC__Activity_Type__c = 'Parts - New Construction';
		wod.Invoice_Detail__c = invd.Id;
		wod.SVMXC__Consumed_From_Location__c = loc.Id;
		wod.SVMXC__Product__c = pid;
		wod.SVMXC__Actual_Quantity2__c = 10;
        //wod.SVMXC__Posted_To_Inventory__c = false;
		insert wod;
		
		SVMXC__Service_Order_Line__c wod1 = new SVMXC__Service_Order_Line__c();
		wod1 = [SELECT Id, SVMXC__Posted_To_Inventory__c FROM SVMXC__Service_Order_Line__c WHERE Id =: wod.Id];
		//system.assertEquals(wod1.SVMXC__Posted_To_Inventory__c, false);
		
	}
	
	private static testMethod void testInventoryRelief1(){

		Account ac = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
		insert ac;
		
		Account ac1 = TestDataProvider.getAccounts(1,'Vendor Account','Vendor')[0];
		insert ac1;
		
		Map<String,String> prodMap = TestDataProvider.getProductAndPriceBookEntry(1);
        String pid = '';
        for(String key :prodMap.keySet()){
            pid = key;
            break;
        }
		
		SVMXC__Site__c loc = TestDataProvider.getLocations(1,'Location Site','SPSC',ac.Id)[0];
        insert loc;
        // create IP
        SVMXC__Installed_Product__c IP1 = TestDataProvider.getInstalledProducts(1,'Installed Product',loc.Id,ac.Id)[0];
		insert IP1;
		
		SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
		wo.SVMXC__Company__c = ac.id;
		wo.SVMXC__Order_Status__c = 'Open';
		wo.SVMXC__Order_Type__c = 'Parts Orders';
        wo.SVMXC__Component__c = IP1.id;
		insert wo;
		
		SVMXC__Site__c loc1 = TestDataProvider.getLocations(1,'Location Site','SPSC',ac.Id)[0];
		loc1.Name = 'location1';
        loc1.SVMXC__Stocking_Location__c = true;
		loc1.Travel_Time__c = 12345;
        insert loc1;
        
        MH_Invoice__c inv = new MH_Invoice__c();
        inv.Account__c = ac.Id;
		inv.Work_Order__c = wo.Id;
		insert inv;
		
		MH_Invoice_Details__c invd = new MH_Invoice_Details__c();
		invd.Invoice__c = inv.Id;
		insert invd;
		
		SVMXC__Service_Order_Line__c wod1 = new SVMXC__Service_Order_Line__c();
		wod1.Vendor__c = ac1.id;
		wod1.SVMXC__Service_Order__c = wo.id;
		wod1.SVMXC__Line_Type__c = 'Parts';
        wod1.SVMXC__Activity_Type__c = 'Parts - New Construction';
		wod1.Invoice_Detail__c = invd.Id;
		wod1.SVMXC__Consumed_From_Location__c = loc1.Id;
		wod1.SVMXC__Product__c = pid;
		wod1.SVMXC__Actual_Quantity2__c = 10;
		insert wod1;
		
		SVMXC__Service_Order_Line__c wod2 = new SVMXC__Service_Order_Line__c();
		wod2 = [SELECT Id, SVMXC__Posted_To_Inventory__c FROM SVMXC__Service_Order_Line__c WHERE Id =: wod1.Id];
		system.assertEquals(wod2.SVMXC__Posted_To_Inventory__c, true);
		
	}

}