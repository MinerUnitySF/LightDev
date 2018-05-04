public class UNITY_CreateStockingPOController{
    
    public String stockLocationId {get; private set;}
    public Boolean hasError {get; private set;}
    private static final String STOCKINGPORTID = UNITY_Constants.ORDER_STOCKING_PURCHASE_ORDER_RECORDTYPE;
    /**This is the class constructor*/
    public UNITY_CreateStockingPOController(ApexPages.StandardController controller){
        this.stockLocationId = ApexHelper.getParam('id');
        this.hasError = false;
        if(String.isBlank(this.stockLocationId)){
            String message = 'Stock Location Id not found.<br/>' + 
                'Please try again by clicking on the <strong>Create Stocking PO</strong> from the Stock Location.';
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
            this.hasError = true;
        }
    }
    /**This class creates the Stocking PO for the Stock Location and redirects to the new PO*/ 
    public PageReference createStockingPO(){
        this.hasError = false;
        PageReference pr;
        if(String.isNotBlank(this.stockLocationId)){
            //Query for the Stock Location info to create the PO
            List<FSO__Location__c> stockLocation = [SELECT Id,Name,FSO__Account__c,UNITY_Business_Unit__c,UNITY_Business_Unit_Account__c,
                                                    FSO__City__c,FSO__Country__c,FSO__State__c,FSO__Street__c,FSO__Zip__c
                                                    FROM FSO__Location__c WHERE Id = :this.stockLocationId LIMIT 1];
            if(!stockLocation.isEmpty()){
                FSO__Location__c sLoc = stockLocation[0];
                Order o = new Order(
                    RecordTypeId = STOCKINGPORTID,
                    AccountId = sLoc.FSO__Account__c,
                    UNITY_Location__c = sLoc.id,
                    EffectiveDate = Date.today(),
                    Status = 'Draft',
                    UNITY_Ship_To_Account__c = sLoc.FSO__Account__c,
                    UNITY_Business_Unit__c = sloc.UNITY_Business_Unit__c,
                    UNITY_Business_Unit_Account__c = sloc.UNITY_Business_Unit_Account__c,
                    ShippingCountry = sLoc.FSO__Country__c,
                    ShippingCity = sLoc.FSO__City__c,
                    ShippingState = sLoc.FSO__State__c,
                    ShippingStreet = sLoc.FSO__Street__c,
                    SHippingPostalCode = sLoc.FSO__Zip__c,
                    Type = 'OEM Restocking PO'
                );
                try{
                    insert o;
                    pr = new PageReference('/'+o.Id);
                    pr.setRedirect(true);
                }catch(Exception e){
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
                    this.hasError = true;
                    return null;
                }
            }else{
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Stock Location not found for the given Id.'));
                this.hasError = true;
                return null;
            }
        }else{
            String message = 'Stock Location Id not found.<br/>' + 
                'Please try again by clicking on the <strong>Create Stocking PO</strong> from the Stock Location.';
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
            this.hasError = true;
            return null;
        }
        return pr;
    }

}