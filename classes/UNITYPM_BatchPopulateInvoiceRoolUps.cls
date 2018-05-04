public class UNITYPM_BatchPopulateInvoiceRoolUps  implements Database.Batchable<SObject> {
     public Database.QueryLocator start(Database.BatchableContext context) {
         return Database.getQueryLocator([
              SELECT Id,UNITYPM_Number_of_Assets__c, Number_of_Labor_Lines__c,Number_of_Travel_Lines__c,Number_of_Part_Lines__c,
                       (SELECT ID, UNITY_Activity_Type__c,UNITYPM_Is_Preventative_Maintenance__c FROM  Invoice_Line_Items__r)
                            FROM UNITY_Invoice__c ]);
    }
    
    
      public void execute(Database.BatchableContext context, List<UNITY_Invoice__c> scope) {
             List<UNITY_Invoice__c> invoicesUpdate = new List<UNITY_Invoice__c>();
             
             for ( UNITY_Invoice__c invoice : scope){
                 Integer pmLines =0;
                 Integer laborLines =0;
                 Integer travelLines =0;
                 Integer partsLines =0;
                 
                 for (UNITY_Invoice_Line_Item__c line: invoice.Invoice_Line_Items__r){
                    if (line.UNITYPM_Is_Preventative_Maintenance__c == true)
                        pmLines++;
                    else if ((line.UNITY_Activity_Type__c.indexOf('Labor') > -1) && line.UNITYPM_Is_Preventative_Maintenance__c == false)
                          laborLines++;
                    else if ((line.UNITY_Activity_Type__c.indexOf('Travel') > -1 ) && line.UNITYPM_Is_Preventative_Maintenance__c == false) 
                           travelLines++;
                    else if (!line.UNITY_Activity_Type__c.contains('Labor') && !line.UNITY_Activity_Type__c.contains('Travel') && line.UNITYPM_Is_Preventative_Maintenance__c == false)
                          partsLines++;
                 }
                 invoice.UNITYPM_Number_of_Assets__c =pmLines;
                 invoice.Number_of_Labor_Lines__c = laborLines;
                 invoice.Number_of_Travel_Lines__c = travelLines;
                 invoice.Number_of_Part_Lines__c = partsLines;
                 
                 invoicesUpdate.add(invoice);
             }
             
             if (invoicesUpdate.size() > 0){
                   update invoicesUpdate;
             }
      }
      
    public void finish(Database.BatchableContext context) {
    }
}