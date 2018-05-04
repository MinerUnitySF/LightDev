trigger AmountCToAmount on Opportunity (before insert, before update) {
	
	List<Opportunity> toupdate =new List<Opportunity>();
	
	String rtid1 = [Select Id From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Miner_Corp_BDC_Opportunities'].Id;
	String rtid2 = [Select Id From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Short_Term_Rental'].Id;
	String rtid3 = [Select Id From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Term_Deals'].Id;
	
	for (Opportunity op : Trigger.new){
		if ((op.Amount != op.Amount__c) && (op.RecordTypeId != rtid1) && (op.RecordTypeId != rtid2) && (op.RecordTypeId != rtid3)){
			op.Amount = op.Amount__c;
			toupdate.add(op);
		}
		
	}
	
	
	
	
}