public class UNITY_AssetWorkOrderHierarchyController {
	
    
    public  Map<id,Asset>             assetMap               {get;set;}
    public  Boolean                   fromWOLI               {get;set;}
    public  String                    searchWO               {get;set;}
    public  Map<id,WorkOrder>         workOrderMap           {get;set;}
    public  Map<id,WorkOrderLineItem> workOrderLineItemsMap  {get;set;}
    
    private id                assetId          				 {get;set;}
    private Set<id>           workOrderId            		 {get;set;}
    
    
    
    public UNITY_AssetWorkOrderHierarchyController( ApexPages.StandardController sc){
        
        this.reset();
        this.init();
        
    }
    
    private void reset(){
        
        this.fromWOLI =  true;
        this.assetMap =  new Map<id,Asset>();
        this.workOrderId           =  new Set<id> ();
        this.workOrderMap          =  new Map<id,WorkOrder>();
        this.workOrderLineItemsMap =  new Map<id,WorkOrderLineItem>();
    }
    
    private void init(){
        
        
        this.assetId = (id)ApexPages.currentPage().getParameters().get('Id');
            
        this.assetMap.put(assetId, [SELECT id, 
                                          Name, 
                                          UNITY_Work_Order__c, 
                                          RootAssetId,
                                          UNITY_Make__c,
                                          UNITY_Model__c,
                                          SSVY_Asset_Condition__c, 
                                          UNITY_Is_Under_Warranty__c ,
                                          SSVY_ScanCode__c  
                                   FROM Asset 
                                   WHERE id = :assetId]);
        
        this.assetMap.putAll(this.getChildAssets(assetId));
            
        this.workOrderLineItemsMap.putAll(this.getWorkOrderLineItems(assetMap.keySet()));
            
        Set<id> aux_woId = new Set<id>();
        
        for(WorkOrderLineItem onWOLI :workOrderLineItemsMap.values()){
            aux_woId.add(onWOLI.WorkOrderId); 
        }
        
        workOrderMap.putAll(this.getWorkOrders(aux_woId));
        
    }
    
    private Map<id,WorkOrder> getWorkOrders(Set<id> woIds){
        
       Map<id,WorkOrder>  aux_workOrderMap = new Map<id,WorkOrder>([SELECT id, 
                                                                                   Status , 
                                                                            	   WorkOrderNumber, 
                                                                                   UNITY_Accepted_Vendor__c ,
                                                                    			   UNITY_Accepted_Vendor__r.name,
                                                                                   Priority  ,
                                                                                   UNITY_Is_Under_Warranty__c,
                                                                                   UNITY_Is_Potential_Warranty__c ,
                                                                                   TotalPrice,
                                                                                   UNITY_Work_Order_Total_w_Tax__c 
                                                                            FROM WorkOrder
                                                                            WHERE id IN :woIds ]);
        return aux_workOrderMap;
    }
    
    private Map<id,WorkOrderLineItem> getWorkOrderLineItems(Set<id> assetsId){
      
        Map<id,WorkOrderLineItem> aux_workOrderMap = new Map<id,WorkOrderLineItem>();
        
        if((searchWO != '')&&(searchWO != null)){
            
            aux_workOrderMap = new Map<id,WorkOrderLineItem>([SELECT  id, 
                                                                      LineItemNumber, 
                                                                      WorkOrderId, 
                                                                      WorkOrder.WorkOrderNumber, 
                                                                      AssetId, 
                                                                      Asset.Name,
                                                                      Description,
                                                                      FSO__Order__c, 
                                                                      FSO__IsRequired__c, 
                                                                      FSO__IsCompleted__c, 
                                                                      FSO__UnableToFinish__c
                                                              FROM WorkOrderLineItem 
                                                              WHERE AssetId IN :assetsId AND 
                                                                     (WorkOrder.id = :this.searchWO OR WorkOrder.WorkOrderNumber LIKE :this.searchWO)]);
        }else{
            aux_workOrderMap = new Map<id,WorkOrderLineItem>([SELECT  id, 
                                                                      LineItemNumber, 
                                                                      WorkOrderId, 
                                                                      WorkOrder.WorkOrderNumber, 
                                                                      AssetId, 
                                                                      Asset.Name,
                                                                      Description,
                                                                      FSO__Order__c, 
                                                                      FSO__IsRequired__c, 
                                                                      FSO__IsCompleted__c, 
                                                                      FSO__UnableToFinish__c
                                                              FROM WorkOrderLineItem 
                                                              WHERE AssetId IN :assetsId ]);
        }
        searchWO = '';
        
        return aux_workOrderMap;
    }
    
    private Map<id,Asset> getChildAssets(id parentAssetId){
        Map<id,Asset> aux_assets = new Map<id,Asset>([SELECT  id, 
                                                              Name, 
                                                              UNITY_Work_Order__c, 
                                                              RootAssetId,
                                                              UNITY_Make__c,
                                                              UNITY_Model__c,
                                                              SSVY_Asset_Condition__c, 
                                                              UNITY_Is_Under_Warranty__c ,
                                                              SSVY_ScanCode__c 
                                                      FROM Asset 
                                                      WHERE RootAssetId = :parentAssetId]);
        
        return aux_assets;
    }
        
    public void searchWO(){
        this.reset();
        this.init();
    }
    /* NOT IMPLEMENTED YET
    class WONode{
        public id 		        woId         {get;set;}
        public String 	        woNumber     {get;set;}
        public Map<id,List<id>> assetToWOLI  {get;set;}
        public Map<id,List<id>> woliToAsset  {get;set;}
        
        private Set<id>    woliId{get;set;}
        private Set<id>    assetId{get;set;}
            
        public WONode(id woId, String woNumber){
            this.woId     = woId;
            this.woNumber = woNumber;
            this.assetToWOLI = new Map<id,List<id>>();
            this.woliToAsset = new Map<id,List<id>>();
            this.woliId      = new Set<id>();
            this.assetId     = new Set<id>();
        }
        
        public void setMaps(WorkOrderLineItem woli){
                        
            if(this.assetToWOLI.get(woli.AssetId)    ==null) this.assetToWOLI.put(woli.AssetId, new List<id>());
            if(this.woliToAsset.get(woli.id)==null) this.woliToAsset.put(woli.id, new List<id>());
            
            if(!this.woliId.contains(woli.id)){
                this.assetToWOLI.get(woli.AssetId).add(woli.id);
                this.woliId.add(woli.id);
            }
            
            if(!this.assetId.contains(woli.AssetId)){
                this.woliToAsset.get(woli.id).add(woli.AssetId);
                this.assetId.add(woli.AssetId);
            }
            
        }
    }*/
}