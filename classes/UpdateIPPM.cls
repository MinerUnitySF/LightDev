/** Description: This class updates the Last PM date and Last PM reading fields on installed products
*** 			 in given work orders for the "Total Fleet Solutions" business unit with "PM" Resolution Code
*** Programer:   Josh Phillips
*** Date:        12/1/2014
*** Version:     1.0
*** -------------------------------------
*** Changelog
*** -------------------------------------
*** Description: Updated class code to prevent error when updating work orders in batch
*** Programer: 	 Izay Ramos
*** Date:		 3/26/2015
*** Version:	 2.0
*/

public with sharing class UpdateIPPM {
    
    public static void updateIPPMDate(List<SVMXC__Service_Order__c> orders){
        /*List<SVMXC__Installed_Product__c> ipUpdates = new List<SVMXC__Installed_Product__c>();
        
        for(SVMXC__Service_Order__c oItem: orders){
            if(oItem.MHE_Resolution_Code__c=='PM' && oItem.Business_Unit__c=='Total Fleet Solutions'){
              SVMXC__Installed_Product__c ipUpdate = new SVMXC__Installed_Product__c();  
                ipUpdate.id = oItem.SVMXC__Component__c;
                ipUpdate.Last_PM_Date__c = oItem.TFS_Service_Date__c;
                ipUpdate.Last_PM_Meter_Reading__c = oItem.Meter_Reading__c;
                ipUpdates.add(ipUpdate);
            }           
        }
        if(ipUpdates.size()>0) update ipUpdates;
        */
        
        //Set to hold installed product ids
        Set<Id> ipIds = new Set<Id>();
        //List of orders with changes
        List<SVMXC__Service_Order__c> ipUpdateOrders = new List<SVMXC__Service_Order__c>();
        //iterate through all orders…
        for(SVMXC__Service_Order__c oItem: orders){
            //if match criteria
            if(oItem.MHE_Resolution_Code__c=='PM' && oItem.Business_Unit__c=='Total Fleet Solutions'){
                //Add the installed product id to the set if meets the criteria. (Sets don't hold duplicate values)
                ipIds.add(oItem.SVMXC__Component__c);
                //Add the order to the list of orders with IPs to update
                ipUpdateOrders.add(oItem);
            }//End if criteria
        }//End for orders
        //If there are ids in the ipIds set...
        if(ipIds.size() > 0){
            //Get the installed product records for the ids set to update
            Map<Id,SVMXC__Installed_Product__c> toUpdateMap = new Map<Id, SVMXC__Installed_Product__c >([SELECT Id,Last_PM_Date__c,Last_PM_Meter_Reading__c FROM SVMXC__Installed_Product__c WHERE Id IN :ipIds]);
            //Iterate through the orders with IPs to update...
            for(SVMXC__Service_Order__c oItem: ipUpdateOrders){
                //If the toUpdateMap has the installed product id as a key… Update the fields
                if(toUpdateMap.containsKey(oItem.SVMXC__Component__c)){
                    toUpdateMap.get(oItem.SVMXC__Component__c).Last_PM_Date__c = oItem.TFS_Service_Date__c;
                    toUpdateMap.get(oItem.SVMXC__Component__c).Last_PM_Meter_Reading__c = oItem.Meter_Reading__c;
                }//End if in toUpdate
            }//End for orders
            //Update records in toUpdateMap
            if(toUpdateMap.values().size() > 0){
                update toUpdateMap.values();
            }//End if toUpdate     
        }//End if ipIds size
		
    }  
    
}