/*------------------------------------------------------------
Name:          AttachmentUtilities
Author:        Krishna Kameneni
Company:       Miner
Description:   This is Main utility class for Attachment object.
History:
12/16/2015     Krishna Kameneni(Perficient)    Added/Modified comments
                                               Created event handling methods
------------------------------------------------------------*/
public without sharing class UNITY_OrderUtilities{
    public static void onAfterInsert(List<Order> ordersNew) {
        UNITY_OrderUtilities.updateMissingRequiredDocumentation(ordersNew,null);
    }
    public static void onAfterUpdate(List<Order> ordersNew,Map<Id,Order>oldMap) {
        UNITY_OrderUtilities.updateMissingRequiredDocumentation(ordersNew,oldMap);
    }
    public static void onAfterDelete(List<Order> ordersNew) {
        UNITY_OrderUtilities.updateMissingRequiredDocumentation(ordersNew,null);
    }
    public static void updateMissingRequiredDocumentation(List<Order> ordersNew,Map<Id,Order>oldMap){
        system.debug('>>>>>> UNITY_OrderUtilities  BEFORE Limits.getQueries() '+Limits.getQueries());
        Set<Id> invoiceIds = new Set<Id>();
        // get the WorkOrder Ids updated / inserted to be used in the following query
        for (Order orderObj : ordersNew){
            if(oldMap==null)
                invoiceIds.add(orderObj.UNITY_Invoice__c);
            else if(orderObj.UNITY_Related_WO_Document_Compli_Text__c!=oldMap.get(orderObj.Id).UNITY_Related_WO_Document_Compli_Text__c)
                invoiceIds.add(orderObj.UNITY_Invoice__c);
        }
        if(!invoiceIds.isEmpty()) {
            List <UNITY_Invoice__c>invoices=[SELECT id ,UNITY_Missing_Required_Documentation__c, 
                                                   (Select id,UNITY_Related_WO_Document_Compli_Text__c from Orders__R )  
                                            FROM UNITY_Invoice__c 
                                            WHERE Id In :invoiceIds]; 
            List<UNITY_Invoice__c>invoicesToUpdate=new List<UNITY_Invoice__c>();
            for(UNITY_Invoice__c invoiceObj : invoices){
                boolean initialValue=invoiceObj.UNITY_Missing_Required_Documentation__c;
                invoiceObj.UNITY_Missing_Required_Documentation__c=false;
                for(Order orderObj : invoiceObj.Orders__R){
                  if(orderObj.UNITY_Related_WO_Document_Compli_Text__c ==false){
                      invoiceObj.UNITY_Missing_Required_Documentation__c=true;
                      break;
                  }
                } 
                if(initialValue!=invoiceObj.UNITY_Missing_Required_Documentation__c)
                    invoicesToUpdate.add(invoiceObj);
             }  
            update invoicesToUpdate;    
        }
        system.debug('>>>>>> UNITY_OrderUtilities AFTER Limits.getQueries() '+Limits.getQueries());
    }
}