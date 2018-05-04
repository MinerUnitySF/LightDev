trigger UpdateDetailRollUpFieldsOnWorkOrder on SVMXC__Service_Order_Line__c (after insert, after update, after delete) {
	
	Set<Id> soIds = new Set<Id>();
	if (Trigger.isInsert || Trigger.isUpdate)
		for (SVMXC__Service_Order_Line__c sol : Trigger.New)
			if (sol.SVMXC__Service_Order__c != null)
				soIds.add(sol.SVMXC__Service_Order__c);
	if (Trigger.isUpdate || Trigger.isDelete)
		for (SVMXC__Service_Order_Line__c sol : Trigger.Old)
			if (sol.SVMXC__Service_Order__c != null)
				soIds.add(sol.SVMXC__Service_Order__c);
			
	List<SVMXC__Service_Order__c> sos = [SELECT Id FROM SVMXC__Service_Order__c WHERE Id IN :soIds];
	
	List<AggregateResult> ags = [SELECT SVMXC__Service_Order__c SO, MIN(RecordType.DeveloperName) RT, SUM(Total_Line_PriceMH__c) TLP, SUM(Sales_Tax__c) ST, SUM(Total_Cost__c) TC FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c IN :soIds GROUP BY SVMXC__Service_Order__c, RecordTypeId];
	
	for (SVMXC__Service_Order__c so : sos) {
		
		so.Estimated_Work_Total__c = 0;
		so.Work_Order_Total__c = 0; 
		so.Sales_Tax_Total__c = 0;
		so.Total_Cost__c = 0;
		
		for (AggregateResult ag : ags) {
			if (ag.get('SO') == so.Id) {
				if (ag.get('RT') == 'Estimate') {
					if (ag.get('TLP') != null)
						so.Estimated_Work_Total__c += (decimal)ag.get('TLP');
				}
				if (ag.get('RT') == 'UsageConsumption') {
					if (ag.get('TLP') != null)
						so.Work_Order_Total__c += (decimal)ag.get('TLP');
					if (ag.get('ST') != null)
						so.Sales_Tax_Total__c += (decimal)ag.get('ST');
				}
				if (ag.get('TC') != null)
					so.Total_Cost__c += (decimal)ag.get('TC');
			}
		}
		
	}
	
	update sos; 
	
	/*
	Map<Id,Decimal> woEWT = new Map<Id,Decimal>();
	Map<Id,Decimal> woWOT = new Map<Id,Decimal>();
	Map<Id,Decimal> woSTT = new Map<Id,Decimal>();
	Map<Id,SVMXC__Service_Order_Line__c> oldMap = Trigger.oldMap;
	
	Id estimate_rt = [Select Id From RecordType  Where SobjectType = 'SVMXC__Service_Order_Line__c' and DeveloperName = 'Estimate'].id;
	Id usagec_rt = [Select Id From RecordType  Where SobjectType = 'SVMXC__Service_Order_Line__c' and DeveloperName = 'UsageConsumption'].id;
	
	if (Trigger.isUpdate || trigger.isInsert) {
		for (SVMXC__Service_Order_Line__c wod:Trigger.new){
			SVMXC__Service_Order_Line__c oldWOD ;
			if (oldMap!=null) oldWOD = oldMap.get(wod.id);
			if (wod.RecordTypeId == estimate_rt && (oldWOD==null || oldWOD!=null && (wod.Total_Line_PriceMH__c!=oldWOD.Total_Line_PriceMH__c)) ) {
				
				if (oldWOD==null && wod.Total_Line_PriceMH__c!=null) {
					if (woEWT.containsKey(wod.SVMXC__Service_Order__c))
						woEWT.put(wod.SVMXC__Service_Order__c,woEWT.get(wod.SVMXC__Service_Order__c)+wod.Total_Line_PriceMH__c);
					else {
						woEWT.put(wod.SVMXC__Service_Order__c,wod.Total_Line_PriceMH__c);
					}
				}
				if (oldWOD!=null){
					Decimal oldValue = oldWOD.Total_Line_PriceMH__c;
					Decimal newValue = wod.Total_Line_PriceMH__c;
					Decimal valueToAddinMap;
					if (oldValue==null && newValue!=null) valueToAddinMap = newValue;
					if (oldValue!=null && newValue==null) valueToAddinMap = -oldValue;
					if (oldValue!=null && newVAlue!=null) valueToAddinMap = newVAlue-OldValue;
					
					
					if (woEWT.containsKey(wod.SVMXC__Service_Order__c))
						woEWT.put(wod.SVMXC__Service_Order__c,woEWT.get(wod.SVMXC__Service_Order__c)+valueToAddinMap);
					else {
						woEWT.put(wod.SVMXC__Service_Order__c,valueToAddinMap);
					}
				}
			} 
			
			if (wod.RecordTypeId == usagec_rt && (oldWOD==null || oldWOD!=null && (wod.Total_Line_PriceMH__c!=oldWOD.Total_Line_PriceMH__c)) ) {
				
				if (oldWOD==null && wod.Total_Line_PriceMH__c!=null) {
									
					if (woWOT.containsKey(wod.SVMXC__Service_Order__c))
						woWOT.put(wod.SVMXC__Service_Order__c,woWOT.get(wod.SVMXC__Service_Order__c)+wod.Total_Line_PriceMH__c);
					else {
						woWOT.put(wod.SVMXC__Service_Order__c,wod.Total_Line_PriceMH__c);
					}
				}
				if (oldWOD!=null){
					Decimal oldValue = oldWOD.Total_Line_PriceMH__c;
					Decimal newValue = wod.Total_Line_PriceMH__c;
					Decimal valueToAddinMap;
					if (oldValue==null && newValue!=null) valueToAddinMap = newValue;
					if (oldValue!=null && newValue==null) valueToAddinMap = -oldValue;
					if (oldValue!=null && newVAlue!=null) valueToAddinMap = newVAlue-OldValue;
									
					if (woWOT.containsKey(wod.SVMXC__Service_Order__c))
						woWOT.put(wod.SVMXC__Service_Order__c,woWOT.get(wod.SVMXC__Service_Order__c)+valueToAddinMap);
					else {
						woWOT.put(wod.SVMXC__Service_Order__c,valueToAddinMap);
					}
				}
			} 
			
			if (wod.RecordTypeId == usagec_rt && (oldWOD==null || oldWOD!=null && (wod.Sales_Tax__c!=oldWOD.Sales_Tax__c)) ) {
				
				if (oldWOD==null && wod.Sales_Tax__c!=null) {
						
					if (woSTT.containsKey(wod.SVMXC__Service_Order__c))
						woSTT.put(wod.SVMXC__Service_Order__c,woSTT.get(wod.SVMXC__Service_Order__c)+wod.Sales_Tax__c);
					else {
						woSTT.put(wod.SVMXC__Service_Order__c,wod.Sales_Tax__c);
					}
				}
				if (oldWOD!=null){
					Decimal oldValue = oldWOD.Sales_Tax__c;
					Decimal newValue = wod.Sales_Tax__c;
					Decimal valueToAddinMap;
					if (oldValue==null && newValue!=null) valueToAddinMap = newValue;
					if (oldValue!=null && newValue==null) valueToAddinMap = -oldValue;
					if (oldValue!=null && newVAlue!=null) valueToAddinMap = newVAlue-OldValue;
						
					if (woSTT.containsKey(wod.SVMXC__Service_Order__c))
						woSTT.put(wod.SVMXC__Service_Order__c,woSTT.get(wod.SVMXC__Service_Order__c)+valueToAddinMap);
					else {
						woSTT.put(wod.SVMXC__Service_Order__c,valueToAddinMap);
					}
				}
			} 
		}
	}
	if (Trigger.isDelete){
	
		for (SVMXC__Service_Order_Line__c wod :Trigger.old){
			
			if (wod.RecordTypeId == estimate_rt && wod.Total_Line_PriceMH__c!=null) {
				
					if (woEWT.containsKey(wod.SVMXC__Service_Order__c))
						woEWT.put(wod.SVMXC__Service_Order__c,woEWT.get(wod.SVMXC__Service_Order__c)-wod.Total_Line_PriceMH__c);
					else {
						woEWT.put(wod.SVMXC__Service_Order__c,-wod.Total_Line_PriceMH__c);
					}
			}
			
			if (wod.RecordTypeId == usagec_rt && wod.Total_Line_PriceMH__c!=null) {
				
					if (woWOT.containsKey(wod.SVMXC__Service_Order__c))
						woWOT.put(wod.SVMXC__Service_Order__c,woWOT.get(wod.SVMXC__Service_Order__c)-wod.Total_Line_PriceMH__c);
					else {
						woWOT.put(wod.SVMXC__Service_Order__c,-wod.Total_Line_PriceMH__c);
					}
			}
			
			if (wod.RecordTypeId == usagec_rt &&  wod.Sales_Tax__c!=null) {
				
					if (woSTT.containsKey(wod.SVMXC__Service_Order__c))
						woSTT.put(wod.SVMXC__Service_Order__c,woSTT.get(wod.SVMXC__Service_Order__c)-wod.Sales_Tax__c);
					else {
						woSTT.put(wod.SVMXC__Service_Order__c,-wod.Sales_Tax__c);
					}
			}
			
		
		}
		
	
	}
	List<SVMXC__Service_Order__c> wo_list = [select id,Estimated_Work_Total__c,Work_Order_Total__c,Sales_Tax_Total__c from SVMXC__Service_Order__c
											where id in :woEWT.keySet() or id in :woWOT.keySet() or id in :woSTT.keySet()];
	Map<Id,SVMXC__Service_Order__c> toupdate = new Map<Id,SVMXC__Service_Order__c>();
	
	for (SVMXC__Service_Order__c wo :wo_list){
		
		if (woEWT.containsKey(wo.id)) {
			if (wo.Estimated_Work_Total__c!=null){
				wo.Estimated_Work_Total__c+=woEWT.get(wo.id);
			}
			else {
				wo.Estimated_Work_Total__c = woEWT.get(wo.id);
			}
			
		}
		if (woWOT.containsKey(wo.id)) {
			if (wo.Work_Order_Total__c!=null){
				wo.Work_Order_Total__c+=woWOT.get(wo.id);
			}
			else {
				wo.Work_Order_Total__c = woWOT.get(wo.id);
			}
			
		}
		if (woSTT.containsKey(wo.id)) {
			if (wo.Sales_Tax_Total__c!=null){
				wo.Sales_Tax_Total__c+=woSTT.get(wo.id);
			}
			else {
				wo.Sales_Tax_Total__c = woSTT.get(wo.id);
			}
			
		}
		toupdate.put(wo.id,wo);
	}
	//System.debug('estimate -->'+ woEWT.values().size());
	//System.debug('WO -->'+ woWOT.values().size());
	//System.debug('STT -->'+ woSTT.values().size());
	//System.debug('Estimated_Work_Total__c -->'+toupdate.values()[0].Estimated_Work_Total__c);
	//System.debug('sales tax -->'+toupdate.values()[0].Sales_Tax_Total__c);
	//System.debug('wo total -->'+toupdate.values()[0].Work_Order_Total__c);
	//System.debug('size of toupdatelist -->'+toupdate.values().size());
	if (toupdate.values().size()>0) update toupdate.values();*/

}