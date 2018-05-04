global class UNITYPM_UpdateWorkOrderDescriptionCtrl {

    public String workDescription {get;set;}
     public List<WorkOrder> workOrders {get;set;}
     private Set<Id> woIds = new Set<Id>();
    
    
    public UNITYPM_UpdateWorkOrderDescriptionCtrl (ApexPages.StandardController controller){
         String strIds = ApexPages.currentPage().getParameters().get('ids');
       
         List<String> tempIDs = strIds.split('\\,');
        
        if (tempIDs.size() > 0) 
            workOrders = [SELECT ID, UNITY_Work_Description__c, Status FROM WorkOrder WHERE ID IN:tempIDs];
         
    }
    
    public PageReference  doUpdate(){
        List<WorkOrder> updateWO = new List <WorkOrder>();
          
        if ( workDescription != null){
            for (WorkOrder wo : workOrders){
                wo.UNITY_Work_Description__c = workDescription;
                updateWO.add(wo);
            }
        }
        
        try{
            if (updateWO.size() > 0)
                 update updateWO; 
        }
        catch (Exception ex){
            
        }
        return null;
    }
}