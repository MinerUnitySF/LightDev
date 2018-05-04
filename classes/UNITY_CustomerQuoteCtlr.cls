/**UNITY_CustomerQuoteCtlr
 * @description: This is the controller class for the customer quote .pdf vfPage
 * @programer:   Izay Ramos-Irizarry
 * @date:		 3/30/2016
 * @version:	 1.0
 */
public class UNITY_CustomerQuoteCtlr {
    public final static Integer LINES_PER_PAGE = 20;
    public final static Integer INC_CHARGE_LINES = 9;
    public UNITY_Proposal__c quote {get; private set;}
    public String quoteId {
        get; 
        set{
        	quoteId = value;
        	generateQuote(quoteId);
    	}
    }
    public List<PageWrapper> pages {get; set;}
    public String caseId {get; private set;}
    public String quoteComments {get; private set;}
    public UNITY_CustomerQuoteCtlr.QuoteTotals totals {get; private set;}
    public List<UNITY_CustomerQuoteCtlr.IncCharge> allInc {get; private set;}
    public Decimal totalInc {get; private set;}
    public Decimal totalIncAdj {get;private set;}
    public Decimal totalIncTax {get; private set;}
    public Decimal totalIncSC {get; private set;}
    public Decimal totalIncSCTax {get; private set;}
    public Account customer {get; private set;}
    public Account location {get; private set;}
    public Account buAccount {get; private set;}
    public Boolean isMaster {get; private set;}
    
    public UNITY_CustomerQuoteCtlr(){}
    
    public UNITY_CustomerQuoteCtlr(ApexPages.StandardController c){
        String qid = c.getRecord().Id;
        generateQuote(qid);
    }
    
    public void generateQuote(String qid){
        if(String.isNotBlank(qid)){
            this.pages = new List<PageWrapper>();
            String mqRTId = UNITY_Constants.PROPOSAL_MASTER_PROPOSAL_RECORDTYPE;
            quote = [SELECT Id,Name,UNITY_Account__c,UNITY_Agent__r.Name,UNITY_Business_Unit_Account__c,UNITY_Case__c,UNITY_Case__r.CaseNumber,UNITY_Case__r.UNITY_Customer_Service_Contract__c,UNITY_Comments__c,UNITY_Customer__c,UNITY_Customer__r.UNITY_Bill_To_Account__c,
                     UNITY_Customer_Email__c,UNITY_Customer_PIN__c,UNITY_Status__c,UNITY_Discount_Amount__c,UNITY_Discount__c,UNITY_Effective_Till_Date__c,UNITY_Work_Order__r.WorkOrderNumber,
                     UNITY_Final_Price__c,UNITY_Has_Pending_Approval_Sub_Quotes__c,UNITY_Master_Quote__c,UNITY_Master_Quote__r.Name,UNITY_Quote_Comments__c,UNITY_Proposal_Status__c,UNITY_Customer_PO__c,UNITY_Estimated_Sales_Tax__c,
                     UNITY_Service_Charge__c,UNITY_Discounted_Service_Charge__c,UNITY_Total_Price__c,UNITY_Email_Logo_URL__c,RecordTypeId,CreatedDate,(SELECT Id,Name,UNITY_Customer_Adjusted_Quantity__c,UNITY_Discount__c,
                     UNITY_Discount_Amount__c,UNITY_Discounted_Price__c,UNITY_Price__c,UNITY_Product__c,UNITY_Product__r.Name,UNITY_Quantity__c,UNITY_Total_Price__c,UNITY_Unknown_Part_Description_2__c,
                     UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Unit_Price__c,UNITY_Line_Item_Unit_Price__c FROM Proposal_Line_Items__r) FROM UNITY_Proposal__c WHERE Id = :qid LIMIT 1];
            this.quoteComments = '';
            this.totals = new UNITY_CustomerQuoteCtlr.QuoteTotals();
            this.caseId = quote.UNITY_Case__c;
            String custId = (String.isNotBlank(quote.UNITY_Customer__r.UNITY_Bill_To_Account__c)?quote.UNITY_Customer__r.UNITY_Bill_To_Account__c:quote.UNITY_Customer__c);
            this.customer = [SELECT Id,Name,BillingStreet,BillingCity,BillingState,BillingPostalCode,UNITY_Account_ID__c,UNITY_Bill_To_Account__c,UNITY_Bill_To_Account__r.Name FROM Account WHERE Id = :custId LIMIT 1];
            this.location = [SELECT Id,Name,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,UNITY_Account_ID__c,UNITY_Bill_To_Account__c,UNITY_Bill_To_Account__r.Name FROM Account WHERE Id = :quote.UNITY_Account__c LIMIT 1];
            this.buAccount = [SELECT Id,Name,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,Phone,Fax,Account_Email__c FROM Account WHERE Id = :quote.UNITY_Business_Unit_Account__c LIMIT 1];
            List<UNITY_Proposal__c> approvedQuotes = new List<UNITY_Proposal__c>();
            List<UNITY_Proposal__c> newQuotes = new List<UNITY_Proposal__c>();
            this.allInc = new List<UNITY_CustomerQuoteCtlr.IncCharge>();
            this.totalInc = 0;
            this.totalIncAdj = 0;
            this.totalIncTax = 0;
            this.totalIncSC = 0;
            this.totalIncSCTax = 0;
            String masterQId = '';
            if(quote.RecordTypeId == mqRTId){
                isMaster = true;
                masterQId = quote.Id;
                if(String.isNotBlank(quote.UNITY_Quote_Comments__c))
                	this.quoteComments += quote.UNITY_Quote_Comments__c.replaceAll('\r\n','<br/>') + '<br/>';
            }else{
                isMaster = false;
                if(String.isNotBlank(quote.UNITY_Master_Quote__c)){
                    masterQId = quote.UNITY_Master_Quote__c;
                }
            }
            if(String.isNotBlank(masterQId)){
                List<UNITY_Proposal__c> myQuotes = [SELECT Id,Name,UNITY_Account__c,UNITY_Agent__r.Name,UNITY_Business_Unit_Account__c,UNITY_Case__c,UNITY_Case__r.CaseNumber,UNITY_Case__r.UNITY_Customer_Service_Contract__c,UNITY_Comments__c,UNITY_Customer__c,
                     								UNITY_Customer_Email__c,UNITY_Customer_PIN__c,UNITY_Status__c,UNITY_Discount_Amount__c,UNITY_Discount__c,UNITY_Effective_Till_Date__c,UNITY_Work_Order__r.WorkOrderNumber,
                     								UNITY_Final_Price__c,UNITY_Has_Pending_Approval_Sub_Quotes__c,UNITY_Master_Quote__c,UNITY_Quote_Comments__c,UNITY_Proposal_Status__c,UNITY_Customer_PO__c,UNITY_Estimated_Sales_Tax__c,
                     								UNITY_Service_Charge__c,UNITY_Discounted_Service_Charge__c,UNITY_Total_Price__c,UNITY_Email_Logo_URL__c,RecordTypeId,CreatedDate,
                                                    (
                                                        SELECT Id,Name,UNITY_Customer_Adjusted_Quantity__c,UNITY_Discount__c,UNITY_Total_Price__c,UNITY_Unknown_Part_Description_2__c,
                                                        UNITY_Discount_Amount__c,UNITY_Discounted_Price__c,UNITY_Price__c,UNITY_Product__c,UNITY_Product__r.Name,UNITY_Quantity__c,
                                                        UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Unit_Price__c,UNITY_Line_Item_Unit_Price__c 
                                                        FROM Proposal_Line_Items__r WHERE UNITY_Not_Billable__c = FALSE
                                                    ) 
                                                    FROM UNITY_Proposal__c WHERE UNITY_Master_Quote__c = :masterQId ORDER BY CreatedDate DESC];
                if(myQuotes.size() > 0){
                    Decimal sCharge = 0;
                    Decimal discAmt = 0;
                    Decimal estTax = 0;
                    Decimal subTotal = 0;
                    Decimal total = 0;
                    //Need to separate old quotes from new quote and remove canceled quotes
                    for(UNITY_Proposal__c q :myQuotes){
                        if(q.UNITY_Proposal_Status__c == 'Customer Approved' || q.UNITY_Proposal_Status__c == 'Completed' ){
                            approvedQuotes.add(q);
                        }else if(q.UNITY_Proposal_Status__c != 'Cancelled' && q.UNITY_Proposal_Status__c != 'Customer Rejected'){
                            newQuotes.add(q);
                            //sCharge += (q.UNITY_Service_Charge__c != null) ? q.UNITY_Service_Charge__c : 0;
                            estTax += (q.UNITY_Estimated_Sales_Tax__c != null) ? q.UNITY_Estimated_Sales_Tax__c : 0;
                            subTotal += (q.UNITY_Total_Price__c != null) ? q.UNITY_Total_Price__c : 0;
                            total += (q.UNITY_Final_Price__c != null) ? q.UNITY_Final_Price__c : 0;
                            if(String.isNotBlank(q.UNITY_Quote_Comments__c) && q.Proposal_Line_Items__r.size() > 0){
                                this.quoteComments += q.UNITY_Quote_Comments__c.replaceAll('\r\n','<br/>') + '<br/>';
                            }
                            discAmt +=  (total - subTotal);
                        }
                    }
                    sCharge += ((quote.UNITY_Service_Charge__c != null)? quote.UNITY_Service_Charge__c : 0);
                    discAmt += ((quote.UNITY_Discounted_Service_Charge__c != null  && sCharge != null) ? 
                                (quote.UNITY_Discounted_Service_Charge__c - sCharge) : 0);
                    this.totals.servCharge = sCharge;
                    if(sCharge>0){
                        UNITY_CallAvatax.AvataxResult result = UNITY_CallAvatax.getServiceChargeTax(this.location.Id,this.buAccount.Id,this.customer.Id,quote.UNITY_Discounted_Service_Charge__c);
                        this.totals.servChargeTax = result.totalTax;
                    }
                    this.totals.totalDiscount = discAmt - estTax;
                    this.totals.estSalesTax = estTax + this.totals.servChargeTax;
                    this.totals.subTotal = subTotal;
                    this.totals.total = total + 
                        ((quote.UNITY_Discounted_Service_Charge__c!=null)?quote.UNITY_Discounted_Service_Charge__c:0) + 
                        this.totals.servChargeTax;
                }
                Map<string,UNITY_General_Settings__c> generalSettings = UNITY_General_Settings__c.getAll();
                Set<String> delimitedInvoiceableStatuses = new Set<String>();
                UNITY_General_Settings__c generalSetting = generalSettings.get(UNITY_Constants.PO_INVOICEABLE_STATUSES);
                String POInvoiceableStatuses;
                if (generalSetting!=null){
                    POInvoiceableStatuses = generalSetting.UNITY_Value__c;
                }
                if (POInvoiceableStatuses!=null){
                    delimitedInvoiceableStatuses = new Set<String>(POInvoiceableStatuses.split(UNITY_Constants.PO_INVOICEABLE_STATUSES_DELIMITER));
                }
                List<Order> allPOs = [SELECT Id,OrderNumber,AccountId,EffectiveDate,UNITY_Discount__c,UNITY_Discount_Amount__c,UNITY_Final_Price__c,UNITY_Line_Item_DIscounted_Price__c,
                                      (SELECT Id,OrderId,OrderItemNumber,UNITY_Customer_Adjusted_Quantity__c,UNITY_Is_Vendor_Supply__c,UNITY_Sales_Tax__c,
                                       UNITY_Price__c,UNITY_Type__c,UNITY_Activity_Type__c,UNITY_Discounted_Price__c,UNITY_Total_Price__c,UNITY_Product_Name__c
                                       FROM OrderItems WHERE PriceBookEntry.Product2.Name != 'Vendor Service Fee' 
                                       AND UNITY_Type__c != 'Non Billable' AND UNITY_Not_Billable__c = FALSE
                                      ) 
                                      FROM Order WHERE FSO__WorkOrder__r.CaseId = :this.caseId
                                      AND(RecordTypeId =: UNITY_Constants.ORDER_PURCHASE_ORDER_RECORDTYPE 
                                          OR 
                                          RecordTypeId =: UNITY_Constants.PART_SOURCING_PURCHASE_ORDER_RECORDTYPE)
                                      AND Status IN :delimitedInvoiceableStatuses];
                //Need to find all incurred chargers from existing (final) POs
                //Map to hold lines by type/activity type and those totals
                Map<String,Map<String,Decimal>> typesMap = new Map<String,Map<String,Decimal>>();
                Decimal tempVendorInc = 0;
                Decimal tempVendorIncDisc = 0;
                for(Order po :allPOs){
                    this.totalInc += (po.UNITY_Final_Price__c != null) ? po.UNITY_Final_Price__c : po.UNITY_Line_Item_DIscounted_Price__c;
                    this.totalIncAdj += (po.UNITY_Final_Price__c - po.UNITY_Line_Item_DIscounted_Price__c);
                    //For each order item... put the incurred charges per line type in the appropriate inc map
                    for(OrderItem ot :po.OrderItems){
                        Decimal temp = (ot.UNITY_Discounted_Price__c != null) ? ot.UNITY_Discounted_Price__c : ot.UNITY_Total_Price__c;
                        Decimal tempTax = (ot.UNITY_Sales_Tax__c != null) ? ot.UNITY_Sales_Tax__c : 0;
                        this.totalIncTax += tempTax;
                        if(ot.UNITY_Is_Vendor_Supply__c){
                            tempVendorInc += temp;
                            System.debug('#####Izay: tempVendorInc=' +tempVendorInc);
                            System.debug('#####Izay: po.UNITY_Discount__c=' +po.UNITY_Discount__c);
                            if(po.UNITY_Discount__c != null && po.UNITY_Discount__c > 0){
                                tempVendorIncDisc += (temp - (temp*(po.UNITY_Discount__c/100))).setScale(2,System.RoundingMode.HALF_DOWN);
                            }
                            System.debug('#####Izay: tempVendorIncDisc=' +tempVendorIncDisc);
                        }
                        Map<String,Decimal> tempMap;
                        if(typesMap.containsKey(ot.UNITY_Type__c)){
                            if(typesMap.get(ot.UNITY_Type__c).containsKey(ot.UNITY_Activity_Type__c)){
                                temp += typesMap.get(ot.UNITY_Type__c).get(ot.UNITY_Activity_Type__c);
                                typesMap.get(ot.UNITY_Type__c).put(ot.UNITY_Activity_Type__c,temp);
                            }else{
								typesMap.get(ot.UNITY_Type__c).put(ot.UNITY_Activity_Type__c,temp);
                            }
                        }else{
                            tempMap = new Map<String,Decimal>();
                            tempMap.put(ot.UNITY_Activity_Type__c,temp);
                            typesMap.put(ot.UNITY_Type__c,tempMap);
                        }
                    }//End per order item
                }//End getting all incurred values
                //Calculate incurred service charge
                this.totalIncSC = UNITY_UsageRequestHandler.calculateServicveCharge(quote.UNITY_Case__r.UNITY_Customer_Service_Contract__c,0,tempVendorInc);
                if(this.totalIncSC != null && this.totalIncSC > 0){
                    Decimal totalDiscSCharge = 0;
                    Decimal scDiscPer = 0;
                    if(tempVendorIncDisc > 0 && tempVendorInc > 0)
                        scDiscPer = (tempVendorIncDisc/tempVendorInc).setScale(2,System.RoundingMode.HALF_DOWN);
                    totalDiscSCharge = (this.totalIncSC * scDiscPer).setScale(2,System.RoundingMode.HALF_DOWN);
                    System.debug('#####Izay: totalIncSC=' +totalIncSC+', scDiscPer-'+scDiscPer+', totalDiscSCharge'+ totalDiscSCharge);
                    UNITY_CallAvatax.AvataxResult result = UNITY_CallAvatax.getServiceChargeTax(this.location.Id,this.buAccount.Id,this.customer.Id,totalDiscSCharge);
                    this.totalIncSCTax = result.totalTax;
                    System.debug('#####Izay: totalIncSCTax=' +totalIncSCTax);
                }
                    
                //this.totalIncTax += this.totalIncSCTax;
                //Now need to create the IncCharge records
                for(String key :typesMap.keySet()){
                    for(String key2 :typesMap.get(key).keySet()){
                    	UNITY_CustomerQuoteCtlr.IncCharge charge = new UNITY_CustomerQuoteCtlr.IncCharge();
                        charge.type = key;
                        charge.description = key2;
                        charge.total = typesMap.get(key).get(key2);
                        allInc.add(charge);
                    }
                }
                
                this.totals.finalTotal = this.totals.total + this.totalInc + this.totalIncTax;
                
                List<UNITY_Proposal_Line_Item__c> allLines = new List<UNITY_Proposal_Line_Item__c>();
                if(!newQuotes.isEmpty()){
                    for(UNITY_Proposal__c q :newQuotes){
                        if(!q.Proposal_Line_Items__r.isEmpty()){
                            allLines.addAll(q.Proposal_Line_Items__r);
                        }
                    }
                }else{
                    if(!quote.Proposal_Line_Items__r.isEmpty())
                    	allLines.addAll(quote.Proposal_Line_Items__r);
                    else
                        allLines.add(new UNITY_Proposal_Line_Item__c());
                }
                
                List<UNITY_Proposal_Line_Item__c> temp = new List<UNITY_Proposal_Line_Item__c>();
                Integer count = 0;
                Integer plCount = 0;
                Integer pNo = 0;
                for(UNITY_Proposal_Line_Item__c qLine :allLines){
                    count++;
                    plCount++;
                    PageWrapper pw;
                    if(count < allLines.size() && plCount < LINES_PER_PAGE){
                        temp.add(qLine);
                    }else if(count < allLines.size()){
                        temp.add(qLine);
                        pNo++;
                        plCount = 0;
                        if(pages.isEmpty())
                        	pw = new PageWrapper(temp,pNo,true,false);
                        else
                            pw = new PageWrapper(temp,pNo,false,false);
                        pages.add(pw);
                        temp.clear();
                    }else{
                        temp.add(qLine);
                        pNo++;
                        if(pages.isEmpty())
                            pw = new PageWrapper(temp,pNo,true,true);
                        else
                            pw = new PageWrapper(temp,pNo,false,true);
                        pages.add(pw);
                    }
                }
                for(PageWrapper pg :pages){
                    if(pg.last && pg.first){
                        Integer lsize = pg.lines.size() + this.allInc.size() + INC_CHARGE_LINES;
                        if(lsize < LINES_PER_PAGE){
                            for(Integer i = lsize; i < LINES_PER_PAGE; i++){
                                pg.lines.add(new UNITY_Proposal_Line_Item__c());
                            }
                        }
                    }else if(pg.last){
                        Integer lsize = pg.lines.size();
                        if(lsize < LINES_PER_PAGE){
                            for(Integer i = lsize; i < LINES_PER_PAGE; i++){
                                pg.lines.add(new UNITY_Proposal_Line_Item__c());
                            }
                        }
                    }
                }  
            }else{
                //No master quote id found
            }//End if masterQId else
        }else{
            //No quote id found
        }
    }

    public class IncCharge{
        public String type {get; set;}
        public String description {get; set;}
        public Decimal total {get; set;}
        public IncCharge(){
            this.type = '';
            this.description = '';
            this.total = 0;
        }
    }
    
    public class PageWrapper{
        public List<UNITY_Proposal_Line_Item__c> lines{get; set;}
        public Integer pageNo{get; set;}
        public Boolean first{get; set;}
        public Boolean last{get;set;}
        public PageWrapper(List<UNITY_Proposal_Line_Item__c> ln, Integer pn, Boolean f, Boolean l){
            this.lines = new List<UNITY_Proposal_Line_Item__c>();
            lines.addAll(ln);
            this.pageNo = pn;
            this.first = f;
            this.last = l;
        }
    }
    
    public class QuoteTotals{
        public Decimal servCharge{get;set;}
        public Decimal servChargeTax{get;set;}
        public Decimal totalDiscount{get;set;}
        public Decimal estSalesTax{get;set;}
        public Decimal subTotal{get; set;}
        public Decimal total{get;set;}
        public Decimal finalTotal{get;set;}
        public QuoteTotals(){
            this.servCharge = 0;
            this.servChargeTax = 0;
            this.totalDiscount = 0;
            this.estSalesTax = 0;
            this.subTotal = 0;
            this.total = 0;
            this.finalTotal = 0;
        }
    }
}