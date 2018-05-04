trigger InvoiceAll on MH_Invoice__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	
    if (trigger.isBefore)
        checkLocked();
    
	if ((trigger.isAfter) && (trigger.isUpdate))
		ReBillWorkDetail();
	
    // check the value of the locked field on the work order to determine if the work detail can be modified

    
	public void ReBillWorkDetail(){
		
		Set<Id> invset = new Set<Id>();
		for (MH_Invoice__c inv : trigger.new){
			if ((inv.Status__c == 'Void') && (trigger.oldMap.get(inv.Id).Status__c != 'Void'))
				invset.add(inv.Id);
		}
		
		List<MH_Invoice_Details__c> invDetailsList = new List<MH_Invoice_Details__c>();
		invDetailsList = [SELECT Id, Work_Detail__r.Invoice_Detail__c, Work_Detail__c FROM MH_Invoice_Details__c WHERE Invoice__c IN : invset];
		Set<Id> wodetailset = new Set<Id>();
		for (MH_Invoice_Details__c index : invDetailsList){
			wodetailset.add(index.Work_Detail__c);
			index.Work_Detail__c = null;
		}
		
		List<SVMXC__Service_Order_Line__c> woDetailsList = new List<SVMXC__Service_Order_Line__c>();
		woDetailsList = [SELECT Id FROM SVMXC__Service_Order_Line__c WHERE Id IN : wodetailset];
		for (SVMXC__Service_Order_Line__c woindex : woDetailsList)
			woindex.Invoice_Detail__c = null;	
			
			
		update invDetailsList;
		update woDetailsList;
	}
	
	public void checkLocked(){
		
		List<sObject> solist = new List<sObject>();
		if (trigger.isDelete)
			soList = trigger.Old;
		else
			solist = trigger.New;
			
		lockedClass.checkL(solist, 'Work_Order__c', 'SVMXC__Service_Order__c', 'Locked__c');
		
	}

}