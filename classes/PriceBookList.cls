public with sharing class PriceBookList {
	
	
	public List<PriceBookEntry> entries {
		get; set;
	}
	
	public string SelectedId {	get; set;}
	
	public ID currentEntry {	get; set;}
	
	public PriceBookList(ApexPages.standardController sc) {
		
		currentEntry = sc.getId(); 
		entries = [SELECT PriceBook2.Name, UnitPrice, Id, IsActive, Cost__c FROM PriceBookEntry 
				   WHERE Product2Id = :currentEntry];
		
	}
	
	
	public void DeleteBook() {
		
		if (SelectedId == null) {
			return;
		}
		
		PriceBookEntry toBeDeleted = null;
		
		for(PriceBookEntry tmp:entries) {
			  if (tmp.Id == SelectedID) {
				toBeDeleted = tmp;
	
				break;
			}
		}
		
		if (toBeDeleted != null) {
			Delete toBeDeleted;
			
		}
		
	   
	 	entries = [SELECT PriceBook2.Name, UnitPrice, Id, IsActive, Cost__c FROM PriceBookEntry 
				   WHERE Product2Id = :currentEntry];
				   
	}

}