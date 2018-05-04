trigger InvoiceDetailAll on MH_Invoice_Details__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if (trigger.isBefore)
		checkLocked();
		
	public void checkLocked(){
		
		List<sObject> solist = new List<sObject>();
		if (trigger.isDelete)
			soList = trigger.Old;
		else
			solist = trigger.New;
			
		lockedClass.checkL(solist, 'Work_Order__c', 'SVMXC__Service_Order__c', 'Locked__c');
		
	}

}