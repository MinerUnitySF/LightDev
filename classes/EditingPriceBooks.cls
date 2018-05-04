public with sharing class EditingPriceBooks {
 
 	public ID currentEntry;
 	
 	public PriceBookEntry entry {
		get; set;
	}
	
	public PriceBookEntry standardPrice {
		get; set;
	}
	
	public Product2 standardCost {
		get; set;
	}	
	 
	public EditingPriceBooks(ApexPages.standardController sc) {
	
		currentEntry = sc.getId();
	
		if(currentEntry == null)  {
			entry = new PriceBookEntry();
			entry.Product2Id =  ApexPages.currentPage().getParameters().get('product');
			entry.IsActive = true;
		}
		else {
			entry = [SELECT PriceBook2Id, Product2Id, UnitPrice, IsActive, Cost__c FROM PriceBookEntry WHERE id = :currentEntry];
		}
		
		try {
		standardPrice = [SELECT UnitPrice FROM PriceBookEntry WHERE Pricebook2.isStandard=True AND Product2.Id = :entry.Product2Id];
		} catch (Exception e) {
		}
		standardCost = [SELECT SVMXC__Product_Cost__c FROM Product2 WHERE Id = :entry.Product2Id];
	}
	
	public PageReference SavePriceBookEntry() {
		Integer tmpCounter;
		tmpCounter = [SELECT Count() FROM PriceBookEntry WHERE Pricebook2.Id = :entry.PriceBook2Id AND Product2.Id = :entry.Product2Id];
		
		if (tmpCounter > 0) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Only one pricebook entry can be active for the same product in a price book. Please modify the other pricebook entry for this product or deactivate it before creating a new pricebook entry.'));
			return null;
		} 
		
		try {
			upsert entry;
		}   catch(Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
			return null;
		}
		
		PageReference ref = new PageReference('/' + standardCost.Id);
		
		return ref;
		
	}
	
	public void getStandardPrice() {
	
	}
}