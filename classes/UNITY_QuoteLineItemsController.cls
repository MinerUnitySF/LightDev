/*
 * @programer: Rodrigo Birriel
 * @date:      01/27/2015
 */
public class UNITY_QuoteLineItemsController {
    public Id quoteId {get; 
                           set {
                               quoteId = value;
                               items = [SELECT Id, UNITY_Quantity_Price__c, UNITY_Description__c, UNITY_Quantity__c, UNITY_Unit_Price__c  
                                        FROM UNITY_Proposal_Line_Item__c
                                        WHERE UNITY_Proposal__c=:quoteId 
                                        ORDER BY UNITY_Proposal__c ASC NULLS FIRST];
                           }}
    
    public String totalPrice {get; set;}
    
    public List<UNITY_Proposal_Line_Item__c> items {get; set;}
    
}