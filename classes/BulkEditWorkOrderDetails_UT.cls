@isTest(SeeAllData = true)
private class BulkEditWorkOrderDetails_UT {
		
	public static testmethod void testMethod1(){
		Account customer = TestDataProvider.getAccounts(1, 'Customer Account', 'Customer')[0];
        insert customer;
        Account vendor = TestDataProvider.getAccounts(1, 'Vendor Account', 'Vendor')[0];
        insert vendor;
		SVMXC__Site__c location = TestDataProvider.getLocations(1, 'Location Site', '', customer.Id)[0];
        insert location;
        
		SVMXC__Installed_Product__c IP1 = TestDataProvider.getInstalledProducts(1, 'Installed Product', location.Id, customer.Id)[0];
		insert IP1;
		
        IP1 = [SELECT Id,Name,Serial_Number__c,SVMXC__Site__c,SVMXC__Company__c,SVMXC__Product__c FROM SVMXC__Installed_Product__c WHERE Id = :ip1.Id LIMIT 1];
        
		SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c();
		
		wo.SVMXC__Company__c = customer.id;
		wo.SVMXC__Order_Status__c = 'Open';
		wo.SVMXC__Order_Type__c = 'Parts Orders';
		wo.SVMXC__Component__c = IP1.id;
		insert wo;
		
        String rtusagec = [Select Id From RecordType  Where SobjectType = 'SVMXC__Service_Order_Line__c' and DeveloperName = 'UsageConsumption' LIMIT 1].Id;
        
		SVMXC__Service_Order_Line__c wod = new SVMXC__Service_Order_Line__c();
		wod.Vendor__c = vendor.id;
		wod.SVMXC__Service_Order__c = wo.id;
		wod.SVMXC__Line_Type__c = 'Parts';
        wod.SVMXC__Activity_Type__c = 'Parts - Service and Remodel';
        wod.SVMXC__Product__c = IP1.SVMXC__Product__c;
        wod.RecordTypeId = rtusagec;
		insert wod;
		
		SVMXC__Service_Order_Line__c wod1 = new SVMXC__Service_Order_Line__c();
		wod1.Vendor__c = vendor.id;
		wod1.SVMXC__Service_Order__c = wo.id;
		wod1.SVMXC__Line_Type__c = 'Parts';
        wod1.SVMXC__Activity_Type__c = 'Parts - Service and Remodel';
        wod1.SVMXC__Product__c = IP1.SVMXC__Product__c;
        wod1.RecordTypeId = rtusagec;
		insert wod1;
		
		
		PageReference pageRef = Page.BulkEditWorkOrderDetails;
		pageRef.getParameters().put('id',wo.id);
		
		Test.setCurrentPageReference(pageRef);
		BulkEditWorkOrderDetails br = new BulkEditWorkOrderDetails();
		br.quickSave();
		br.add10MoreLines();
        br.slnr = 1;
		br.emptyMethod();
		br.togglePart();
		br.saveAndClose();
		
		
	}
}