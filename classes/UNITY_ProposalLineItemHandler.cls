public with sharing class UNITY_ProposalLineItemHandler extends UNITY_BaseHandler{
  
    private Set<Id> updatedProposalLineItemIdSet = new Set<Id>();
    
    public override void afterInsert(Sobject so){

        updatedProposalLineItemIdSet.add(so.Id);
    }
    
    public override void afterUpdate(sObject so, sObject oldSo){
        
        updatedProposalLineItemIdSet.add(so.Id);
    }
      
    public override void andFinally(){
        
        recalculatePricing();
        
    }
    
    public void recalculatePricing(){
        
        if (!updatedProposalLineItemIdSet.isEmpty() && !UNITY_Constants.isExecutingContext('UNITY_PriceCalculation.recalculatePricing') && !UNITY_Constants.isExecutingContext('UNITY_PriceCalculation.callAvataxForProposal')){
            System.debug('#updatedProposalLineItemIdSet '+updatedProposalLineItemIdSet);
            UNITY_PriceCalculation.recalculateProposalPricing(updatedProposalLineItemIdSet);
        }
    }
}