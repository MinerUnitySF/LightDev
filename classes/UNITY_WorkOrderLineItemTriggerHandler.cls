public class UNITY_WorkOrderLineItemTriggerHandler extends UNITY_BaseHandler{

    private Set<Id>     countWOOnAssetIds = new Set<Id>();

    public override void bulkAfter(){

    }

    public override void afterUpdate(SObject oldSO , SObject newSO ){
        WorkOrderLineItem newWOLI = (WorkOrderLineItem)newSO;
        WorkOrderLineItem oldWOLI = (WorkOrderLineItem)oldSO;
        this.checkAsset(newWOLI,oldWOLI);
    }

    public override void afterInsert(SObject so){
        WorkOrderLineItem woli = (WorkOrderLineItem)so;
        this.checkAsset(woli);
    }

    public override void afterDelete(SObject so){
        WorkOrderLineItem woli = (WorkOrderLineItem)so;
        this.checkAsset(woli);
    }


    public override void andFinally(){


       if(!this.countWOOnAssetIds.isEmpty() && !UNITY_Constants.isExecutingContext('UNITY_WorkOrderLineItemTriggerHandler.countWorkOrdersOnAsset'))
          if(!this.countWOOnAssetIds.isEmpty()) countWorkOrdersOnAsset(countWOOnAssetIds);

    }

    private void checkAsset(WorkOrderLineItem woli){
        if((woli!=null) && (woli.AssetId!=null)) this.countWOOnAssetIds.add(woli.AssetId);
    }

    private void checkAsset(WorkOrderLineItem newWOLI, WorkOrderLineItem oldWOLI){

        Boolean changeAsset = (newWOLI.AssetId != oldWOLI.AssetId);

        if(changeAsset){
            if(newWOLI.AssetId != null)
              this.countWOOnAssetIds.add(newWOLI.AssetId);
            if(oldWOLI.AssetId != null)
                this.countWOOnAssetIds.add(oldWOLI.AssetId);
        }
    }

    @future
    private static void countWorkOrdersOnAsset(Set<id> assetIds){
        UNITY_Utils.countWorkOrdersOnAsset(assetIds, Asset.getSObjectType());
    }



}