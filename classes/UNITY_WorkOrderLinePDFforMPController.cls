public class UNITY_WorkOrderLinePDFforMPController {
    public Id workOrderId {get; 
                           set {
                                workOrderId = value;
                               items = [SELECT Id, FSO__Order__c,LineItemNumber, Description, CreatedDate, UNITY_Render_Type__c, UNITY_Vendor_Pin__c
                                    FROM WorkOrderLineItem
                                       WHERE WorkOrderId=:workOrderId 
                                       ORDER BY Createddate ASC, FSO__Order__c ASC NULLS FIRST];
                                       
                                 //init(workOrderId);
                                
                           }}
                           
                          
     public List<WorkOrderLineItem> items {get; private set;}
      public List<UNITY_RenderWOLiInWorkPlanPDF__mdt> itemsRenderType {get; private set;}
    
     public void init(ID workOrderId) {
          items = [SELECT Id, FSO__Order__c,LineItemNumber, Description, CreatedDate, UNITY_Render_Type__c FROM WorkOrderLineItem
                                                   WHERE WorkOrderId=:workOrderId 
                                                   ORDER BY Createddate ASC, FSO__Order__c ASC NULLS FIRST];
       
          UNITY_RenderWOLiInWorkPlanPDF__mdt [] renderTypeWOLI = [SELECT FreeText__c, GoodMediumBad__c, Meter_Reading__c, PassFail__c, YesNo__c FROM UNITY_RenderWOLiInWorkPlanPDF__mdt ];
           
     }
    
}