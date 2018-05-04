public with sharing class CustomEquipmentCtrl extends genesis.ApplicationWizardBaseClass{

  //  private Office_Name__c currentBranch;
    private Date systemDate;
    public genesis__Vehicle_Valuation__c vehicleValuation {get;set;}    
    private String mode = genesis.LendingConstants.NEW_RECORD;
    
    public CustomEquipmentCtrl (ApexPages.StandardController controller) {
       super(controller);
       this.application = (genesis__Applications__c)controller.getRecord();
    }
    
}