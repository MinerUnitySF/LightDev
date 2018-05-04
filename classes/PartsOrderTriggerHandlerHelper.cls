public class PartsOrderTriggerHandlerHelper {
    
    /*
Create a trigger to validate when a Parts Order is receipt. Ensure that the user performing the action is set as "Manage Inventory" for the stock location.
Comments	
When a Parts Order(SVMXC__RMA_Shipment_Order__c) Order Status(SVMXC__Order_Status__c) changes to "Closed"

If the Parts Order's To Location is a Stocking Location(SVMXC__Destination_Location__r.SVMXC__Stocking_Location__c == TRUE):

Verify that the current user:
Has a Technician/Equipment record where the Inventory Location is the same as the To Location on the Parts Order and is set to Manage Inventory
- SVMXC__Service_Group_Members__c.SVMXC__Salesforce_User__c == CurrentUser.Id
- SVMXC__Service_Group_Members__c.SVMXC__Inventory_Location__c == SVMXC__RMA_Shipment_Order__c.SVMXC__Destination_Location__c
- SVMXC__Service_Group_Members__c.Manage Inventory == TRUE

If the Parts Order's To Location is NOT a Stocking Location(SVMXC__Destination_Location__r.SVMXC__Stocking_Location__c == FALSE):

Verify that the current user:
Has a Technician/Equipment record for the Service Team on the related Work Order and is set to Manage Inventory
- SVMXC__Service_Group_Members__c.SVMXC__Salesforce_User__c == CurrentUser.Id
- SVMXC__Service_Group_Members__c.Id == SVMXC__RMA_Shipment_Order__c.SVMXC__Service_Order__r.SVMXC__Service_Group__c
- SVMXC__Service_Group_Members__c.Manage Inventory == TRUE 
*/
    public static void ValidateTechManageInventory(Map<Id, SVMXC__RMA_Shipment_Order__c> poMap,Map<Id, SVMXC__RMA_Shipment_Order__c> oldPOMap){
        User u = [SELECT Id,Ignore_Validations__c FROM User WHERE Id = :UserInfo.getUserId()];
        //using map for addError method
        //map<id, SVMXC__RMA_Shipment_Order__c> poMap = newList;
        
        //get current users locations and group they belong in and that they are allowed to manage territiores in 
        List<SVMXC__Service_Group_Members__c> techs = [
            SELECT SVMXC__Inventory_Location__c, SVMXC__Service_Group__c, SVMXC_Manage_Inventory__c
            FROM SVMXC__Service_Group_Members__c
            WHERE (SVMXC__Salesforce_User__c =:UserInfo.getUserId() AND SVMXC_Manage_Inventory__c = True)];
        
        //query for relationships on parts orders
        List<SVMXC__RMA_Shipment_Order__c> partsOrders = [
            SELECT SVMXC__Destination_Location__r.SVMXC__Stocking_Location__c, SVMXC__Destination_Location__c,SVMXC__Service_Order__r.SVMXC__Service_Group__c,SVMXC__Order_Status__c,SVMXC__Order_Type__c
            FROM SVMXC__RMA_Shipment_Order__c
            WHERE ID IN :poMap.keySet()];
        
        //system.debug(partsOrders[0].SVMXC__Destination_Location__r.SVMXC__Stocking_Location__c + ' '+ partsOrders[0].SVMXC__Destination_Location__c + ' '+partsOrders[0].SVMXC__Order_Status__c);
        
        for(SVMXC__RMA_Shipment_Order__c po :partsOrders){       
            boolean validated = false;
            if(Trigger.isUpdate){
                if(po.SVMXC__Order_Status__c == 'Closed' && oldPOMap.get(po.Id).SVMXC__Order_Status__c != 'Closed'){
                    system.debug('techs: '+techs);
                    if(techs.isEmpty() && !u.Ignore_Validations__c){
                        poMap.get(po.Id).addError(' Manage inventory permission not set on this user.'); // prevent update
                        break;
                    }
                    for(SVMXC__Service_Group_Members__c t :techs){
                        //system.debug(po.SVMXC__Destination_Location__r.SVMXC__Stocking_Location__c + ' '+ po.SVMXC__Destination_Location__c + ' ' +t.SVMXC__Inventory_Location__c);
                        //system.debug(po.SVMXC__Destination_Location__r.SVMXC__Stocking_Location__c + ' '+ po.SVMXC__Service_Order__r.SVMXC__Service_Group__c +' '+ t.SVMXC__Service_Group__c);
                        if(po.SVMXC__Destination_Location__r.SVMXC__Stocking_Location__c == True && po.SVMXC__Destination_Location__c == t.SVMXC__Inventory_Location__c){
                            validated = true;
                        }
                        else if(po.SVMXC__Destination_Location__r.SVMXC__Stocking_Location__c == FALSE && po.SVMXC__Service_Order__r.SVMXC__Service_Group__c == t.SVMXC__Service_Group__c){
                            validated = true;
                        }
                    }
                    if(validated == false  && !u.Ignore_Validations__c){
                        poMap.get(po.Id).addError(' Manage inventory permission at this location not met.'); // prevent update
                    }
                }
            }else if(trigger.isInsert){
                if(po.SVMXC__Order_Type__c == 'Stocking'){
                    if(techs.isEmpty() && !u.Ignore_Validations__c){
                        poMap.get(po.Id).addError(' Manage inventory permission not set on this user.'); // prevent update
                        break;
                    }else{
                        for(SVMXC__Service_Group_Members__c t :techs){
                            if(po.SVMXC__Destination_Location__c == t.SVMXC__Inventory_Location__c){
                                validated = true;
                            }
                        }
                    } 
                }
            }
            if(validated == false && !u.Ignore_Validations__c){
                //poMap.get(po.Id).addError(' Manage inventory permission at this location not met.'); // prevent update
            }
        }        
    }
}