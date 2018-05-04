public class UNITY_DisputeInvoiceButtonController{

    UNITY_Invoice__c invoice {get;set;}
    UNITY_Invoice__c newInvoice {get;set;}
    Case invoiceCase;
    UNITY_Service_Contract__c sContract;
    
    public UNITY_DisputeInvoiceButtonController(ApexPages.StandardController stdController) {
        this.invoice =  this.invoice = [SELECT Id, UNITY_Original_Invoice__c, UNITY_Customer__c,UNITY_Agent__c, UNITY_Case__c, UNITY_Invoice_Status__c,
                                        (SELECT UNITY_Total_Price__c, UNITY_Cost__c, UNITY_Sales_Tax__c, UNITY_PO_Price__c, UNITY_Quantity__c,
                        			   			UNITY_Adjusted_Quantity__c, Product__c, UNITY_Tax_Code__c, UNITY_Is_Vendor_Supply__c, 
                        			   			UNITY_Activity_Type__c, UNITY_Type__c FROM Invoice_Line_Items__r)
                                        FROM UNITY_Invoice__c
                        				WHERE Id =: stdController.getRecord().Id];
        this.newInvoice = new UNITY_Invoice__c();
    }
    
    public PageReference disputeInvoice(){
        if(invoice.UNITY_Invoice_Status__c == 'Disputed'){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Invoice already in "Disputed" status');
            ApexPages.addMessage(myMsg);
            return null;
        }
        Savepoint sp;
        
        try{
        sp = Database.setSavepoint();
        invoiceCase = [SELECT Id, UNITY_Customer_Service_Contract__c, UNITY_Customer__c, UNITY_Customer__r.Account_Email__c,
                       (SELECT Id,UNITY_Original_Invoice__c FROM Invoices__r)
                       FROM Case WHERE Id =: invoice.UNITY_Case__c];
        sContract = [SELECT Id, UNITY_Margin__c FROM UNITY_Service_Contract__c WHERE Id =: invoiceCase.UNITY_Customer_Service_Contract__c];
    
        newInvoice.UNITY_Case__c = invoiceCase.Id;
        newInvoice.UNITY_Customer__c = invoice.UNITY_Customer__c;
        newInvoice.UNITY_Customer_Email__c = invoiceCase.UNITY_Customer__r.Account_Email__c;
        newInvoice.UNITY_Customer_Service_Contract__c = invoiceCase.UNITY_Customer_Service_Contract__c;
        newInvoice.UNITY_Service_Contract_Margin_Value__c = sContract.UNITY_Margin__c;
        newInvoice.UNITY_Original_Invoice__c = invoice.id;
        newInvoice.UNITY_Agent__c = invoice.UNITY_Agent__c;
        //newInvoice.Name = invoice.Name + '-CR'; field is not writeable
        insert newInvoice;
        

        invoice.UNITY_Invoice_Status__c = 'Disputed';
        update invoice;
        
        // build the hierarchy map
        Map<Id,Id> invoicesMap = new Map<Id,Id>();
        for(UNITY_Invoice__c invoice : invoiceCase.Invoices__r) {
            invoicesMap.put(invoice.Id, invoice.UNITY_Original_Invoice__c);
        }
		Id topOriginalInvoiceId = invoice.Id;
        while(invoicesMap.get(topOriginalInvoiceId) != null){
       		topOriginalInvoiceId = invoicesMap.get(topOriginalInvoiceId);   
        }
        List<Order> orders = [SELECT Id, UNITY_Invoice__c, UNITY_Updated_Invoice__c, (SELECT Id, UNITY_Is_Vendor_Supply__c, UNITY_Activity_Type__c, UNITY_Type__c,UNITY_Sales_Tax__c, OrderId, UNITY_Tax_Code__c, UNITY_Price__c, UNITY_Total_Cost__c, UNITY_Total_Price__c,PricebookEntry.Product2Id, PricebookEntry.Product2.UNITY_Product_Type__c, Quantity, UNITY_Customer_Adjusted_Quantity__c FROM OrderItems) FROM Order WHERE UNITY_Invoice__c =: topOriginalInvoiceId];
        if(orders.size() == 0 && invoice.UNITY_Original_Invoice__c == null){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Invoice is not assigned to the order');
            ApexPages.addMessage(myMsg);
            return null;
        }
            
        //if(orders.size() > 1){
        //    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Invoice is assigned to more than one order');
        //    ApexPages.addMessage(myMsg);
        //    return null;
        //}
        
        List<UNITY_Invoice_Line_Item__c> invoiceLineItems = new List<UNITY_Invoice_Line_Item__c>();              

        for (Order currentOrder : orders){
            
            currentOrder.UNITY_Updated_Invoice__c = newInvoice.Id;
            currentOrder.Status = 'Invoice Regenerated';
            
        }
        for(UNITY_Invoice_Line_Item__c originalLineItem : this.invoice.Invoice_Line_Items__r) {
            UNITY_Invoice_Line_Item__c ili = new UNITY_Invoice_Line_Item__c();
            ili.UNITY_Invoice__c = newInvoice.Id;
            ili.UNITY_Total_Price__c = originalLineItem.UNITY_Total_Price__c;
            ili.UNITY_Cost__c = originalLineItem.UNITY_Cost__c;
            ili.UNITY_Sales_Tax__c = originalLineItem.UNITY_Sales_Tax__c;
            ili.UNITY_PO_Price__c = originalLineItem.UNITY_PO_Price__c; 
            ili.UNITY_Quantity__c = originalLineItem.UNITY_Quantity__c;
            ili.UNITY_Adjusted_Quantity__c = originalLineItem.UNITY_Adjusted_Quantity__c;
            ili.Product__c = originalLineItem.Product__c;
            ili.UNITY_Tax_Code__c = originalLineItem.UNITY_Tax_Code__c;
            ili.UNITY_Is_Vendor_Supply__c = originalLineItem.UNITY_Is_Vendor_Supply__c;
            ili.UNITY_Activity_Type__c = originalLineItem.UNITY_Activity_Type__c;
            ili.UNITY_Type__c = originalLineItem.UNITY_Type__c;
            invoiceLineItems.add(ili);
        }
            
            
        insert invoiceLineItems;
        update orders;
        
        PageReference pageRef = new PageReference('/' + newInvoice.Id);
        return pageRef;
        
        } catch (Exception ex){
            Database.rollback(sp);
            throw ex;
        } 
    }
}