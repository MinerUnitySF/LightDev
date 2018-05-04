/*
 *   @programer:    Rodrigo Birriel
 *   @description:  handle the vendor assignment trigger.
 *   @date:         01/05/2015            
 */
public class UNITY_VendorAssignmentTriggerHandler extends UNITY_BaseHandler{
    
    private Map<id,Account> parentVendors =  new Map<id,Account>();
    
    public override void bulkBefore() {
        
        Set<id> pullVendors = new Set<id> ();
            
        assignPinToAssignments((List<UNITY_Vendor_Assignment__c>) Trigger.new);
        
        for(SObject so :Trigger.new){
            UNITY_Vendor_Assignment__c vendorAssignment = (UNITY_Vendor_Assignment__c) so;
            if(vendorAssignment.Vendor__c!=null)pullVendors.add(vendorAssignment.Vendor__c);
        }
        parentVendors = new Map<id,Account>([SELECT id, name, Account_Email__c FROM  Account WHERE id IN :pullVendors]);
    }
    
    public override void bulkAfter() {
        propagateVendorPinToChildWOLIs( (List<UNITY_Vendor_Assignment__c>) Trigger.new, (Map<Id, UNITY_Vendor_Assignment__c>) Trigger.oldMap );
    }

    public override void beforeInsert(SObject so) {
        UNITY_Vendor_Assignment__c newVA = (UNITY_Vendor_Assignment__c) so;
        if(parentVendors.get(newVA.Vendor__c)!=null)newVA.UNITY_Vendor_Email__c=parentVendors.get(newVA.Vendor__c).Account_Email__c;
    }
    
    /**
     * Assign the pins to the current assignments
     */
    private void assignPinToAssignments(List<UNITY_Vendor_Assignment__c> assignments) {
        for(UNITY_Vendor_Assignment__c assigment : assignments) {
            assigment.PIN__c = UNITY_Utils.generateRandomPin();
        }
    }

    public void propagateVendorPinToChildWOLIs( List<UNITY_Vendor_Assignment__c> triggerAssignments, Map<Id, UNITY_Vendor_Assignment__c> oldAssignments ) {

        Map<Id, WorkOrder> woMap;
        Set<Id> woIds = new Set<Id>();
        List<UNITY_Vendor_Assignment__c> updatedAssignments = new List<UNITY_Vendor_Assignment__c>();
        List<WorkOrderLineItem> wolisToUpdate = new List<WorkOrderLineItem>();

        for (UNITY_Vendor_Assignment__c assign : triggerAssignments) {
            if ( assign.Status__c == 'Accepted' && assign.Status__c != oldAssignments.get(assign.Id).Status__c && assign.PIN__c != null && assign.Work_Order__c != null ) {
                updatedAssignments.add( assign );
                woIds.add( assign.Work_Order__c );
            }
        }

        if ( updatedAssignments.isEmpty() || woIds.isEmpty() ) return;

        woMap = new Map<Id, WorkOrder> ( [SELECT Id, (SELECT Id, Description FROM WorkOrderLineItems WHERE UNITY_Vendor_Pin__c = true) FROM WorkOrder WHERE Id IN: woIds] );

        for (UNITY_Vendor_Assignment__c assign : updatedAssignments) {
            for (WorkOrderLineItem woli : woMap.get(assign.Work_Order__c).WorkOrderLineItems) {
                wolisToUpdate.add( woli );
                
                Integer i = woli.Description.indexOfIgnoreCase( 'Pin:' ) + 4;
                String startingDesc = woli.Description.substring(0, i) + ' ' +assign.PIN__c;
                woli.Description = startingDesc;
            }
        }

        if ( !wolisToUpdate.isEmpty() ) update wolisToUpdate;
    }
}