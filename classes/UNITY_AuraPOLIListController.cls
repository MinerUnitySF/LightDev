public class UNITY_AuraPOLIListController {
    @AuraEnabled
    public static List<OrderItem> getOrderItemList(Id orderId){
        system.debug('@@@getOrderItemList orderId:'+orderId);
        return [SELECT Id, UNITY_Product_Name__c, Description, UNITY_Cost__c, UNITY_Total_Cost__c, UNITY_Vendor_Adjusted_Quantity__c FROM OrderItem
                WHERE OrderId = :orderId AND UNITY_Is_Vendor_Supply__c = true AND UNITYPM_Non_Payable__c = false];
    }
}