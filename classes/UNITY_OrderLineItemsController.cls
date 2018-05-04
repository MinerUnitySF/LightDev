/*
 * @programer: Rodrigo Birriel
 * @date:      02/04/2015
 */
public class UNITY_OrderLineItemsController {
    public Id orderId {get; 
                           set {
                               orderId = value;
                               items = [SELECT UNITY_Product_Code__c,UNITY_Product_Description__c,UNITY_Cost__c,Quantity,
                                        UNITY_Unknown_Part_Description__c,UNITY_Vendor_Adjusted_Quantity__c,UNITY_Total_Cost__c,Order.UNITY_Total_Cost__c 
                                        FROM OrderItem
                                        WHERE OrderId=:value];
                           }}
    public List<OrderItem> items {get; set;}
}