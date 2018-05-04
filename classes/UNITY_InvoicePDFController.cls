/**
 * Izay: Added the UNITY_Invoice_Description to the invoice query to display on invoice PDF
 * 
 * */
public class UNITY_InvoicePDFController{

    public UNITY_Invoice__c invoice {get;set;}
    
    public List<InvoicePageWrapper> pageWrappers {get;set;}
    public String[] emailAddress {get;set;}
    public String[] shippingAddress {get;set;}
    public String[] billingAddress {get;set;}
    public Date dateValue {get;set;}
    
    public String net {get;set;}
    public String discount {get;set;}
    public String tax {get;set;}
    public String total {get;set;}
    
    public Decimal discountDecimal {get;set;}
    public Decimal taxDecimal {get;set;}
    public Decimal totalDecimal {get;set;}
    public Decimal finalDecimal {get;set;}
    
    public Integer totalPages {get;set;}
    
    public final static Integer MAX_LINEITEM_LINES_PER_PAGE = 15; //23

    public Id invoiceId {get;
    set{
        if(value == null) return;
        invoiceId = value;
        pageWrappers = new List<InvoicePageWrapper>();
        
        invoice = [SELECT Id, 
                    Name, 
                    CreatedDate, 

                    UNITY_Bill_To_Address__c, 
                    UNITY_Job_Site__c, 
                    UNITY_Final_Price__c, 
                    UNITY_Total_Price__c, 
                    UNITY_Total_Tax__c, 
                    UNITY_Total_Cost__c, 
                    UNITY_Discount_Amount__c, 
                    UNITY_Email_Logo_URL__c, 
                    UNITY_Email_Billing_Address__c,
                    UNITY_Invoice_Description__c,
                    UNITY_Invoice_Status__c,
                    UNITY_Invoice_Date__c,
                    UNITY_Total_Adjustments__c, 

                    UNITY_Case__r.UNITY_Customer_PO__c, 
                    UNITY_Case__r.UNITY_Email_Invoice_Guarantee_Text__c, 
                
                    UNITY_Customer__r.UNITY_TimeZoneSidKey__c, 
                    UNITY_Customer__r.UNITY_Account_ID__c, 
                    UNITY_Customer__r.BillingStreet, 
                    UNITY_Customer__r.BillingPostalCode, 
                    UNITY_Customer__r.BillingCity,
                    UNITY_Customer__r.BillingState, 
                    UNITY_Customer__r.ShippingStreet, 
                    UNITY_Customer__r.ShippingPostalCode, 
                    UNITY_Customer__r.ShippingCity, 
                    UNITY_Customer__r.ShippingState, 

                    UNITY_Customer_Service_Contract__r.UNITY_Net_Payment_Terms__c, 

                    UNITY_Business_Unit_Account__c,
                    UNITY_Business_Unit_Account__r.MSPFS_BU_Billing_Address__c

                   FROM UNITY_Invoice__c WHERE Id =: invoiceId];
        List<UNITY_Invoice_Line_Item__c> invoiceLineItems = [SELECT Id,Product__r.Description,UNITY_Sales_Tax__c,Product__r.Name,UNITY_Quantity__c,UNITY_Unit_Price__c,UNITY_Total_Price__c,UNITY_Adjusted_Quantity__c,UNITY_Description__c FROM UNITY_Invoice_Line_Item__c WHERE UNITY_Invoice__c =: invoiceId AND UNITY_Line_Status__c != 'Cancelled'];
        
        List<List<UNITY_Invoice_Line_Item__c>> invoiceLineItemList = new List<List<UNITY_Invoice_Line_Item__c>>();
        List<UNITY_Invoice_Line_Item__c> iliPageList = new List<UNITY_Invoice_Line_Item__c>();
        Integer counter = 0;
        for(UNITY_Invoice_Line_Item__c ili : invoiceLineItems){
            if(counter >= 22){
                invoiceLineItemList.add(iliPageList);
                iliPageList = new List<UNITY_Invoice_Line_Item__c>();
                counter = 0;   
            }
            iliPageList.add(ili);
            if(ili.Product__r.Description.length() > 256 || ili.Product__r.Name.length() > 80){
                counter = counter + 2;
            } else if(ili.Product__r.Description.length() > 128 || ili.Product__r.Name.length() > 40){
                counter = counter + 1;
            }
            counter++;
        }
        invoiceLineItemList.add(iliPageList);
        
        totalPages = 1;
        for(List<UNITY_Invoice_Line_Item__c> iliList : invoiceLineItemList){
            List<InvoiceLineItemWrapper> wrapperList = new List<InvoiceLineItemWrapper>();
            for(UNITY_Invoice_Line_Item__c ili : iliList){
                wrapperList.add(new InvoiceLineItemWrapper(ili));
            }
            Integer pageSize = 0;
            for(InvoiceLineItemWrapper wrapper : wrapperList){
                pageSize  = pageSize + wrapper.textLines;
            }
            if(pageSize < MAX_LINEITEM_LINES_PER_PAGE){
                for(Integer i = 0; i < MAX_LINEITEM_LINES_PER_PAGE - pageSize; i++){
                    wrapperList.add(new InvoiceLineItemWrapper(null));
                }
            }
            pageWrappers.add(new InvoicePageWrapper(wrapperList, totalPages));
            totalPages++;
        }
        totalPages--;
        pageWrappers.get(pageWrappers.size() - 1).lastPage = true;
        
        emailAddress = (invoice.UNITY_Email_Billing_Address__c.replace('&amp;','&')).split('<br>');
        
        billingAddress = new String[2];
        shippingAddress = new String[2];
        shippingAddress[0] = invoice.UNITY_Job_Site__c;//invoice.UNITY_Customer__r.ShippingStreet == null ? ' ' : invoice.UNITY_Customer__r.ShippingStreet;
        shippingAddress[1] = '';//invoice.UNITY_Customer__r.ShippingCity == null ? ' ' : invoice.UNITY_Customer__r.ShippingCity + ', ' + invoice.UNITY_Customer__r.ShippingState == null ? ' ' : invoice.UNITY_Customer__r.ShippingState + ' ' + invoice.UNITY_Customer__r.ShippingPostalCode == null ? ' ' : invoice.UNITY_Customer__r.ShippingPostalCode;
        billingAddress[0] = invoice.UNITY_Bill_To_Address__c;
        billingAddress[1] = '';
        /*
            billingAddress[0] = invoice.UNITY_Customer__r.BillingStreet == null ? ' ' : invoice.UNITY_Customer__r.BillingStreet;
            billingAddress[1] = invoice.UNITY_Customer__r.BillingCity == null ? ' ' : invoice.UNITY_Customer__r.BillingCity + ', ' + invoice.UNITY_Customer__r.BillingState == null ? ' ' : invoice.UNITY_Customer__r.BillingState + ' ' + invoice.UNITY_Customer__r.BillingPostalCode == null ? ' ' : invoice.UNITY_Customer__r.BillingPostalCode;
        */
        
        discountDecimal = invoice.UNITY_Discount_Amount__c == null ? 0: invoice.UNITY_Discount_Amount__c;
        taxDecimal = invoice.UNITY_Total_Tax__c == null ? 0: invoice.UNITY_Total_Tax__c;
        totalDecimal = invoice.UNITY_Total_Price__c == null ? 0: invoice.UNITY_Total_Price__c;
        finalDecimal = invoice.UNITY_Final_Price__c == null ? 0: invoice.UNITY_Final_Price__c;
        
        dateValue = invoice.UNITY_Invoice_Date__c;
        total = String.valueOf(finalDecimal- discountDecimal);
        discount = String.valueOf(discountDecimal);
        tax = String.valueOf(taxDecimal);
        net = String.valueOf(finalDecimal - taxDecimal);
        
        }
    }
    //Izay - Added to support UNITY_CustomerInvoice vfPage
    public UNITY_InvoicePDFController(){
        this.invoiceId = ApexHelper.getParam('id');
    }

    //Izay - Added to support UNITY_CustomerInvoice vfPage
    public UNITY_InvoicePDFController(ApexPages.StandardController controller){
        this.invoiceId = ApexHelper.getParam('id');
    }
    
    private String convertDate(DateTime value, String timeZoneId){
        system.debug('>>> '+value+'/'+timeZoneId);
        String strConvertedDate = value.format('MM/dd/yyyy HH:mm:ss', timeZoneId);
        
        String d = strConvertedDate.substring(0,2);
        if(d.length() == 1){
            d = '0' + d;
        }
        String m = strConvertedDate.substring(3,5);
        String y = strConvertedDate.substring(6,10);
        return d + '/' + m + '/' + y;
    }
    
    public class InvoicePageWrapper{
        public List<InvoiceLineItemWrapper> invoiceLineItemWrappers {get;set;}
        public Integer pageNumber {get;set;}
        public Boolean lastPage {get;set;}
        
        InvoicePageWrapper(List<InvoiceLineItemWrapper> wrappers, Integer pageNumber){
            this.invoiceLineItemWrappers = wrappers;
            this.pageNumber = pageNumber;
        }
    }
    
    public class InvoiceLineItemWrapper{
        public String productName{get;set;}
        public String description {get;set;}
        public String quantity {get;set;}
        public String tax {get;set;}
        public String price {get;set;}
        public String total {get;set;}
        
        public Integer textLines {get;set;}
        
        public InvoiceLineItemWrapper(UNITY_Invoice_Line_Item__c ili){
            if(ili != null){
                productName = String.valueOf(ili.Product__r.Name);
                description = String.valueOf(ili.Product__r.Description);
                if(String.isNotBlank(ili.UNITY_Description__c))
                    description += ili.UNITY_Description__c;
                quantity = ili.UNITY_Adjusted_Quantity__c == null ? '0.00': String.valueOf(ili.UNITY_Adjusted_Quantity__c);
                price = ili.UNITY_Unit_Price__c == null ? '0.00': String.valueOf(ili.UNITY_Unit_Price__c);
                total= ili.UNITY_Total_Price__c == null ? '0.00': String.valueOf(ili.UNITY_Total_Price__c);
                tax = ili.UNITY_Sales_Tax__c == null ? '0.00': String.valueOf(ili.UNITY_Sales_Tax__c);
            } else {
                productName = '';
                description = '';
                quantity = '';
                price = '';
                total= '';
                tax = '';
            }
            if(description.length() > 256){
                description = description.substring(0, 256) + ' ...';
            }
            textLines = 1;
            if(description.length() > 256 || productName.length() > 80){
                textLines = 3;
            } else if(description.length() > 128 || productName.length() > 40){
                textLines = 2;
            }
        }
    }
}