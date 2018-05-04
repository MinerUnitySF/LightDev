global class UNITY_QuoteToOrderConverter{

    webservice static String convertQuote(Id quoteId){
        UNITY_Proposal__c quote = [SELECT Id, UNITY_Account__c,UNITY_Work_Order__c, UNITY_Work_Order__r.Pricebook2Id, UNITY_Status__c FROM UNITY_Proposal__c WHERE id =: quoteid];
        if(quote.UNITY_Status__c != 'Accepted'){
            return 'The quote has not been approved by the customer yet. Please wait for approval.';
        }
        
        List<UNITY_Proposal_Line_Item__c> quoteLineItems = [SELECT Id, UNITY_Tax_Code__c, UNITY_Price__c, UNITY_Product__c, UNITY_Total_Price__c,UNITY_Total_Cost__c, UNITY_Quantity__c FROM UNITY_Proposal_Line_Item__c WHERE UNITY_Proposal__c =: quoteid];

        Set<Id> produsctIdSet = new Set<Id>();
        for(UNITY_Proposal_Line_Item__c qli : quoteLineItems ){
            produsctIdSet.add(qli.UNITY_Product__c);
        }

        List<PriceBookEntry> priceBookEntries = [SELECT Id, IsActive, Pricebook2Id, Product2Id FROM PriceBookEntry WHERE IsActive = True AND Pricebook2Id =: quote.UNITY_Work_Order__r.Pricebook2Id AND Product2Id IN: produsctIdSet];
        Map<Id,Id> productToPriceBookEntryMap = new Map<Id,Id>();
        for(PriceBookEntry pbe : priceBookEntries ){
            productToPriceBookEntryMap.put(pbe.Product2Id, pbe.Id); 
        }
        
        Order o = new Order();
        o.AccountId = quote.UNITY_Account__c;
        o.FSO__WorkOrder__c = quote.UNITY_Work_Order__c;
        o.Status = 'Draft';
        o.EffectiveDate = Date.today();
        insert o;
        
        List<OrderItem> orderItems = new List<OrderItem>();
        for(UNITY_Proposal_Line_Item__c qli : quoteLineItems){
            OrderItem oi = new OrderItem();
            oi.UNITY_Total_Cost__c = qli.UNITY_Total_Cost__c;
            oi.UNITY_Total_Price__c = qli.UNITY_Total_Price__c;
            oi.Quantity = qli.UNITY_Quantity__c;
            oi.OrderId = o.Id;
            oi.UnitPrice = qli.UNITY_Price__c;
            oi.PricebookEntryId = productToPriceBookEntryMap.get(qli.UNITY_Product__c);
            oi.UNITY_Tax_Code__c = qli.UNITY_Tax_Code__c;
            orderItems.add(oi);
        }
        insert orderItems;
        return 'Purchase order have been created';
    }

}