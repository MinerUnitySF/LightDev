@isTest(seeAllData=true)
public with sharing class InvoiceAllTest {

	public static testmethod void test1(){
		
		Account ac = TestDataProvider.getAccounts(1,'Customer Account','Customer')[0];
		insert ac;
		
		SVMXC__Site__c loc = TestDataProvider.getLocations(1,'Location Site','SPCS',ac.Id)[0];
		insert loc;
		
        SVMXC__Installed_Product__c IP1 = TestDataProvider.getInstalledProducts(1,'Installed Product', loc.Id, ac.Id)[0];
		insert IP1;
        
		SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
		wo.SVMXC__Company__c = ac.id;
		wo.SVMXC__Site__c = loc.Id;
		wo.SVMXC__Order_Status__c = 'Open';
		wo.SVMXC__Order_Type__c = 'Parts Orders';
        wo.SVMXC__Component__c = IP1.id;
		insert wo;
		
		SVMXC__Service_Order_Line__c wod = new SVMXC__Service_Order_Line__c();
		wod.SVMXC__Service_Order__c = wo.id;
		wod.SVMXC__Line_Type__c = 'Parts';
        wod.SVMXC__Activity_Type__c = 'Parts - Service and Remodel';
		insert wod;
		
		MH_Invoice__c inv = new MH_Invoice__c();
		inv.Work_Order__c = wo.Id;
		inv.Account__c = ac.Id;
		insert inv;
		
		MH_Invoice_Details__c invd = new MH_Invoice_Details__c();
		invd.Work_Detail__c = wod.Id;
		invd.Invoice__c = inv.Id;
		insert invd;
		
		wod.Invoice_Detail__c = invd.Id;
		update wod;
		
		inv.Status__c = 'Void';
		update inv;
		
		MH_Invoice_Details__c invd2 = [SELECT Id, Work_Detail__c FROM MH_Invoice_Details__c WHERE Id =: invd.Id];
		system.assertEquals(invd2.Work_Detail__c, null);
		
	}

}