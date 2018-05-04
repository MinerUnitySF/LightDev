public with sharing class UNITY_AdjustmentPOCreationController {

    private Order newAdjPO;
    private final Order purchOrder;

    // Constructor.
    public UNITY_AdjustmentPOCreationController(ApexPages.StandardController stdController) {
        purchOrder = [SELECT Id, Name, AccountId, EffectiveDate, Status, UNITY_Invoice__c, UNITY_Invoice__r.UNITY_Invoice_Status__c,
                      UNITY_Customer__c, UNITY_Vendor__c, UNITY_Vendor_Contract__c, FSO__WorkOrder__c
                      FROM Order WHERE Id =: ApexPages.currentPage().getParameters().get('orderId') ];
    }

    public PageReference createAdjustmentPO() {
        
        //Ensure current running user has access to create Adjustment Purchase Order record type.
        List<RecordTypeInfo> infos = Order.sObjectType.getDescribe().getRecordTypeInfos();
        for (RecordTypeInfo rtInfo : infos) {
            System.debug('RT: '+rtInfo);
            if ( rtInfo.getName() == UNITY_Constants.ADJUSTMENT_PURCHASE_ORDER && !rtInfo.isAvailable() ) {
                ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have the appropriate permissions to create Adjustment Purchase Orders.') );
                return null;
            }
        }

        //Check if original order is related to finalized invoice.
        if ( String.isEmpty(purchOrder.UNITY_Invoice__c) || purchOrder.UNITY_Invoice__r.UNITY_Invoice_Status__c != 'Invoice Finalized' ) {
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Adjustment Purchase Orders are for orders related to finalized invoices.') );
            return null;
        }
        
        newAdjPO = new Order( 
            
            UNITY_Adjustment_To_PO__c = purchOrder.Id, 
            RecordTypeId = UNITY_Constants.ADJUSTMENT_PURCHASE_ORDER_RECORDTYPE ,
            Status = 'Draft',
            
            AccountId = purchOrder.AccountId, 
            UNITY_Customer__c = purchOrder.UNITY_Customer__c,
            UNITY_Vendor__c = purchOrder.UNITY_Vendor__c,
            UNITY_Vendor_Contract__c = purchOrder.UNITY_Vendor_Contract__c,
            EffectiveDate = purchOrder.EffectiveDate, 
            FSO__WorkOrder__c = purchOrder.FSO__WorkOrder__c
            
        );
        
        try {
            insert newAdjPO;
        } catch (Exception e) {
            ApexPages.getMessages().add( new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error creating the new adjustment record: '+e.getMessage()) );
            return null;
        }
        
        return new PageReference('/'+newAdjPO.Id);
    }
}