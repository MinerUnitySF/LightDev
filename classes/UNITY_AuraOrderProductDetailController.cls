public class UNITY_AuraOrderProductDetailController {
    @AuraEnabled
    public static OrderItem getOrderItem(Id recordId){
        system.debug('@@@getOrderItem recordId:'+recordId);
        return [SELECT Id, Order.OrderNumber, UNITY_Product_Name__c, Description, UNITY_Cost__c, UNITY_Total_Cost__c, UNITY_Vendor_Adjusted_Quantity__c,
                UNITY_Part_Delivered__c, UNITY_Shipment_Received__c, UNITY_Shipping_Provider__c, UNITY_Expected_Quantity__c, UNITY_Tracking_Number__c, UNITY_Expected_Ship_Date__c,
                UNITY_Tracking_URL__c, UNITY_Actual_Quantity__c, UNITY_Actual_Ship_Date__c,UNITY_Is_Vendor_Supply__c, UNITY_Vendor_Holiday_Multiplier__c, UNITY_Vendor_OT_Multiplier__c
                FROM OrderItem 
                  WHERE Id = :recordId 
                     AND UNITY_Is_Vendor_Supply__c = true];
    }
}